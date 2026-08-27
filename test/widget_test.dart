import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ibm_money_app/account_data_service.dart';
import 'package:ibm_money_app/app_widgets.dart';
import 'package:ibm_money_app/auth_service.dart';
import 'package:ibm_money_app/home_screen.dart';
import 'package:ibm_money_app/home_goal_widget_service.dart';
import 'package:ibm_money_app/models.dart';
import 'package:ibm_money_app/money_app.dart';
import 'package:ibm_money_app/money_utils.dart';
import 'package:ibm_money_app/product_search_service.dart';
import 'package:ibm_money_app/seed_data.dart';
import 'package:ibm_money_app/user_data_service.dart';
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

const _returningUser = AppUser(
  uid: 'demo:test001@gmail.com',
  provider: AuthProviderType.demo,
  isFirstTime: false,
  email: 'test001@gmail.com',
  displayName: '김은찬',
);

const _firstTimeUser = AppUser(
  uid: 'demo:test002@gmail.com',
  provider: AuthProviderType.demo,
  isFirstTime: true,
  email: 'test002@gmail.com',
  displayName: '김민진',
);

class _FakeAuthGateway implements AuthGateway {
  _FakeAuthGateway({this.user});

  AppUser? user;
  final _changes = StreamController<AppUser?>.broadcast();

  @override
  Stream<AppUser?> authStateChanges() => _changes.stream;

  @override
  AppUser? get currentUser => user;

  @override
  Future<AppUser?> restoreSession() async => user;

  @override
  Future<AppUser> signInWithEmail(String email, String password) async {
    user = email == _firstTimeUser.email ? _firstTimeUser : _returningUser;
    _changes.add(user);
    return user!;
  }

  @override
  Future<AppUser> signUpWithEmail(
    String name,
    String email,
    String password,
  ) async {
    user = AppUser(
      uid: 'firebase:$email',
      provider: AuthProviderType.email,
      isFirstTime: true,
      email: email,
      displayName: name,
    );
    _changes.add(user);
    return user!;
  }

  @override
  Future<AppUser> signInWithKakao() async {
    user = const AppUser(
      uid: 'kakao:1',
      provider: AuthProviderType.kakao,
      isFirstTime: true,
      displayName: '카카오 사용자',
      photoUrl: 'https://example.com/profile.png',
    );
    _changes.add(user);
    return user!;
  }

  @override
  Future<void> signOut() async {
    user = null;
    _changes.add(null);
  }

  @override
  Future<void> deleteAccount() async {
    user = null;
    _changes.add(null);
  }

  @override
  Future<String?> currentIdToken() async => null;

  void emitUser(AppUser? nextUser) {
    user = nextUser;
    _changes.add(nextUser);
  }
}

class _DelayedAuthGateway extends _FakeAuthGateway {
  _DelayedAuthGateway({required AppUser restoredUser})
    : _restoredUser = restoredUser,
      super(user: restoredUser);

  final AppUser _restoredUser;
  final Completer<AppUser?> restoreCompleter = Completer<AppUser?>();

  @override
  Future<AppUser?> restoreSession() => restoreCompleter.future;

  void finishRestore() => restoreCompleter.complete(_restoredUser);
}

class _FakeGoalWidgetGateway implements GoalWidgetGateway {
  SavingsGoal? lastGoal;
  bool? lastHasSelectedGoal;
  var clearCount = 0;

  @override
  Future<void> syncGoal({
    required SavingsGoal goal,
    required bool hasSelectedGoal,
  }) async {
    lastGoal = goal;
    lastHasSelectedGoal = hasSelectedGoal;
  }

  @override
  Future<void> clear() async {
    clearCount += 1;
  }
}

