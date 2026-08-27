import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class BankApp {
  const BankApp({required this.name, required this.scheme});

  final String name;
  final String scheme;
}

const tossBankApp = BankApp(name: '토스', scheme: 'supertoss://');

enum DeepLinkResult { opened, notInstalled, failed }

const _nativeChannel = MethodChannel(
  'com.ibm.money.ibm_money_app/account_data',
);

/// 지정한 은행 앱을 딥링크로 엽니다.
/// 앱이 설치돼 있지 않거나 스킴이 거부되면 [DeepLinkResult.notInstalled]를 반환합니다.
Future<DeepLinkResult> openBankApp(BankApp bank) async {
  if (bank.scheme == tossBankApp.scheme &&
      defaultTargetPlatform == TargetPlatform.android) {
    try {
      final launched = await _nativeChannel.invokeMethod<bool>('openTossApp');
      if (launched == true) return DeepLinkResult.opened;
      if (launched == false) return DeepLinkResult.notInstalled;
    } on MissingPluginException {
      // 위젯 테스트와 Android 이외의 실행 환경에서는 URL 스킴으로 대체합니다.
    } on PlatformException {
      // 네이티브 실행이 실패하면 기존 URL 스킴 방식으로 한 번 더 시도합니다.
    }
  }
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
