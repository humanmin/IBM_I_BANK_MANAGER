import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

abstract interface class ProductSearchGateway {
  Future<List<ProductSearchResult>> search(String query);
}

class ProductSearchException implements Exception {
  const ProductSearchException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ProductSearchService implements ProductSearchGateway {
  ProductSearchService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? _configuredBaseUrl;

  static const _configuredBaseUrl = String.fromEnvironment(
    'PRODUCT_SEARCH_API_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  final http.Client _client;
  final String _baseUrl;

  @override
  Future<List<ProductSearchResult>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      throw const ProductSearchException('두 글자 이상 입력해 주세요.');
    }

    final root = _baseUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse(
      '$root/api/products/search',
    ).replace(queryParameters: {'q': trimmed});

    try {
      final response = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 20));
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode != 200) {
        final message = body is Map<String, dynamic>
            ? body['error'] as String?
            : null;
        throw ProductSearchException(message ?? '상품 검색에 실패했어요.');
      }
      if (body is! Map<String, dynamic> || body['items'] is! List) {
        throw const ProductSearchException('검색 결과 형식을 확인할 수 없어요.');
      }
      return (body['items'] as List)
          .whereType<Map<String, dynamic>>()
          .map(ProductSearchResult.fromJson)
          .where((item) => item.price > 0 && item.name.isNotEmpty)
          .toList();
    } on ProductSearchException {
      rethrow;
    } on FormatException {
      throw const ProductSearchException('검색 서버 응답을 읽을 수 없어요.');
    } catch (_) {
      throw const ProductSearchException(
        '상품 검색 서버에 연결할 수 없어요. 잠시 후 다시 시도해 주세요.',
      );
    }
  }

  void close() => _client.close();
}