Widget _testApp({
  AppUser? user = _returningUser,
  AuthGateway? authGateway,
  ProductSearchGateway? productSearchGateway,
  GoalWidgetGateway? goalWidgetGateway,
}) {
  return MoneyApp(
    authGateway: authGateway ?? _FakeAuthGateway(user: user),
    productSearchGateway: productSearchGateway,
    goalWidgetGateway: goalWidgetGateway ?? _FakeGoalWidgetGateway(),
  );
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
      _testApp(productSearchGateway: _FakeProductSearchGateway()),
    );
    await tester.pumpAndSettle();

    expect(find.text('김은찬'), findsOneWidget);
    expect(find.text('AirPods'), findsOneWidget);
    expect(find.text('24일 후면 살 수 있어요!'), findsOneWidget);
    expect(find.byKey(const Key('account-profile-menu')), findsNothing);
    expect(find.byKey(const Key('account-label')), findsOneWidget);
    expect(find.textContaining('현재 잔액'), findsNothing);

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

  testWidgets('auth entry screens expose email and Kakao options', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(402, 874));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_testApp(user: null));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('auth-login-entry')), findsOneWidget);
    expect(find.byKey(const Key('auth-signup-entry')), findsOneWidget);
    expect(find.byKey(const Key('auth-brand-logo')), findsOneWidget);
    expect(find.byIcon(Icons.savings_outlined), findsNothing);
    expect(find.byKey(const Key('nav-home')), findsNothing);

    await tester.tap(find.byKey(const Key('auth-login-entry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('email-login-option')), findsOneWidget);
    expect(find.byKey(const Key('kakao-login-option')), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('auth-signup-entry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('email-signup-option')), findsOneWidget);
    expect(find.byKey(const Key('kakao-signup-option')), findsOneWidget);
    await tester.tap(find.byKey(const Key('email-signup-option')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('email-signup-name-field')), findsOneWidget);
    expect(find.text('이름'), findsOneWidget);
  });

  testWidgets('restored savings goal is synchronized to the home widget', (
    tester,
  ) async {
    final goalWidget = _FakeGoalWidgetGateway();

    await tester.pumpWidget(
      _testApp(user: _returningUser, goalWidgetGateway: goalWidget),
    );
    await tester.pumpAndSettle();

    expect(goalWidget.lastGoal?.name, initialGoal.name);
    expect(goalWidget.lastHasSelectedGoal, isTrue);
  });

  testWidgets('does not flash the login screen while restoring a session', (
    tester,
  ) async {
    final auth = _DelayedAuthGateway(restoredUser: _firstTimeUser);
    await tester.pumpWidget(_testApp(authGateway: auth));
    await tester.pump();

    auth.emitUser(null);
    await tester.pump();
    expect(find.byKey(const Key('auth-login-entry')), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    auth.finishRestore();
    await tester.pumpAndSettle();
    expect(find.text('김민진'), findsOneWidget);
    expect(find.byKey(const Key('auth-login-entry')), findsNothing);
  });

  testWidgets('restores consumer data and a selected goal after login', (
    tester,
  ) async {
    final accountKey =
        'account_data_v2_${UserDataService.keyForUser(_firstTimeUser.uid)}';
    await AccountDataService(storageKey: accountKey).save(
      AccountData(
        balance: 150000,
        transactions: [
          MoneyTransaction(
            id: 'saved-transaction',
            merchant: '저장된 카페',
            category: '카페',
            amount: 5500,
            date: DateTime(2026, 8, 27),
          ),
        ],
        isDemo: false,
      ),
    );
    await UserDataService(userId: _firstTimeUser.uid).save(
      goal: const SavingsGoal(
        name: '저장된 키보드',
        imageAsset: null,
        price: 99000,
        saved: 10000,
        savingAmount: 5000,
        savingPeriod: SavingPeriod.daily,
      ),
      hasSelectedGoal: true,
      wishItems: const [],
      fixedExpenses: const [],
    );

    await tester.pumpWidget(_testApp(user: _firstTimeUser));
    await tester.pumpAndSettle();

    expect(find.text('저장된 키보드'), findsOneWidget);
    await tester.tap(find.byKey(const Key('nav-spending')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('first-time-spending-empty')), findsNothing);
    expect(find.byKey(const Key('category-pie-card')), findsOneWidget);
  });

  testWidgets('four digit demo login opens the matching account', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(402, 874));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_testApp(user: null));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('auth-login-entry')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('email-login-option')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('email-login-email-field')),
      'test002@gmail.com',
    );
    await tester.enterText(
      find.byKey(const Key('email-login-password-field')),
      '0000',
    );
    await tester.tap(find.widgetWithText(FilledButton, '로그인'));
    await tester.pumpAndSettle();

    expect(find.text('김민진'), findsOneWidget);
    expect(find.byKey(const Key('first-time-user-home')), findsOneWidget);
  });

  testWidgets('first-time account ignores previously stored account data', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'account_data_kim_minjin_v1': 'legacy data that must be ignored',
    });
    await tester.binding.setSurfaceSize(const Size(402, 874));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _testApp(
        user: _firstTimeUser,
        productSearchGateway: _FakeProductSearchGateway(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('김민진'), findsOneWidget);
    expect(find.byKey(const Key('first-time-user-home')), findsOneWidget);
    expect(find.text('소비 데이터 연결 완료'), findsNothing);
    expect(find.byKey(const Key('account-profile-menu')), findsNothing);
    await tester.tap(find.byKey(const Key('nav-spending')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('first-time-spending-empty')), findsOneWidget);
    expect(find.byKey(const Key('category-pie-card')), findsNothing);
  });

  testWidgets('connected first-time home hides the onboarding guide', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(402, 874));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: ThemeScope(
          palette: AppPalette.fromChoice(ThemeChoice.green),
          child: Scaffold(
            body: HomeScreen(
              currentUser: _firstTimeUser,
              goal: initialGoal,
              unreadCount: 0,
              transactions: [
                MoneyTransaction(
                  id: 'connected-1',
                  merchant: '테스트 상점',
                  category: '쇼핑',
                  amount: 10000,
                  date: DateTime(2026, 8, 27),
                ),
              ],
              onOpenNotifications: () {},
              onPeriodChanged: (_) {},
              onAmountChanged: (_) {},
              onSaveWithToss: () {},
              onOpenSpending: () {},
              onOpenShop: (_) {},
              onBuy: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('first-time-onboarding-card')), findsNothing);
    expect(find.byKey(const Key('save-with-toss-button')), findsOneWidget);
  });

  testWidgets('saving action wraps as a whole and stays left aligned', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(402, 874));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _testApp(productSearchGateway: _FakeProductSearchGateway()),
    );
    await tester.pumpAndSettle();

    final amountField = find.byKey(const Key('saving-amount-field'));
    final savingSentence = find.byKey(const Key('saving-sentence-wrap'));
    final savingPeriod = find.byKey(const Key('saving-period-menu'));
    final wonText = find.text('원을');
    final savingAction = find.descendant(
      of: savingSentence,
      matching: find.text('저축하기'),
    );
    expect(
      find.ancestor(of: savingAction, matching: find.byType(InkWell)),
      findsNothing,
    );
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
    await tester.pumpWidget(_testApp());

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

    await tester.pumpWidget(_testApp());
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

    await tester.pumpWidget(_testApp());
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
      _testApp(productSearchGateway: _FakeProductSearchGateway()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('nav-settings')));
    await tester.pumpAndSettle();

    expect(find.text('설정'), findsWidgets);
    expect(find.text('테마'), findsNothing);
    // If AnimatedSwitcher centered the short settings page, this title
    // would sit around the middle of the 874-tall surface.
    expect(tester.getTopLeft(find.text('설정').first).dy, lessThan(48));
  });

  testWidgets('account deletion requires the current user name', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(402, 874));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final auth = _FakeAuthGateway(user: _firstTimeUser);

    await tester.pumpWidget(
      _testApp(
        authGateway: auth,
        productSearchGateway: _FakeProductSearchGateway(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete-account-button')));
    await tester.pumpAndSettle();

    final confirm = find.byKey(const Key('confirm-delete-account-button'));
    expect(find.byKey(const Key('delete-account-dialog')), findsOneWidget);
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

    await tester.enterText(
      find.byKey(const Key('delete-account-name-field')),
      '김민진',
    );
    await tester.pump();
    expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(auth.user, isNull);
    expect(find.byKey(const Key('auth-login-entry')), findsOneWidget);
  });

  testWidgets('spending summary keeps only the compact data card', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(402, 874));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_testApp());
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
