import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_widgets.dart';
import 'money_utils.dart';

/// 저축 이체를 실제 API 연동 없이 "은행 앱을 열어서 사용자가 직접 이체를 완료"하는
/// 방식으로 처리합니다 (멘토 피드백: 딥링크 방식 권장).
///
/// 실제 계좌 잔액 이동은 각 은행 앱 안에서 사용자가 직접 진행하며, 이 앱은
/// 그 진입만 도와줍니다 — 실제 이체 API를 갖고 있지 않다는 점을 발표 시
/// 명확히 설명해야 합니다 (멘토 피드백 3번).
class BankApp {
  const BankApp({required this.name, required this.scheme, this.storeUrl});

  final String name;
  final String scheme; // 커스텀 URL 스킴 (예: 'kakaobank://')
  final String? storeUrl; // 앱이 없을 때 안내할 스토어 링크 (선택)
}

/// 자주 쓰는 은행/핀테크 앱 목록. 스킴은 각 사가 공개적으로 문서화했거나
/// 널리 알려진 값 기준이며, 정책 변경 시 동작하지 않을 수 있습니다.
const tossBankApp = BankApp(name: '토스', scheme: 'supertoss://');

const bankApps = <BankApp>[
  tossBankApp,
  BankApp(name: '카카오뱅크', scheme: 'kakaobank://'),
  BankApp(name: 'KB국민은행', scheme: 'kbbank://'),
  BankApp(name: '신한 SOL뱅크', scheme: 'shinhan-sr-ib://'),
  BankApp(name: '토스뱅크', scheme: 'tossbank://'),
];

enum DeepLinkResult { opened, notInstalled, failed }

/// 지정한 은행 앱을 딥링크로 엽니다.
/// 앱이 설치돼 있지 않거나 스킴이 거부되면 [DeepLinkResult.notInstalled]를 반환합니다.
Future<DeepLinkResult> openBankApp(BankApp bank) async {
  final uri = Uri.parse(bank.scheme);
  try {
    final canLaunch = await canLaunchUrl(uri);
    if (!canLaunch) return DeepLinkResult.notInstalled;
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    return launched ? DeepLinkResult.opened : DeepLinkResult.notInstalled;
  } catch (_) {
    return DeepLinkResult.failed;
  }
}

Future<DeepLinkResult> openTossForSaving() => openBankApp(tossBankApp);

/// 은행 앱을 연 뒤, 사용자가 이체를 마쳤다고 확인하면 true를 반환합니다.
///
/// 은행이 이체 API를 열어주지 않기 때문에 이 앱이 돈을 옮기지는 못합니다.
/// 대신 금액을 클립보드에 복사하고, 은행 앱 진입 → 돌아와서 완료 확인까지 돕습니다.
Future<bool> runSaveWithBankFlow({
  required BuildContext context,
  required int amount,
  required String goalName,
}) async {
  await Clipboard.setData(ClipboardData(text: '$amount'));
  if (!context.mounted) return false;

  final bank = await showModalBottomSheet<BankApp>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: ThemeScope.paletteOf(context).surface,
    barrierColor: const Color(0x99101D14),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (sheetContext) {
      return ThemeScope(
        palette: ThemeScope.paletteOf(context),
        child: _BankPickerSheet(amount: amount, goalName: goalName),
      );
    },
  );
  if (bank == null || !context.mounted) return false;

  final result = await openBankApp(bank);
  if (!context.mounted) return false;

  if (result != DeepLinkResult.opened) {
    return _confirmTransfer(
      context,
      amount: amount,
      bankName: bank.name,
      openedBank: false,
    );
  }

  await waitUntilAppResumed();
  if (!context.mounted) return false;
  return _confirmTransfer(
    context,
    amount: amount,
    bankName: bank.name,
    openedBank: true,
  );
}

/// 은행 앱으로 나갔다가 다시 이 앱으로 돌아올 때까지 기다립니다.
/// 앱이 실제로 백그라운드로 가지 않으면(에뮬레이터 등) 바로 반환합니다.
Future<void> waitUntilAppResumed() async {
  final binding = WidgetsBinding.instance;
  await Future<void>.delayed(const Duration(milliseconds: 400));
  if (binding.lifecycleState == AppLifecycleState.resumed) {
    return;
  }

  final completer = Completer<void>();
  late final WidgetsBindingObserver observer;
  observer = _ResumeObserver((state) {
    if (state == AppLifecycleState.resumed && !completer.isCompleted) {
      binding.removeObserver(observer);
      completer.complete();
    }
  });
  binding.addObserver(observer);
  try {
    await completer.future.timeout(const Duration(minutes: 5));
  } on TimeoutException {
    binding.removeObserver(observer);
  }
}

Future<bool> _confirmTransfer(
  BuildContext context, {
  required int amount,
  required String bankName,
  required bool openedBank,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(openedBank ? '이체를 완료했나요?' : '$bankName 앱을 열 수 없어요'),
        content: Text(
          openedBank
              ? '$bankName에서 ${formatWon(amount)}을 저축 계좌로 보냈다면, 이 앱 목표에도 같은 금액을 더할게요.'
              : '은행 앱이 없거나 이 기기에서 열리지 않습니다. 직접 이체한 뒤 ${formatWon(amount)}을 목표에 기록할까요?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('아직이에요'),
          ),
          FilledButton(
            key: const Key('confirm-transfer-button'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('완료했어요'),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}

class _ResumeObserver with WidgetsBindingObserver {
  _ResumeObserver(this.onState);

  final ValueChanged<AppLifecycleState> onState;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    onState(state);
  }
}

class _BankPickerSheet extends StatelessWidget {
  const _BankPickerSheet({required this.amount, required this.goalName});

  final int amount;
  final String goalName;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.paletteOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSheetHeader(
            icon: Icons.savings_outlined,
            title: '은행 앱에서 저축하기',
            subtitle:
                '$goalName을 위해 ${formatWon(amount)}을 이체할 은행을 고르세요. 금액은 클립보드에 복사해 두었어요.',
            onClose: () => Navigator.pop(context),
          ),
          const SizedBox(height: 16),
          for (final bank in bankApps)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                key: Key('bank-${bank.name}'),
                onTap: () => Navigator.pop(context, bank),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: palette.accentBorder),
                ),
                tileColor: palette.accentSoft,
                leading: CircleAvatar(
                  backgroundColor: palette.surface,
                  child: Text(
                    bank.name.substring(0, 1),
                    style: TextStyle(
                      color: palette.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                title: Text(
                  bank.name,
                  style: TextStyle(
                    color: palette.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                trailing: Icon(
                  Icons.north_east_rounded,
                  color: palette.textSoft,
                  size: 18,
                ),
              ),
            ),
          const SizedBox(height: 4),
          Text(
            '이 앱이 은행 계좌에서 돈을 옮기지는 않습니다. 이체는 은행 앱에서 직접 완료해 주세요.',
            style: TextStyle(
              color: palette.textMuted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
