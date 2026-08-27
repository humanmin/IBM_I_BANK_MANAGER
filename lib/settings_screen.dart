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
    required this.onDeleteAccount,
    super.key,
  });

  final AppUser? currentUser;
  final VoidCallback onOpenAccount;
  final Future<void> Function() onDeleteAccount;

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
          if (user != null) ...[
            const SizedBox(height: 10),
            _DeleteAccountButton(user: user, onDeleteAccount: onDeleteAccount),
          ],
        ],
      ),
    );
  }
}

class _DeleteAccountButton extends StatelessWidget {
  const _DeleteAccountButton({
    required this.user,
    required this.onDeleteAccount,
  });

  final AppUser user;
  final Future<void> Function() onDeleteAccount;

  Future<void> _showDeleteDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          _DeleteAccountDialog(user: user, onDeleteAccount: onDeleteAccount),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        key: const Key('delete-account-button'),
        onPressed: () => _showDeleteDialog(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFB42318),
          side: const BorderSide(color: Color(0x33B42318)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: const Icon(Icons.person_remove_outlined, size: 19),
        label: const Text(
          '계정 삭제',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({
    required this.user,
    required this.onDeleteAccount,
  });

  final AppUser user;
  final Future<void> Function() onDeleteAccount;

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _deleting = false;
  String? _errorText;

  String get _expectedName {
    final displayName = widget.user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) return displayName;
    return widget.user.email?.trim() ?? '사용자';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    setState(() {
      _deleting = true;
      _errorText = null;
    });
    try {
      await widget.onDeleteAccount();
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _deleting = false;
        _errorText = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.paletteOf(context);
    final matches = _controller.text.trim() == _expectedName;
    return AlertDialog(
      key: const Key('delete-account-dialog'),
      title: const Text('계정을 삭제할까요?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '계정과 이 휴대폰에 저장된 소비 데이터를 삭제합니다. 이 작업은 되돌릴 수 없어요.',
              style: TextStyle(
                color: palette.textSoft,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '계속하려면 아래에 “$_expectedName”을 입력하세요.',
              style: TextStyle(
                color: palette.text,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const Key('delete-account-name-field'),
              controller: _controller,
              enabled: !_deleting,
              autofocus: true,
              onChanged: (_) => setState(() => _errorText = null),
              decoration: InputDecoration(
                hintText: _expectedName,
                errorText: _errorText,
                filled: true,
                fillColor: mutedBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _deleting ? null : () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          key: const Key('confirm-delete-account-button'),
          onPressed: !matches || _deleting ? null : _delete,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFB42318),
            foregroundColor: Colors.white,
          ),
          child: _deleting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('계정 삭제'),
        ),
      ],
    );
  }
}
