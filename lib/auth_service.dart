import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'models.dart';

/// 로그인 관련 사용자 대상 에러 메시지.
/// (event_service.dart의 EventException, account_service.dart의
///  AccountException과 동일한 패턴 — 화면에 그대로 보여줄 한국어 메시지)
class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// firebase_auth SDK를 화면 코드로부터 감싸는 얇은 레이어.
/// (product_search_service.dart의 ProductSearchGateway와 동일한 목적 —
///  화면 위젯이 특정 SDK에 직접 의존하지 않도록 함, 테스트 시 mock 대체 가능)
abstract interface class AuthGateway {
  Stream<AppUser?> authStateChanges();
  AppUser? get currentUser;
  Future<AppUser> signUpWithEmail(String email, String password);
  Future<AppUser> signInWithEmail(String email, String password);
  Future<void> signOut();

  /// 서버 API 호출 시 Authorization 헤더에 넣을 ID Token.
  /// 매 호출마다 새로 받아야 함 (만료 시 SDK가 자동 갱신).
  Future<String?> currentIdToken();
}

class FirebaseAuthService implements AuthGateway {
  FirebaseAuthService({fb.FirebaseAuth? auth}) : _auth = auth;

  final fb.FirebaseAuth? _auth;

  // Firebase가 아직 초기화되지 않은 데모·테스트 환경에서도 앱 자체는
  // 시작할 수 있도록 SDK 인스턴스는 인증 기능을 실제로 사용할 때 얻습니다.
  fb.FirebaseAuth get _client => _auth ?? fb.FirebaseAuth.instance;

  AppUser? _toAppUser(fb.User? user) {
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
    );
  }

  /// Firebase 프로젝트 연결 전(FlutterFire 설정 전)에는 이 메시지를 보여줍니다.
  Never _throwUnavailable() {
    throw const AuthException('로그인 기능이 아직 준비되지 않았어요. 잠시 후 다시 시도해 주세요.');
  }

  String _messageFor(fb.FirebaseAuthException error) {
    return switch (error.code) {
      'email-already-in-use' => '이미 가입된 이메일이에요.',
      'invalid-email' => '이메일 형식을 확인해 주세요.',
      'weak-password' => '비밀번호는 6자 이상으로 설정해 주세요.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => '이메일 또는 비밀번호가 올바르지 않아요.',
      _ => error.message ?? '요청을 처리할 수 없어요.',
    };
  }

  @override
  Stream<AppUser?> authStateChanges() {
    try {
      return _client.authStateChanges().map(_toAppUser);
    } catch (_) {
      // Firebase 미초기화 — 로그인 안 된 상태로 취급하고 앱은 계속 진행
      return Stream.value(null);
    }
  }

  @override
  AppUser? get currentUser {
    try {
      return _toAppUser(_client.currentUser);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AppUser> signUpWithEmail(String email, String password) async {
    try {
      final credential = await _client.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _toAppUser(credential.user)!;
    } on fb.FirebaseAuthException catch (error) {
      throw AuthException(_messageFor(error));
    } catch (_) {
      _throwUnavailable();
    }
  }

  @override
  Future<AppUser> signInWithEmail(String email, String password) async {
    try {
      final credential = await _client.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _toAppUser(credential.user)!;
    } on fb.FirebaseAuthException catch (error) {
      throw AuthException(_messageFor(error));
    } catch (_) {
      _throwUnavailable();
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.signOut();
    } catch (_) {
      // 이미 로그아웃 상태이거나 Firebase 미초기화 — 무시
    }
  }

  @override
  Future<String?> currentIdToken() async {
    try {
      return await _client.currentUser?.getIdToken();
    } catch (_) {
      return null;
    }
  }
}
