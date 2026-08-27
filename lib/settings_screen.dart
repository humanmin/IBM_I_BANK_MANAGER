import 'package:flutter/material.dart';

import 'app_widgets.dart';
import 'models.dart';

/// 설정 탭. 현재 로그인 계정과 로그아웃 동작을 모아둔 화면.
///
/// 이전에는 홈 화면 아바타를 눌러 Navigator.push로 로그인 화면을 띄우는
/// 방식이었는데, 이 앱의 다른 모든 화면은 하단 탭 전환(_activeTab 상태 변경)
/// 방식으로 동작하는 반면 그 방식만 예외적으로 별도 라우트를 쌓는 구조라
/// ThemeScope 등 여러 문제가 반복됐습니다. 설정을 하단 탭 중 하나로 만들면
/// 다른 화면들과 완전히 같은 방식으로 동작해서 그 문제들이 원천적으로 없습니다.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.currentUser,
    required this.onOpenAccount,
    super.key,
  });

  final AppUser? currentUser;
  final VoidCallback onOpenAccount;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.paletteOf(context);
    final user = currentUser;

    return SingleChildScrollView(
      key: const PageStorageKey('settings-scroll'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '설정',
            style: TextStyle(
              color: palette.text,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 20),

          // ── 계정 섹션 ──────────────────────────────────────────
          Text(
            '계정',
            style: TextStyle(
              color: palette.textSoft,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          SoftCard(
            color: palette.surface,
            radius: 16,
            onTap: onOpenAccount,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: palette.accentSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    user == null ? Icons.login_rounded : Icons.person_rounded,
                    color: palette.text,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? user?.email ?? '로그인 / 회원가입',
                        style: TextStyle(
                          color: palette.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user == null
                            ? '계좌 연동, 이벤트 참여를 위해 로그인해 주세요.'
                            : '탭해서 계정 정보 보기 · 로그아웃',
                        style: TextStyle(color: palette.textSoft, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: palette.textSoft, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
