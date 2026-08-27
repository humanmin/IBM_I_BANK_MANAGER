import 'package:flutter/material.dart';

import 'app_widgets.dart';
import 'auth_service.dart';

/// 이메일/비밀번호 로그인 화면.
/// 로그인 없이도 앱의 다른 기능은 전부 쓸 수 있으므로, "게스트로 계속하기"로
/// 언제든 건너뛸 수 있게 합니다 (해커톤 데모 중 Firebase 설정이 안 됐거나
/// 네트워크가 불안정해도 시연이 막히지 않도록 하는 안전장치).
class LoginScreen extends StatefulWidget {
  const LoginScreen({required this.authGateway, super.key});

  final AuthGateway authGateway;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.authGateway.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is AuthException ? error.message : '로그인에 실패했어요.';
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _continueAsGuest() => Navigator.of(context).pop();

  Future<void> _openSignUp() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => SignUpScreen(authGateway: widget.authGateway),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.paletteOf(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '로그인',
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '계좌 연동, 이벤트 참여를 위해 로그인해 주세요.',
                  style: TextStyle(color: palette.textSoft, fontSize: 13),
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: '이메일',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                  validator: (value) {
                    if (value == null || !value.contains('@')) {
                      return '올바른 이메일을 입력해 주세요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: '비밀번호',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return '비밀번호는 6자 이상이어야 해요.';
                    }
                    return null;
                  },
                ),
                if (_error case final message?) ...[
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: const TextStyle(
                      color: Color(0xFFB94747),
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.accent,
                      foregroundColor: palette.text,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('로그인'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _submitting ? null : _openSignUp,
                    child: Text(
                      '계정이 없으신가요? 회원가입',
                      style: TextStyle(
                        color: palette.textSoft,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: _submitting ? null : _continueAsGuest,
                    child: Text(
                      '게스트로 계속하기',
                      style: TextStyle(color: palette.textMuted, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({required this.authGateway, super.key});

  final AuthGateway authGateway;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.authGateway.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      // 회원가입 성공 -> Firebase가 자동으로 로그인 상태로 만들어줌.
      // 로그인 화면, 회원가입 화면 둘 다 닫고 원래 화면으로 복귀.
      final navigator = Navigator.of(context);
      navigator.pop();
      navigator.pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is AuthException ? error.message : '회원가입에 실패했어요.';
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.paletteOf(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: palette.text,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '회원가입',
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: '이메일',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                  validator: (value) {
                    if (value == null || !value.contains('@')) {
                      return '올바른 이메일을 입력해 주세요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: '비밀번호',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return '비밀번호는 6자 이상이어야 해요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: '비밀번호 확인',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return '비밀번호가 일치하지 않아요.';
                    }
                    return null;
                  },
                ),
                if (_error case final message?) ...[
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: const TextStyle(
                      color: Color(0xFFB94747),
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.accent,
                      foregroundColor: palette.text,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('가입하기'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 로그인/회원가입 직후 홈에 보여 줄 이름을 받는 하단 시트.
class DisplayNameSheet extends StatefulWidget {
  const DisplayNameSheet({this.initialName, super.key});

  final String? initialName;

  @override
  State<DisplayNameSheet> createState() => _DisplayNameSheetState();
}

class _DisplayNameSheetState extends State<DisplayNameSheet> {
  late final TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(context, _nameController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.paletteOf(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSheetHeader(
                icon: Icons.badge_outlined,
                title: '이름을 알려 주세요',
                subtitle: '홈 화면에 이 이름으로 인사할게요.',
                onClose: () => Navigator.pop(context),
              ),
              const SizedBox(height: 20),
              TextFormField(
                key: const Key('display-name-field'),
                controller: _nameController,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: '이름',
                  hintText: '예: 민진',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  final name = value?.trim() ?? '';
                  if (name.isEmpty) return '이름을 입력해 주세요.';
                  if (name.length > 12) return '이름은 12자 이하로 입력해 주세요.';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('save-display-name-button'),
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.accent,
                    foregroundColor: palette.text,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _submit,
                  child: const Text('저장하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
