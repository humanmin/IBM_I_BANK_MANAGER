import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'account_data_service.dart';
import 'app_widgets.dart';
import 'auth_screens.dart';
import 'auth_service.dart';
import 'commerce_screens.dart';
import 'event_screens.dart';
import 'event_service.dart';
import 'bank_deeplink.dart';
import 'home_goal_widget_service.dart';
import 'home_screen.dart';
import 'models.dart';
import 'report_screens.dart';
import 'seed_data.dart';
import 'settings_screen.dart';
import 'product_search_service.dart';
import 'spending_insight_service.dart';
import 'user_data_service.dart';

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

ThemeData _buildAppTheme(AppPalette palette, {required bool isDark}) {
  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: palette.accent,
        brightness: isDark ? Brightness.dark : Brightness.light,
      ).copyWith(
        primary: palette.accent,
        onPrimary: palette.text,
        secondary: palette.accentSoft,
        onSecondary: palette.text,
        surface: palette.surface,
        onSurface: palette.text,
        outline: palette.accentBorder,
        outlineVariant: dividerColor,
      );
  final fieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: BorderSide(color: palette.accentBorder),
  );
  final focusedFieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: BorderSide(color: palette.textSoft, width: 1.6),
  );
  const errorColor = Color(0xFFB94747);

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: palette.pageBackground,
    textTheme: (isDark ? ThemeData.dark() : ThemeData.light()).textTheme.apply(
      bodyColor: palette.text,
      displayColor: palette.text,
      fontFamily: 'sans-serif',
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: isDark ? palette.accentSoft : const Color(0xFFF6F8F6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      labelStyle: TextStyle(
        color: palette.textSoft,
        fontWeight: FontWeight.w700,
      ),
      floatingLabelStyle: TextStyle(
        color: palette.textSoft,
        fontWeight: FontWeight.w800,
      ),
      hintStyle: TextStyle(color: palette.textMuted, fontSize: 14),
      prefixIconColor: palette.textMuted,
      suffixIconColor: palette.textSoft,
      suffixStyle: TextStyle(
        color: palette.textSoft,
        fontWeight: FontWeight.w700,
      ),
      border: fieldBorder,
      enabledBorder: fieldBorder,
      focusedBorder: focusedFieldBorder,
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: errorColor, width: 1.6),
      ),
      errorStyle: const TextStyle(
        color: errorColor,
        fontWeight: FontWeight.w700,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 18,
      shadowColor: const Color(0x330F2217),
      barrierColor: const Color(0x99101D14),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: palette.accentBorder),
      ),
      titleTextStyle: TextStyle(
        color: palette.text,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
      ),
      contentTextStyle: TextStyle(
        color: palette.textSoft,
        fontSize: 14,
        height: 1.5,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palette.surface,
      modalBackgroundColor: palette.surface,
      surfaceTintColor: Colors.transparent,
      modalBarrierColor: const Color(0x99101D14),
      modalElevation: 18,
      shadowColor: const Color(0x330F2217),
      showDragHandle: true,
      dragHandleColor: palette.accentBorder,
      dragHandleSize: const Size(42, 4),
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: palette.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      shadowColor: const Color(0x2E0F2217),
      position: PopupMenuPosition.under,
      menuPadding: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: palette.accentBorder),
      ),
      textStyle: TextStyle(color: palette.text, fontSize: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: palette.accent,
        foregroundColor: palette.text,
        minimumSize: const Size(44, 50),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: palette.textSoft,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: palette.textSoft,
      selectionColor: palette.accent.withValues(alpha: 0.45),
      selectionHandleColor: palette.textSoft,
    ),
    splashFactory: InkRipple.splashFactory,
  );
}

class MoneyApp extends StatefulWidget {
  const MoneyApp({
    this.productSearchGateway,
    this.spendingInsightGateway,
    this.authGateway,
    this.goalWidgetGateway,
    super.key,
  });

  final ProductSearchGateway? productSearchGateway;
  final SpendingInsightGateway? spendingInsightGateway;
  final AuthGateway? authGateway;
  final GoalWidgetGateway? goalWidgetGateway;

