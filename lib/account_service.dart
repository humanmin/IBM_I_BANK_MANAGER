import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';
import 'models.dart';

abstract interface class AccountGateway {
  /// 오픈뱅킹 동의 화면(WebView)에 열 URL을 서버로부터 받아온다.
  Future<String> requestLinkUrl();

  Future<List<BankAccount>> fetchAccounts();
  Future<BankAccount> refreshAccount(String accountId);
  Future<void> unlinkAccount(String accountId);
}

class AccountException implements Exception {
  const AccountException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AccountService implements AccountGateway {
  AccountService({
    required AuthGateway auth,
    http.Client? client,
    String? baseUrl,
  }) : _auth = auth,
       _client = client ?? http.Client(),
       _baseUrl = baseUrl ?? _configuredBaseUrl;

  static const _configuredBaseUrl = String.fromEnvironment(
    'PRODUCT_SEARCH_API_URL', // 기존 서버 주소 설정과 동일 환경변수를 재사용
    defaultValue: 'http://10.0.2.2:8080',
  );

  final AuthGateway _auth;
  final http.Client _client;
  final String _baseUrl;

  Future<Map<String, String>> _authHeaders() async {
    final token = await _auth.currentIdToken();
    if (token == null) {
      throw const AccountException('로그인이 필요해요.');
    }
    return {'Authorization': 'Bearer $token', 'Accept': 'application/json'};
  }

  Uri _uri(String path) =>
      Uri.parse('${_baseUrl.replaceAll(RegExp(r'/+$'), '')}$path');

  @override
  Future<String> requestLinkUrl() async {
    final response = await _client.post(
      _uri('/api/accounts/link/start'),
      headers: await _authHeaders(),
    );
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200 || body['url'] is! String) {
      throw AccountException(
        (body is Map ? body['error'] as String? : null) ?? '계좌 연결을 시작할 수 없어요.',
      );
    }
    return body['url'] as String;
  }

  @override
  Future<List<BankAccount>> fetchAccounts() async {
    final response = await _client.get(
      _uri('/api/accounts'),
      headers: await _authHeaders(),
    );
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200 || body['items'] is! List) {
      throw const AccountException('계좌 정보를 불러올 수 없어요.');
    }
    return (body['items'] as List)
        .whereType<Map<String, dynamic>>()
        .map(BankAccount.fromJson)
        .toList();
  }

  @override
  Future<BankAccount> refreshAccount(String accountId) async {
    final response = await _client.post(
      _uri('/api/accounts/$accountId/refresh'),
      headers: await _authHeaders(),
    );
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200) {
      throw const AccountException('잔액을 갱신할 수 없어요.');
    }
    return BankAccount.fromJson(body as Map<String, dynamic>);
  }

  @override
  Future<void> unlinkAccount(String accountId) async {
    final response = await _client.delete(
      _uri('/api/accounts/$accountId'),
      headers: await _authHeaders(),
    );
    if (response.statusCode != 200) {
      throw const AccountException('연결 해제에 실패했어요.');
    }
  }

  void close() => _client.close();
}
