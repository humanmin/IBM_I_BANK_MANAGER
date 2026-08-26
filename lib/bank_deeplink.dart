import 'package:url_launcher/url_launcher.dart';

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
const bankApps = <BankApp>[
  BankApp(name: '토스', scheme: 'supertoss://'),
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
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    return launched ? DeepLinkResult.opened : DeepLinkResult.notInstalled;
  } catch (_) {
    return DeepLinkResult.failed;
  }
}
