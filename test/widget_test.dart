import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibm_money_app/models.dart';
import 'package:ibm_money_app/money_app.dart';
import 'package:ibm_money_app/money_utils.dart';
import 'package:ibm_money_app/product_search_service.dart';

class _FakeProductSearchGateway implements ProductSearchGateway {
  @override
  Future<List<ProductSearchResult>> search(String query) async {
    return const [
      ProductSearchResult(
        id: 'keyboard-1',
        name: '무선 키보드 Pro',
        price: 29900,
        imageUrl: '',
        productUrl: 'https://shop.example.com/keyboard',
        source: '테스트몰',
      ),
    ];
  }
}

void main() {
  test('won formatting uses Korean thousands separators', () {
    expect(formatWon(118700), '118,700원');
    expect(formatWon(0), '0원');
  });

  testWidgets('core savings journey works', (tester) async {
    await tester.binding.setSurfaceSize(const Size(402, 874));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MoneyApp(productSearchGateway: _FakeProductSearchGateway()),
    );
    await tester.pumpAndSettle();

    expect(find.text('김은찬'), findsOneWidget);
    expect(find.text('AirPods'), findsOneWidget);
    expect(find.text('24일 후면 살 수 있어요!'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-insights')));
    await tester.pumpAndSettle();
    expect(find.text('이번 달 한마디'), findsOneWidget);
    expect(find.text('배달이 조금 늘었어요'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-shop')));
    await tester.pumpAndSettle();
    expect(find.text('내 위시리스트'), findsOneWidget);
    expect(find.text('watsonx AI 상품 검색'), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-wish-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('wish-price-field')), findsNothing);
    await tester.enterText(
      find.byKey(const Key('product-search-field')),
      '무선 키보드',
    );
    await tester.tap(find.byKey(const Key('product-search-button')));
    await tester.pumpAndSettle();
    expect(find.text('무선 키보드 Pro'), findsOneWidget);
    expect(find.text('29,900원'), findsOneWidget);
    await tester.tap(find.byKey(const Key('product-result-keyboard-1')));
    await tester.pumpAndSettle();

    expect(find.text('무선 키보드 Pro'), findsOneWidget);
    expect(find.text('지금 사기'), findsOneWidget);

    await tester.tap(find.byKey(const Key('goal-action')));
    await tester.pumpAndSettle();
    expect(find.text('결제'), findsOneWidget);
    expect(find.text('29,900원 결제하기'), findsOneWidget);

    await tester.tap(find.text('29,900원 결제하기'));
    await tester.pumpAndSettle();
    expect(find.text('결제 완료'), findsOneWidget);
  });

  testWidgets('fixed expenses can be registered', (tester) async {
    await tester.binding.setSurfaceSize(const Size(402, 874));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MoneyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-spending')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('add-fixed-expense-button')),
    );
    await tester.tap(find.byKey(const Key('add-fixed-expense-button')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('fixed-name-field')), '넷플릭스');
    await tester.enterText(
      find.byKey(const Key('fixed-amount-field')),
      '17000',
    );
    await tester.enterText(find.byKey(const Key('fixed-day-field')), '15');
    await tester.tap(find.byKey(const Key('save-fixed-expense-button')));
    await tester.pumpAndSettle();

    expect(find.text('넷플릭스'), findsWidgets);
    expect(find.text('월 고정지출'), findsOneWidget);
    expect(find.text('17,000원'), findsWidgets);
    expect(find.text('OTT·구독 · 매월 15일'), findsOneWidget);
  });
}
