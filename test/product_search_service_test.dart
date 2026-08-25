import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ibm_money_app/product_search_service.dart';

void main() {
  test('product search service parses backend products', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/products/search');
      expect(request.url.queryParameters['q'], '무선 키보드');
      return http.Response(
        '''{"items":[{"id":"p1","name":"무선 키보드","price":45900,"imageUrl":"https://example.com/product.jpg","productUrl":"https://example.com/product","source":"테스트몰"}]}''',
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final service = ProductSearchService(
      client: client,
      baseUrl: 'https://api.example.com',
    );
    addTearDown(service.close);

    final results = await service.search('무선 키보드');

    expect(results, hasLength(1));
    expect(results.single.name, '무선 키보드');
    expect(results.single.price, 45900);
    expect(results.single.source, '테스트몰');
  });

  test('product search service surfaces backend errors', () async {
    final service = ProductSearchService(
      client: MockClient(
        (_) async => http.Response(
          '{"error":"설정이 필요합니다."}',
          503,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
      baseUrl: 'https://api.example.com',
    );
    addTearDown(service.close);

    expect(
      () => service.search('키보드'),
      throwsA(
        isA<ProductSearchException>().having(
          (error) => error.message,
          'message',
          '설정이 필요합니다.',
        ),
      ),
    );
  });
}
