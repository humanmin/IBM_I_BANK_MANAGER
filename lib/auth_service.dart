import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'models.dart';

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

  @override
  Stream<AppUser?> authStateChanges() =>
      _client.authStateChanges().map(_toAppUser);

  @override
  AppUser? get currentUser => _toAppUser(_client.currentUser);

  @override
  Future<AppUser> signUpWithEmail(String email, String password) async {
    final credential = await _client.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _toAppUser(credential.user)!;
  }

  @override
  Future<AppUser> signInWithEmail(String email, String password) async {
    final credential = await _client.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _toAppUser(credential.user)!;
  }

  @override
  Future<void> signOut() => _client.signOut();

  @override
  Future<String?> currentIdToken() async {
    return _client.currentUser?.getIdToken();
  }
}