  @override
  State<MoneyApp> createState() => _MoneyAppState();
}

class _MoneyAppState extends State<MoneyApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  AppTab _activeTab = AppTab.home;
  SavingsGoal _goal = initialGoal;
  bool _firstTimeHasSelectedGoal = false;
  final bool _isDarkMode = false;
  int _unreadCount = demoNotifications.length;
  String? _historyFilter;
  final List<FixedExpense> _fixedExpenses = [];
  final List<WishItem> _wishItems = [];
  final AccountDataService _legacyAccountDataService = AccountDataService();
  AccountDataService? _userAccountDataService;
  UserDataService? _userDataService;
  Future<void> _userDataSaveQueue = Future<void>.value();
  Future<void> _goalWidgetSyncQueue = Future<void>.value();
  AccountData _accountData = AccountData(
    balance: remainingBalance,
    transactions: List.unmodifiable(transactions),
    isDemo: true,
  );
  bool _notificationAccessGranted = false;
  late final ProductSearchGateway _productSearchGateway;
  late final bool _ownsProductSearchGateway;
  late final SpendingInsightGateway _spendingInsightGateway;
  late final bool _ownsSpendingInsightGateway;
  late final AuthGateway _authGateway;
  late final GoalWidgetGateway _goalWidgetGateway;
  late final EventGateway _eventGateway;
  AppUser? _currentUser;
  StreamSubscription<AppUser?>? _authSubscription;
  bool _authReady = false;
  String? _insightFingerprint;
  List<Insight>? _remoteInsights;
  bool _insightsLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ownsProductSearchGateway = widget.productSearchGateway == null;
    _productSearchGateway =
        widget.productSearchGateway ?? ProductSearchService();
    _ownsSpendingInsightGateway = widget.spendingInsightGateway == null;
    _spendingInsightGateway =
        widget.spendingInsightGateway ?? SpendingInsightService();
    _authGateway = widget.authGateway ?? FirebaseAuthService();
    _goalWidgetGateway = widget.goalWidgetGateway ?? HomeGoalWidgetService();
    _eventGateway = EventService(auth: _authGateway);
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    if (_ownsProductSearchGateway &&
        _productSearchGateway is ProductSearchService) {
      _productSearchGateway.close();
    }
    if (_ownsSpendingInsightGateway &&
        _spendingInsightGateway is SpendingInsightService) {
      _spendingInsightGateway.close();
    }
    if (_eventGateway is EventService) {
      _eventGateway.close();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshNotificationAccess(syncWhenGranted: true);
    }
  }

  Future<void> _initializeApp() async {
    final restoredUser = await _authGateway.restoreSession();
    if (restoredUser != null) {
      await _restoreUserData(restoredUser);
    } else {
      await _queueGoalWidgetClear();
    }
    if (!mounted) return;
    setState(() {
      _currentUser = restoredUser;
      _authReady = true;
    });
    _authSubscription = _authGateway.authStateChanges().listen((user) {
      unawaited(_applyAuthenticatedUser(user));
    });

    final access = await _legacyAccountDataService
        .isNotificationAccessGranted();
    if (!mounted) return;
    setState(() => _notificationAccessGranted = access);
    if (access && restoredUser != null && !restoredUser.isFirstTime) {
      await _syncTossNotifications(silent: true);
    }
  }

  Future<void> _applyAuthenticatedUser(AppUser? user) async {
    if (!mounted) return;
    final changedAccount = _currentUser?.uid != user?.uid;
    if (user != null && changedAccount) {
      await _restoreUserData(user);
      if (!mounted) return;
    } else if (user == null) {
      await _queueGoalWidgetClear();
    }
    setState(() {
      _currentUser = user;
      _authReady = true;
      _activeTab = AppTab.home;
      _historyFilter = null;
    });
  }

  Future<void> _restoreUserData(AppUser user) async {
    final accountService = AccountDataService(
      storageKey: 'account_data_v2_${UserDataService.keyForUser(user.uid)}',
    );
    final userDataService = UserDataService(userId: user.uid);
    var accountData = await accountService.loadSaved();

    // 기존 버전의 단일 계정 저장값은 현재 로그인한 계정으로 한 번만 옮깁니다.
    if (accountData == null) {
      final legacyData = await _legacyAccountDataService.loadSaved();
      if (legacyData != null) {
        accountData = legacyData;
        await accountService.save(legacyData);
        await _legacyAccountDataService.clearSaved();
      }
    }

    final storedUserData = await userDataService.load();
    _userAccountDataService = accountService;
    _userDataService = userDataService;
    _accountData = accountData ?? _defaultAccountDataFor(user);
    _goal = storedUserData?.goal ?? initialGoal;
    _firstTimeHasSelectedGoal =
        storedUserData?.hasSelectedGoal ?? !user.isFirstTime;
    _wishItems
      ..clear()
      ..addAll(storedUserData?.wishItems ?? const []);
    _fixedExpenses
      ..clear()
      ..addAll(storedUserData?.fixedExpenses ?? const []);
    _insightFingerprint = null;
    _remoteInsights = null;
    unawaited(
      _queueGoalWidgetSync(
        goal: _goal,
        hasSelectedGoal: _firstTimeHasSelectedGoal,
      ),
    );
  }

  AccountData _defaultAccountDataFor(AppUser user) {
    if (user.isFirstTime) {
      return const AccountData(balance: 0, transactions: [], isDemo: false);
    }
    return AccountData(
      balance: remainingBalance,
      transactions: List.unmodifiable(transactions),
      isDemo: true,
    );
  }

  void _resetFirstTimeSession() {
    _accountData = const AccountData(
      balance: 0,
      transactions: [],
      isDemo: false,
    );
    _goal = initialGoal;
    _firstTimeHasSelectedGoal = false;
    _fixedExpenses.clear();
    _wishItems.clear();
    _insightFingerprint = null;
    _remoteInsights = null;
  }

  Future<void> _refreshNotificationAccess({
    bool syncWhenGranted = false,
  }) async {
    final granted = await _legacyAccountDataService
        .isNotificationAccessGranted();
    if (!mounted) return;
    setState(() => _notificationAccessGranted = granted);
    if (granted && syncWhenGranted && !_isFirstTimeUser) {
      await _syncTossNotifications(silent: true);
    }
  }

  Future<AccountActionResult> _importAccountData() async {
    final firstTimeUser = _isFirstTimeUser;
    final service = _accountDataServiceFor(firstTimeUser);
    final currentData = _accountDataFor(firstTimeUser);
    try {
      final result = await service.importDocument(
        currentData,
        requestPassword: _requestExcelPassword,
      );
      if (result == null) {
        return const AccountActionResult(
          succeeded: false,
          message: '파일 가져오기를 취소했어요.',
        );
      }
      if (mounted) {
        setState(() => _setAccountDataFor(firstTimeUser, result.data));
        _refreshSpendingInsights();
      }
      final skippedText = result.skipped == 0
          ? ''
          : ' · 읽지 못한 행 ${result.skipped}개';
      return AccountActionResult(
        succeeded: true,
        message: '지출 ${result.imported}건을 반영했어요$skippedText',
      );
    } on AccountImportException catch (error) {
      return AccountActionResult(succeeded: false, message: error.message);
    } catch (error, stackTrace) {
      debugPrint('Account import failed (${error.runtimeType}).\n$stackTrace');
      return const AccountActionResult(
        succeeded: false,
        message: '거래내역을 가져오지 못했어요. 파일 형식을 확인해 주세요.',
      );
    }
  }

  Future<String?> _requestExcelPassword(String? errorMessage) async {
    final navigatorContext = _navigatorKey.currentContext;
    if (!mounted || navigatorContext == null) return null;
    var enteredPassword = '';
    var obscurePassword = true;
    var validationMessage = errorMessage;
    final palette = _palette;
    final password = await showDialog<String>(
      context: navigatorContext,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          void submit() {
            final value = enteredPassword.trim();
            if (value.isEmpty) {
              setDialogState(() => validationMessage = '비밀번호를 입력해 주세요.');
              return;
            }
            Navigator.of(dialogContext).pop(value);
          }

          return AlertDialog(
            icon: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: palette.accentSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.lock_outline_rounded, color: palette.text),
            ),
            title: const Text('엑셀 비밀번호'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '토스뱅크에서 받은 거래내역 파일의 '
                  '비밀번호를 입력해 주세요.',
                  style: TextStyle(
                    color: palette.textSoft,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  autofocus: true,
                  obscureText: obscurePassword,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onChanged: (value) => enteredPassword = value,
                  onSubmitted: (_) => submit(),
                  decoration: InputDecoration(
                    labelText: '비밀번호',
                    hintText: '파일 비밀번호 입력',
                    errorText: validationMessage,
                    prefixIcon: const Icon(Icons.password_rounded),
                    suffixIcon: IconButton(
                      tooltip: obscurePassword ? '비밀번호 보기' : '비밀번호 숨기기',
                      onPressed: () => setDialogState(
                        () => obscurePassword = !obscurePassword,
                      ),
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 16,
                      color: palette.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '비밀번호는 파일을 여는 동안만 사용하고 '
                        '휴대폰에 저장하지 않아요.',
                        style: TextStyle(
                          color: palette.textMuted,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('취소'),
              ),
              FilledButton(onPressed: submit, child: const Text('열기')),
            ],
          );
        },
      ),
    );
    return password;
  }

  Future<AccountActionResult> _syncTossNotifications({
    bool silent = false,
  }) async {
    final firstTimeUser = _isFirstTimeUser;
    final service = _accountDataServiceFor(firstTimeUser);
    final currentData = _accountDataFor(firstTimeUser);
    try {
      final result = await service.syncNotifications(currentData);
      if (mounted && !identical(result.data, currentData)) {
        setState(() => _setAccountDataFor(firstTimeUser, result.data));
        _refreshSpendingInsights();
      }
      return AccountActionResult(
        succeeded: true,
        message: result.added == 0
            ? '새로 반영할 토스 지출 알림이 없어요.'
            : '새 지출 알림 ${result.added}건을 반영했어요.',
      );
    } catch (_) {
      return AccountActionResult(
        succeeded: false,
        message: silent ? '' : '토스 알림을 불러오지 못했어요.',
      );
    }
  }

  Future<AccountActionResult> _openNotificationSettings() async {
    try {
      await _legacyAccountDataService.openNotificationAccessSettings();
      return const AccountActionResult(
        succeeded: true,
        message: '설정에서 아이뱅크매니저의 알림 접근을 허용해 주세요.',
      );
    } on AccountImportException catch (error) {
      return AccountActionResult(succeeded: false, message: error.message);
    }
  }

  AppPalette get _palette =>
      AppPalette.fromChoice(ThemeChoice.green, isDark: _isDarkMode);

  bool get _isFirstTimeUser => _currentUser?.isFirstTime ?? true;

  AccountDataService _accountDataServiceFor(bool firstTimeUser) =>
      _userAccountDataService ?? _legacyAccountDataService;

  AccountData _accountDataFor(bool firstTimeUser) => _accountData;

  AccountData get _activeAccountData => _accountDataFor(_isFirstTimeUser);

  void _setAccountDataFor(bool firstTimeUser, AccountData data) {
    _accountData = data;
  }

  void _persistUserData() {
    final service = _userDataService;
    if (service == null) return;
    final goal = _goal;
    final hasSelectedGoal = _firstTimeHasSelectedGoal;
    final wishItems = List<WishItem>.of(_wishItems);
    final fixedExpenses = List<FixedExpense>.of(_fixedExpenses);
    _userDataSaveQueue = _userDataSaveQueue.then((_) async {
      await service.save(
        goal: goal,
        hasSelectedGoal: hasSelectedGoal,
        wishItems: wishItems,
        fixedExpenses: fixedExpenses,
      );
    });
    unawaited(
      _queueGoalWidgetSync(goal: goal, hasSelectedGoal: hasSelectedGoal),
    );
  }

  Future<void> _queueGoalWidgetSync({
    required SavingsGoal goal,
    required bool hasSelectedGoal,
  }) {
    _goalWidgetSyncQueue = _goalWidgetSyncQueue.then(
      (_) => _goalWidgetGateway.syncGoal(
        goal: goal,
        hasSelectedGoal: hasSelectedGoal,
      ),
    );
    return _goalWidgetSyncQueue;
  }

  Future<void> _queueGoalWidgetClear() {
    _goalWidgetSyncQueue = _goalWidgetSyncQueue.then(
      (_) => _goalWidgetGateway.clear(),
    );
    return _goalWidgetSyncQueue;
  }

  void _changeTab(AppTab tab) {
    setState(() {
      _activeTab = tab;
      if (tab == AppTab.history) _historyFilter = null;
    });
    _refreshSpendingInsights();
  }

  void _openNotifications() {
    setState(() {
      _unreadCount = 0;
      _activeTab = AppTab.notifications;
    });
  }

  Future<void> _openAccount() async {
    final navigatorContext = _navigatorKey.currentContext;
    if (!mounted || navigatorContext == null) return;

    final user = _currentUser;
    if (user == null) return;

    final signOut = await showDialog<bool>(
      context: navigatorContext,
      builder: (context) => AlertDialog(
        title: const Text('계정'),
        content: Text(
          [user.displayName, user.email].whereType<String>().join('\n'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('닫기'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
    if (signOut == true) {
      await _authGateway.signOut();
    }
  }

  void _openSpending() {
    _changeTab(AppTab.spending);
  }

  /// Ask watsonx for 통계 feedback only when the policy says so.
  /// Local `insightsFor` cards stay on screen until a real response arrives.
  Future<void> _refreshSpendingInsights() async {
    final accountData = _activeAccountData;
    final request = buildSpendingInsightRequest(
      transactions: accountData.transactions,
      goal: _goal,
      isDemo: accountData.isDemo,
      lastUpdated: accountData.lastUpdated,
    );
    if (!shouldRequestSpendingInsights(
      isDemoData: accountData.isDemo,
      isSpendingTabVisible: _activeTab == AppTab.spending,
      fingerprint: request.fingerprint,
      lastRequestedFingerprint: _insightFingerprint,
    )) {
      return;
    }

    _insightFingerprint = request.fingerprint;
    setState(() => _insightsLoading = true);

    try {
      final insights = await _spendingInsightGateway.fetch(request);
      if (!mounted) return;
      if (_insightFingerprint != request.fingerprint) return;
      setState(() {
        _remoteInsights = insights.isEmpty ? null : insights;
        _insightsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      if (_insightFingerprint != request.fingerprint) return;
      setState(() => _insightsLoading = false);
    }
  }

  void _openHistory([String? category]) {
    setState(() {
      _historyFilter = category;
      _activeTab = AppTab.history;
    });
  }

  void _changePeriod(SavingPeriod period) {
    setState(() => _goal = _goal.copyWith(savingPeriod: period));
    _persistUserData();
  }

  void _changeSavingAmount(int amount) {
    setState(() => _goal = _goal.copyWith(savingAmount: amount));
    _persistUserData();
  }

  Future<void> _openTossForSaving() async {
    final result = await openTossForSaving();
    if (!mounted || result == DeepLinkResult.opened) return;
    final context = _navigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('토스 앱을 열 수 없어요. 토스가 설치되어 있는지 확인해 주세요.')),
    );
  }

  Future<void> _deleteCurrentAccount() async {
    final accountService = _userAccountDataService;
    final userDataService = _userDataService;
    await _authGateway.deleteAccount();
    await accountService?.clearSaved();
    await userDataService?.clear();
    await _queueGoalWidgetClear();
    if (!mounted) return;
    setState(() {
      _resetFirstTimeSession();
      _userAccountDataService = null;
      _userDataService = null;
    });
  }

  void _addFixedExpense(FixedExpense expense) {
    setState(() => _fixedExpenses.add(expense));
    _persistUserData();
  }

  void _updateFixedExpense(FixedExpense expense) {
    setState(() {
      final index = _fixedExpenses.indexWhere((item) => item.id == expense.id);
      if (index != -1) _fixedExpenses[index] = expense;
    });
    _persistUserData();
  }

  void _deleteFixedExpense(FixedExpense expense) {
    setState(() => _fixedExpenses.removeWhere((item) => item.id == expense.id));
    _persistUserData();
  }

  void _applyWishItemToGoal(WishItem item) {
    final isFirstGoal = _isFirstTimeUser && !_firstTimeHasSelectedGoal;
    _goal = _goal.copyWith(
      name: item.name,
      price: item.price,
      imageUrl: item.imageUrl,
      clearImage: true,
      saved: isFirstGoal ? 0 : null,
    );
    if (_isFirstTimeUser) {
      _firstTimeHasSelectedGoal = true;
    }
  }

  void _selectWishItem(WishItem item) {
    setState(() => _applyWishItemToGoal(item));
    _persistUserData();
  }

  void _addWishItem(WishItem item) {
    setState(() {
      _wishItems.add(item);
      _applyWishItemToGoal(item);
    });
    _persistUserData();
  }

  void _updateWishItem(WishItem item) {
    setState(() {
      final index = _wishItems.indexWhere((entry) => entry.id == item.id);
      if (index == -1) return;
      final previous = _wishItems[index];
      _wishItems[index] = item;
      if (_goal.imageAsset == null &&
          _goal.name == previous.name &&
          _goal.imageUrl == previous.imageUrl) {
        _goal = _goal.copyWith(
          name: item.name,
          price: item.price,
          imageUrl: item.imageUrl,
        );
      }
    });
    _persistUserData();
  }

  void _deleteWishItem(WishItem item) {
    setState(() => _wishItems.removeWhere((entry) => entry.id == item.id));
    _persistUserData();
  }

  void _finishPayment(AppTab destination) {
    final leftover = _goal.saved > _goal.price ? _goal.saved - _goal.price : 0;
    setState(() {
      _goal = _goal.copyWith(saved: leftover);
      _activeTab = destination;
    });
    _persistUserData();
  }

  Future<void> _openWishlistSheet([BuildContext? hostContext]) async {
    final context = hostContext ?? _navigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    final palette = ThemeScope.paletteOf(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      enableDrag: true,
      backgroundColor: palette.surface,
      barrierColor: const Color(0x99101D14),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (sheetContext) {
        return ThemeScope(
          palette: palette,
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              void refreshSheet() => setSheetState(() {});
              return ShoppingScreen(
                goal: _goal,
                wishItems: _wishItems,
                showEmptyState: _isFirstTimeUser && !_firstTimeHasSelectedGoal,
                productSearchGateway: _productSearchGateway,
                onPeriodChanged: (period) {
                  _changePeriod(period);
                  refreshSheet();
                },
                onAmountChanged: (amount) {
                  _changeSavingAmount(amount);
                  refreshSheet();
                },
                onAddWishItem: (item) {
                  _addWishItem(item);
                  refreshSheet();
                },
                onUpdateWishItem: (item) {
                  _updateWishItem(item);
                  refreshSheet();
                },
                onDeleteWishItem: (item) {
                  _deleteWishItem(item);
                  refreshSheet();
                },
                onSelectWishItem: _selectWishItem,
              );
            },
          ),
        );
      },
    );
  }

  Widget _screen() {
    final activeAccountData = _activeAccountData;
    final currentUser = _currentUser!;
    return switch (_activeTab) {
      AppTab.home || AppTab.shop => HomeScreen(
        key: ValueKey(currentUser.uid),
        currentUser: currentUser,
        goal: _goal,
        unreadCount: _unreadCount,
        transactions: activeAccountData.transactions,
        onOpenNotifications: _openNotifications,
        onPeriodChanged: _changePeriod,
        onAmountChanged: _changeSavingAmount,
        onSaveWithToss: _openTossForSaving,
        onOpenSpending: _openSpending,
        onOpenShop: (context) => _openWishlistSheet(context),
        onBuy: () => setState(() => _activeTab = AppTab.payment),
        hasSelectedGoal: _firstTimeHasSelectedGoal,
      ),
      AppTab.settings => SettingsScreen(
        currentUser: _currentUser,
        onOpenAccount: _openAccount,
        onDeleteAccount: _deleteCurrentAccount,
      ),
      AppTab.notifications => NotificationsScreen(
        onBack: () => setState(() => _activeTab = AppTab.home),
      ),
      AppTab.habits => HabitsScreen(
        transactions: activeAccountData.transactions,
      ),
      AppTab.spending => SpendingScreen(
        key: ValueKey(currentUser.uid),
        goal: _goal,
        transactions: activeAccountData.transactions,
        isDemoData: activeAccountData.isDemo,
        lastUpdated: activeAccountData.lastUpdated,
        notificationAccessGranted: _notificationAccessGranted,
        onImportAccountData: _importAccountData,
        onSyncNotifications: _syncTossNotifications,
        onOpenNotificationSettings: _openNotificationSettings,
        onSeeGoal: () => setState(() => _activeTab = AppTab.home),
        onOpenHistory: _openHistory,
        fixedExpenses: _fixedExpenses,
        onAddFixedExpense: _addFixedExpense,
        onUpdateFixedExpense: _updateFixedExpense,
        onDeleteFixedExpense: _deleteFixedExpense,
        remoteInsights: _remoteInsights,
        insightsLoading: _insightsLoading,
        showEmptyState:
            _isFirstTimeUser &&
            activeAccountData.transactions.isEmpty &&
            activeAccountData.lastUpdated == null,
      ),
      AppTab.history => RecentTransactionsScreen(
        key: ValueKey('${currentUser.uid}-${_historyFilter ?? 'all'}'),
        transactions: activeAccountData.transactions,
        initialCategory: _historyFilter,
      ),
      AppTab.event => EventScreen(eventGateway: _eventGateway),
      AppTab.payment => PaymentScreen(
        goal: _goal,
        onCancel: () => setState(() => _activeTab = AppTab.home),
        onFinishHome: () => _finishPayment(AppTab.home),
        onPickNextGoal: () {
          _finishPayment(AppTab.home);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _openWishlistSheet();
          });
        },
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final palette = _palette;
    return ThemeScope(
      palette: palette,
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        debugShowCheckedModeBanner: false,
        title: '아이뱅크매니저',
        scrollBehavior: const AppScrollBehavior(),
        theme: _buildAppTheme(palette, isDark: _isDarkMode),
        home: !_authReady
            ? Scaffold(
                backgroundColor: palette.pageBackground,
                body: Center(
                  child: CircularProgressIndicator(color: palette.accent),
                ),
              )
            : _currentUser == null
            ? AuthWelcomeScreen(authGateway: _authGateway)
            : PopScope(
                canPop: _activeTab == AppTab.home,
                onPopInvokedWithResult: (didPop, _) {
                  if (!didPop && _activeTab != AppTab.home) {
                    setState(() => _activeTab = AppTab.home);
                  }
                },
                child: Scaffold(
                  backgroundColor: palette.pageBackground,
                  body: SafeArea(
                    bottom: _activeTab == AppTab.payment,
                    child: Center(
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 430),
                        color: palette.surface,
                        child: Column(
                          children: [
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                // Default layoutBuilder uses a center-aligned Stack.
                                // Short tabs like Settings then float in the middle of
                                // the screen, which looks like a huge empty gap above
                                // the title. Pin every tab to the top instead.
                                layoutBuilder:
                                    (currentChild, previousChildren) {
                                      return Stack(
                                        alignment: Alignment.topCenter,
                                        fit: StackFit.expand,
                                        children: [
                                          ...previousChildren,
                                          ?currentChild,
                                        ],
                                      );
                                    },
                                child: KeyedSubtree(
                                  key: ValueKey(_activeTab),
                                  child: SizedBox.expand(child: _screen()),
                                ),
                              ),
                            ),
                            if (_activeTab != AppTab.payment)
                              AppBottomNav(
                                activeTab: _activeTab,
                                onChanged: _changeTab,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
