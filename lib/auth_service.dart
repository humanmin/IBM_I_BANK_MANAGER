import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

const kakaoNativeAppKey = String.fromEnvironment('KAKAO_NATIVE_APP_KEY');

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
  Future<AppUser?> restoreSession();
  Future<AppUser> signUpWithEmail(String name, String email, String password);
  Future<AppUser> signInWithEmail(String email, String password);
  Future<AppUser> signInWithKakao();
  Future<void> signOut();
  Future<void> deleteAccount();

  /// 서버 API 호출 시 Authorization 헤더에 넣을 ID Token.
  /// 매 호출마다 새로 받아야 함 (만료 시 SDK가 자동 갱신).
  Future<String?> currentIdToken();
}

class FirebaseAuthService implements AuthGateway {
  FirebaseAuthService({fb.FirebaseAuth? auth}) : _auth = auth;

  static const _demoSessionKey = 'signed_in_demo_email_v1';
  static const _returningEmail = 'test001@gmail.com';
  static const _firstTimeEmail = 'test002@gmail.com';
  static const _returningPasswordHash =
      '52a6eb687cd22e80d3342eac6fcc7f2e19209e8f83eb9b82e81c6f3e6f30743b';
  static const _firstTimePasswordHash =
      '1a08785d4897bde6665ece8ff85cc539010a6495c88f0f223999fa73956969ef';

  final fb.FirebaseAuth? _auth;
  final StreamController<AppUser?> _changes =
      StreamController<AppUser?>.broadcast();
  StreamSubscription<fb.User?>? _firebaseSubscription;
  AppUser? _sessionUser;

  // Firebase가 아직 초기화되지 않은 데모·테스트 환경에서도 앱 자체는
  // 시작할 수 있도록 SDK 인스턴스는 인증 기능을 실제로 사용할 때 얻습니다.
  fb.FirebaseAuth get _client => _auth ?? fb.FirebaseAuth.instance;

  AppUser _demoUser(String email) {
    final isReturning = email == _returningEmail;
    return AppUser(
      uid: 'demo:$email',
      provider: AuthProviderType.demo,
      isFirstTime: !isReturning,
      email: email,
      displayName: isReturning ? '김은찬' : '김민진',
    );
  }

  AppUser? _toAppUser(fb.User? user) {
    if (user == null) return null;
    final email = user.email?.trim().toLowerCase();
    final mappedName = switch (email) {
      _returningEmail => '김은찬',
      _firstTimeEmail => '김민진',
      _ => user.displayName ?? email?.split('@').first,
    };
    return AppUser(
      uid: user.uid,
      provider: AuthProviderType.email,
      isFirstTime: email != _returningEmail,
      email: user.email,
      displayName: mappedName,
      photoUrl: user.photoURL,
    );
  }

  AppUser _toKakaoUser(User user) {
    final account = user.kakaoAccount;
    final profile = account?.profile;
    return AppUser(
      uid: 'kakao:${user.id}',
      provider: AuthProviderType.kakao,
      isFirstTime: true,
      email: account?.email,
      displayName: profile?.nickname ?? account?.name ?? '카카오 사용자',
      photoUrl: profile?.profileImageUrl ?? profile?.thumbnailImageUrl,
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
      'operation-not-allowed' => 'Firebase에서 이메일 로그인을 먼저 활성화해 주세요.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => '이메일 또는 비밀번호가 올바르지 않아요.',
      _ => error.message ?? '요청을 처리할 수 없어요.',
    };
  }

  void _emit(AppUser? user) {
    _sessionUser = user;
    if (!_changes.isClosed) _changes.add(user);
  }

  void _listenToFirebase() {
    if (_firebaseSubscription != null) return;
    try {
      _firebaseSubscription = _client.authStateChanges().listen((user) {
        final current = _sessionUser;
        if (current != null && current.provider != AuthProviderType.email) {
          return;
        }
        _emit(_toAppUser(user));
      });
    } catch (_) {
      // Firebase 설정이 없는 테스트 환경에서는 자체 스트림만 사용합니다.
    }
  }

  @override
  Stream<AppUser?> authStateChanges() {
    _listenToFirebase();
    return _changes.stream;
  }

  @override
  AppUser? get currentUser {
    if (_sessionUser case final user?) return user;
    try {
      return _toAppUser(_client.currentUser);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AppUser?> restoreSession() async {
    final preferences = await SharedPreferences.getInstance();
    final demoEmail = preferences.getString(_demoSessionKey);
    if (demoEmail == _returningEmail || demoEmail == _firstTimeEmail) {
      _sessionUser = _demoUser(demoEmail!);
      return _sessionUser;
    }

    try {
      final firebaseUser = _toAppUser(_client.currentUser);
      if (firebaseUser != null) {
        _sessionUser = firebaseUser;
        return firebaseUser;
      }
    } catch (_) {
      // Firebase가 초기화되지 않았으면 카카오 세션 확인으로 넘어갑니다.
    }

    if (kakaoNativeAppKey.isNotEmpty) {
      try {
        final user = _toKakaoUser(await UserApi.instance.me());
        _sessionUser = user;
        return user;
      } catch (_) {
        // 저장된 카카오 토큰이 없거나 만료된 정상적인 로그아웃 상태입니다.
      }
    }
    return null;
  }

  Future<void> _clearDemoSession() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_demoSessionKey);
  }

