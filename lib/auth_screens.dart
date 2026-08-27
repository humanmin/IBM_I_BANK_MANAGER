import 'package:flutter/material.dart';

import 'app_widgets.dart';
import 'auth_service.dart';

enum AuthEntryMode { login, signUp }

class AuthWelcomeScreen extends StatelessWidget {
  const AuthWelcomeScreen({required this.authGateway, super.key});

  final AuthGateway authGateway;

  void _openMethods(BuildContext context, AuthEntryMode mode) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => AuthMethodScreen(authGateway: authGateway, mode: mode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.paletteOf(context);
    return Scaffold(
      backgroundColor: palette.pageBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Image.asset(
                  'assets/images/app_logo_transparent.png',
                  key: const Key('auth-brand-logo'),
                  width: 104,
                  height: 104,
                  fit: BoxFit.contain,
                  semanticLabel: '아이뱅크매니저 로고',
                ),
                const SizedBox(height: 18),
                Text(
                  '아이뱅크매니저',
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 29,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '내 소비를 확인하고 갖고 싶은 목표를\n한 걸음씩 준비해 보세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: palette.textSoft,
                    fontSize: 14,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 54),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('auth-login-entry'),
                    onPressed: () => _openMethods(context, AuthEntryMode.login),
                    child: const Text('로그인'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    key: const Key('auth-signup-entry'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: palette.text,
                      side: BorderSide(color: palette.accentBorder),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () =>
                        _openMethods(context, AuthEntryMode.signUp),
                    child: const Text('회원가입'),
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

class AuthMethodScreen extends StatefulWidget {
  const AuthMethodScreen({
    required this.authGateway,
    required this.mode,
    super.key,
  });

  final AuthGateway authGateway;
  final AuthEntryMode mode;

  @override
  State<AuthMethodScreen> createState() => _AuthMethodScreenState();
}

class _AuthMethodScreenState extends State<AuthMethodScreen> {
  bool _submitting = false;
  String? _error;

  Future<void> _openEmail() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => widget.mode == AuthEntryMode.login
            ? LoginScreen(authGateway: widget.authGateway)
            : SignUpScreen(authGateway: widget.authGateway),
      ),
    );
  }

  Future<void> _startKakao() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.authGateway.signInWithKakao();
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is AuthException ? error.message : '카카오 로그인에 실패했어요.';
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.paletteOf(context);
    final isLogin = widget.mode == AuthEntryMode.login;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: palette.text,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isLogin ? '로그인 방법을 선택해 주세요' : '회원가입 방법을 선택해 주세요',
                style: TextStyle(
                  color: palette.text,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isLogin
                    ? '사용하던 계정으로 이어서 시작할 수 있어요.'
                    : '이메일 또는 카카오 계정으로 간편하게 시작해요.',
                style: TextStyle(color: palette.textSoft, fontSize: 13),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: Key(
                    isLogin ? 'email-login-option' : 'email-signup-option',
                  ),
                  onPressed: _submitting ? null : _openEmail,
                  icon: const Icon(Icons.mail_outline_rounded),
                  label: Text(isLogin ? '이메일로 로그인' : '이메일로 회원가입하기'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: palette.text,
                    side: BorderSide(color: palette.accentBorder),
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: Key(
                    isLogin ? 'kakao-login-option' : 'kakao-signup-option',
                  ),
                  onPressed: _submitting ? null : _startKakao,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chat_bubble_rounded),
                  label: Text(isLogin ? '카카오로 로그인' : '카카오로 시작하기'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFEE500),
                    foregroundColor: const Color(0xFF191919),
                    padding: const EdgeInsets.symmetric(vertical: 17),
                  ),
                ),
              ),
              if (_error case final message?) ...[
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFFB94747),
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Firebase 이메일/비밀번호 로그인 폼.
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
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is AuthException ? error.message : '로그인에 실패했어요.';
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

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
                  key: const Key('email-login-email-field'),
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
                  key: const Key('email-login-password-field'),
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: '비밀번호',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '비밀번호를 입력해 주세요.';
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
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
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
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
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
                  key: const Key('email-signup-name-field'),
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: '이름',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '이름을 입력해 주세요.';
                    }
                    if (value.trim().length > 30) {
                      return '이름은 30자 이하로 입력해 주세요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const Key('email-signup-email-field'),
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
                  key: const Key('email-signup-password-field'),
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
                  key: const Key('email-signup-confirm-field'),
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
