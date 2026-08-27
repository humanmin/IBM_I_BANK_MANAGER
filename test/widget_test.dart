import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibm_money_app/models.dart';
import 'package:ibm_money_app/money_app.dart';
import 'package:ibm_money_app/money_utils.dart';
import 'package:ibm_money_app/product_search_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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

    await tester.tap(find.byKey(const Key('nav-spending')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('이번 달 한마디'),
      350,
      scrollable: find.descendant(
        of: find.byKey(const PageStorageKey('spending-scroll')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('이번 달 한마디'), findsOneWidget);
    expect(find.text('배달이 조금 늘었어요'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('open-shop-button')));
    await tester.tap(find.byKey(const Key('open-shop-button')));
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

  testWidgets('account menu switches to the first-time user home', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(402, 874));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MoneyApp(productSearchGateway: _FakeProductSearchGateway()),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('first-time-user-home')), findsNothing);
    expect(find.text('AirPods'), findsOneWidget);

    await tester.tap(find.byKey(const Key('account-profile-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('김민진').last);
    await tester.pumpAndSettle();

    expect(find.text('김민진'), findsOneWidget);
    expect(find.byKey(const Key('first-time-user-home')), findsOneWidget);
    expect(find.text('김민진님, 반가워요!'), findsOneWidget);
    expect(find.byKey(const Key('first-goal-button')), findsOneWidget);
    expect(find.byKey(const Key('first-import-button')), findsOneWidget);
    expect(find.text('AirPods'), findsNothing);
    expect(find.text('257,230원'), findsNothing);

    await tester.tap(find.byKey(const Key('nav-spending')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('first-time-spending-empty')), findsOneWidget);
    expect(find.byKey(const Key('category-pie-chart')), findsNothing);
    expect(find.byKey(const Key('spending-bar-card')), findsNothing);
    expect(find.byKey(const Key('recent-transactions-button')), findsNothing);

    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('first-goal-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('first-time-shopping-empty')), findsOneWidget);
    expect(find.text('AirPods'), findsNothing);
    expect(find.text('현재 저축 목표'), findsNothing);
    expect(find.byKey(const Key('add-wish-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('shop-back-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('account-profile-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('김은찬').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('first-time-user-home')), findsNothing);
    expect(find.text('AirPods'), findsOneWidget);
  });

  testWidgets('restores the selected user and imported statistics', (
    tester,
  ) async {
    final now = DateTime.now();
    SharedPreferences.setMockInitialValues({
      'selected_home_user_profile_v1': 'firstTimeUser',
      'account_data_kim_minjin_v1': jsonEncode({
        'balance': 310000,
        'lastUpdated': now.toIso8601String(),
        'transactions': [
          {
            'id': 'saved-minjin-1',
            'merchant': '스타벅스',
            'category': '카페',
            'amount': 6500,
            'date': now.toIso8601String(),
          },
        ],
      }),
    });
    expect(
      (await SharedPreferences.getInstance()).getString(
        'selected_home_user_profile_v1',
      ),
      'firstTimeUser',
    );
    await tester.binding.setSurfaceSize(const Size(402, 874));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MoneyApp(productSearchGateway: _FakeProductSearchGateway()),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('김민진'), findsOneWidget);
    expect(find.text('소비 데이터 연결 완료'), findsOneWidget);
    await tester.tap(find.byKey(const Key('nav-spending')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('first-time-spending-empty')), findsNothing);
    expect(find.byKey(const Key('category-pie-card')), findsOneWidget);
    expect(find.byKey(const Key('spending-bar-card')), findsOneWidget);
    expect(find.byKey(const Key('category-pie-chart')), findsOneWidget);
  });

  testWidgets('saving action wraps as a whole and stays left aligned', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(402, 874));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MoneyApp(productSearchGateway: _FakeProductSearchGateway()),
    );
    await tester.pumpAndSettle();

    final amountField = find.byKey(const Key('saving-amount-field'));
    final savingSentence = find.byKey(const Key('saving-sentence-wrap'));
    final savingPeriod = find.byKey(const Key('saving-period-menu'));
    final wonText = find.text('원을');
    final savingAction = find.text('저축하기');
    expect(
      (tester.getCenter(amountField).dy - tester.getCenter(savingAction).dy)
          .abs(),
      lessThan(10),
    );
    final sentenceLeftX = tester.getTopLeft(savingSentence).dx;
    expect(
      (sentenceLeftX - tester.getTopLeft(savingPeriod).dx).abs(),
      lessThan(2),
    );
    expect(
      tester.getTopLeft(savingAction).dx - tester.getTopRight(wonText).dx,
      greaterThanOrEqualTo(3),
    );

    await tester.enterText(amountField, '1000000');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(savingAction).dy,
      greaterThan(tester.getBottomLeft(find.text('원을')).dy),
    );
    expect(tester.getSize(savingAction).height, lessThan(40));
    expect(
      (sentenceLeftX - tester.getTopLeft(savingAction).dx).abs(),
      lessThan(2),
    );
  });

  testWidgets('forms and popups share the polished component theme', (
    tester,
  ) async {
    await tester.pumpWidget(const MoneyApp());

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    final theme = materialApp.theme!;

    expect(theme.inputDecorationTheme.filled, isTrue);
    expect(theme.inputDecorationTheme.border, isA<OutlineInputBorder>());
    expect(theme.dialogTheme.shape, isA<RoundedRectangleBorder>());
    expect(theme.bottomSheetTheme.showDragHandle, isTrue);
    expect(theme.popupMenuTheme.shape, isA<RoundedRectangleBorder>());
    expect(theme.popupMenuTheme.position, PopupMenuPosition.under);
  });

  testWidgets('mouse scrolling uses clamped app scroll behavior', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(402, 874));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MoneyApp());
    await tester.pumpAndSettle();

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    final scrollBehavior = materialApp.scrollBehavior;

    expect(scrollBehavior, isA<AppScrollBehavior>());
    expect(scrollBehavior!.dragDevices, contains(PointerDeviceKind.mouse));
    expect(scrollBehavior.dragDevices, contains(PointerDeviceKind.trackpad));
    expect(
      scrollBehavior.getScrollPhysics(tester.element(find.byType(MaterialApp))),
      isA<ClampingScrollPhysics>(),
    );

    await tester.tap(find.byKey(const Key('nav-spending')));
    await tester.pumpAndSettle();

    final spendingList = tester.widget<ListView>(
      find.byKey(const PageStorageKey('spending-scroll')),
    );
    final position = spendingList.controller!.position;
    position.pointerScroll(10000);
    expect(position.pixels, inInclusiveRange(1, 120));
    position.pointerScroll(-10000);
    expect(position.pixels, 0);
  });

  testWidgets('fixed expenses can be registered', (tester) async {
    await tester.binding.setSurfaceSize(const Size(402, 874));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MoneyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-spending')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('add-fixed-expense-button')),
      350,
      scrollable: find.descendant(
        of: find.byKey(const PageStorageKey('spending-scroll')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(
      tester.widget(find.byKey(const Key('add-fixed-expense-button'))),
      isA<TextButton>(),
    );
    final addButtonSize = tester.getSize(
      find.byKey(const Key('add-fixed-expense-button')),
    );
    expect(addButtonSize.width, greaterThan(300));
    expect(addButtonSize.height, greaterThanOrEqualTo(44));
    expect(find.text('+ 등록'), findsOneWidget);
    final addButton = tester.widget<TextButton>(
      find.byKey(const Key('add-fixed-expense-button')),
    );
    expect(
      addButton.style?.foregroundColor?.resolve(<WidgetState>{}),
      const Color(0xFF9A9A9A),
    );
    await tester.ensureVisible(
      find.byKey(const Key('add-fixed-expense-button')),
    );
    await tester.pumpAndSettle();
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

  testWidgets('settings title sits near the top of the tab', (tester) async {
    await tester.binding.setSurfaceSize(const Size(402, 874));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MoneyApp(productSearchGateway: _FakeProductSearchGateway()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-settings')));
    await tester.pumpAndSettle();

    expect(find.text('설정'), findsWidgets);
    // If AnimatedSwitcher centered the short settings page, this title
    // would sit around the middle of the 874-tall surface.
    expect(tester.getTopLeft(find.text('설정').first).dy, lessThan(48));
  });

  testWidgets('spending summary keeps only the compact data card', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(402, 874));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MoneyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-spending')));
    await tester.pumpAndSettle();

    expect(find.text('현재 잔액'), findsNothing);
    expect(find.byKey(const Key('account-balance-value')), findsNothing);
    expect(find.text('이번 달 총 지출'), findsNothing);
    expect(find.text('가장 많이 쓴 곳'), findsNothing);
    expect(find.text('가장 많이 쓴 카테고리'), findsNothing);
    expect(find.byKey(const Key('top-category-card')), findsNothing);
    expect(find.text('거래 횟수'), findsNothing);
    expect(find.text('건당 평균'), findsNothing);
    expect(find.text('하루 평균'), findsNothing);
    expect(find.byKey(const Key('category-pie-card')), findsOneWidget);
    expect(find.byKey(const Key('category-pie-chart')), findsOneWidget);
    expect(find.byKey(const Key('spending-bar-card')), findsOneWidget);
    expect(find.text('최근 7일 사용량'), findsOneWidget);
    await tester.tap(find.byKey(const Key('spending-bar-weekly')));
    await tester.pumpAndSettle();
    expect(find.text('이번 달 주간별 사용량'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('account-data-card'))).height,
      lessThanOrEqualTo(130),
    );

    expect(find.byKey(const Key('recent-transactions-button')), findsNothing);
    expect(find.byKey(const Key('recent-transactions-sheet')), findsNothing);

    await tester.tap(find.byKey(const Key('nav-history')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('recent-transactions-sheet')), findsOneWidget);
    expect(find.byKey(const Key('recent-filter-all')), findsOneWidget);
    expect(find.text('최근 내역'), findsWidgets);
    expect(find.text('거래 횟수'), findsOneWidget);
    expect(find.text('건당 평균'), findsOneWidget);
    expect(find.text('하루 평균'), findsOneWidget);
    expect(find.text('가장 많이 쓴 카테고리'), findsOneWidget);
    expect(find.byKey(const Key('top-category-card')), findsOneWidget);

    final topCard = find.byKey(const Key('top-category-card'));
    final startY = tester.getTopLeft(topCard).dy;
    await tester.drag(
      find.byKey(const Key('recent-transactions-sheet')),
      const Offset(0, -240),
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(topCard).dy, lessThan(startY - 80));
  });
}