  @override
  Future<AppUser> signUpWithEmail(
    String name,
    String email,
    String password,
  ) async {
    try {
      await _clearDemoSession();
      final credential = await _client.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final firebaseUser = credential.user!;
      await firebaseUser.updateDisplayName(name.trim());
      await firebaseUser.reload();
      final user = _toAppUser(_client.currentUser ?? firebaseUser)!;
      _emit(user);
      return user;
    } on fb.FirebaseAuthException catch (error) {
      throw AuthException(_messageFor(error));
    } catch (_) {
      _throwUnavailable();
    }
  }

  @override
  Future<AppUser> signInWithEmail(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    final expectedPasswordHash = switch (normalizedEmail) {
      _returningEmail => _returningPasswordHash,
      _firstTimeEmail => _firstTimePasswordHash,
      _ => null,
    };
    if (expectedPasswordHash != null) {
      final passwordHash = sha256.convert(utf8.encode(password)).toString();
      if (passwordHash != expectedPasswordHash) {
        throw const AuthException('이메일 또는 비밀번호가 올바르지 않아요.');
      }
      try {
        await _client.signOut();
      } catch (_) {
        // Firebase 미초기화 상태여도 데모 로그인은 사용할 수 있습니다.
      }
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_demoSessionKey, normalizedEmail);
      final user = _demoUser(normalizedEmail);
      _emit(user);
      return user;
    }

    try {
      await _clearDemoSession();
      final credential = await _client.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final user = _toAppUser(credential.user)!;
      _emit(user);
      return user;
    } on fb.FirebaseAuthException catch (error) {
      throw AuthException(_messageFor(error));
    } catch (_) {
      _throwUnavailable();
    }
  }

  @override
  Future<AppUser> signInWithKakao() async {
    if (kakaoNativeAppKey.isEmpty) {
      throw const AuthException(
        '카카오 Native App Key가 설정되지 않았어요. android/local.properties를 확인해 주세요.',
      );
    }
    try {
      await _clearDemoSession();
      try {
        await _client.signOut();
      } catch (_) {
        // Firebase와 별개의 카카오 로그인은 계속 진행합니다.
      }

      if (await isKakaoTalkInstalled()) {
        try {
          await UserApi.instance.loginWithKakaoTalk();
        } on KakaoClientException catch (error) {
          if (error.reason == ClientErrorCause.cancelled) {
            throw const AuthException('카카오 로그인을 취소했어요.');
          }
          await UserApi.instance.loginWithKakaoAccount();
        } catch (_) {
          await UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        await UserApi.instance.loginWithKakaoAccount();
      }

      final user = _toKakaoUser(await UserApi.instance.me());
      _emit(user);
      return user;
    } on AuthException {
      rethrow;
    } on KakaoClientException catch (error) {
      if (error.reason == ClientErrorCause.cancelled) {
        throw const AuthException('카카오 로그인을 취소했어요.');
      }
      throw const AuthException('카카오 로그인에 실패했어요. 잠시 후 다시 시도해 주세요.');
    } catch (_) {
      throw const AuthException('카카오 로그인에 실패했어요. 카카오 개발자 설정을 확인해 주세요.');
    }
  }

  @override
  Future<void> signOut() async {
    final provider = _sessionUser?.provider;
    await _clearDemoSession();
    if (provider == AuthProviderType.kakao) {
      try {
        await UserApi.instance.logout();
      } catch (_) {
        // SDK는 실패하더라도 로컬 토큰을 폐기합니다.
      }
    }
    try {
      await _client.signOut();
    } catch (_) {
      // 이미 로그아웃 상태이거나 Firebase 미초기화 — 무시
    }
    _emit(null);
  }

  @override
  Future<void> deleteAccount() async {
    final provider = _sessionUser?.provider ?? currentUser?.provider;
    try {
      switch (provider) {
        case AuthProviderType.kakao:
          await UserApi.instance.unlink();
          break;
        case AuthProviderType.email:
          final user = _client.currentUser;
          if (user == null) {
            throw const AuthException('삭제할 로그인 계정을 찾을 수 없어요.');
          }
          await user.delete();
          break;
        case AuthProviderType.demo:
          await _clearDemoSession();
          break;
        case null:
          throw const AuthException('삭제할 로그인 계정을 찾을 수 없어요.');
      }
      await _clearDemoSession();
      _emit(null);
    } on AuthException {
      rethrow;
    } on fb.FirebaseAuthException catch (error) {
      if (error.code == 'requires-recent-login') {
        throw const AuthException('보안을 위해 다시 로그인한 뒤 계정 삭제를 다시 시도해 주세요.');
      }
      throw AuthException(error.message ?? '계정을 삭제하지 못했어요.');
    } on KakaoClientException catch (error) {
      if (error.reason == ClientErrorCause.cancelled) {
        throw const AuthException('계정 삭제를 취소했어요.');
      }
      throw const AuthException('카카오 계정 연결을 해제하지 못했어요. 잠시 후 다시 시도해 주세요.');
    } catch (_) {
      throw const AuthException('계정을 삭제하지 못했어요. 잠시 후 다시 시도해 주세요.');
    }
  }

  @override
  Future<String?> currentIdToken() async {
    if (_sessionUser?.provider != AuthProviderType.email) return null;
    try {
      return await _client.currentUser?.getIdToken();
    } catch (_) {
      return null;
    }
  }
}
