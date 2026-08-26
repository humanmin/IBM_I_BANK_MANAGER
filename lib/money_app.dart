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
import 'home_screen.dart';
import 'models.dart';
import 'report_screens.dart';
import 'seed_data.dart';
import 'product_search_service.dart';

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

ThemeData _buildAppTheme(AppPalette palette) {
  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: palette.accent,
        brightness: Brightness.light,
      ).copyWith(
        primary: palette.accent,
        onPrimary: palette.text,
        secondary: palette.accentSoft,
        onSecondary: palette.text,
        surface: Colors.white,
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
    textTheme: ThemeData.light().textTheme.apply(
      bodyColor: palette.text,
      displayColor: palette.text,
      fontFamily: 'sans-serif',
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: const Color(0xFFF6F8F6),
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
      backgroundColor: Colors.white,
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
      backgroundColor: Colors.white,
      modalBackgroundColor: Colors.white,
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
      color: Colors.white,
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
  const MoneyApp({this.productSearchGateway, super.key});

  final ProductSearchGateway? productSearchGateway;

  @override
  State<MoneyApp> createState() => _MoneyAppState();
}

class _MoneyAppState extends State<MoneyApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  AppTab _activeTab = AppTab.home;
  SavingsGoal _goal = initialGoal;
  ThemeChoice _themeChoice = ThemeChoice.green;
  int _unreadCount = demoNotifications.length;
  String? _spendingFilter;
  final List<FixedExpense> _fixedExpenses = [];
  final List<WishItem> _wishItems = [];
  final AccountDataService _accountDataService = AccountDataService();
  AccountData _accountData = AccountData(
    balance: remainingBalance,
    transactions: List.unmodifiable(transactions),
    isDemo: true,
  );
  bool _notificationAccessGranted = false;
  late final ProductSearchGateway _productSearchGateway;
  late final bool _ownsProductSearchGateway;
  late final AuthGateway _authGateway;
  late final EventGateway _eventGateway;
  AppUser? _currentUser;
  StreamSubscription<AppUser?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ownsProductSearchGateway = widget.productSearchGateway == null;
    _productSearchGateway =
        widget.productSearchGateway ?? ProductSearchService();
    _authGateway = FirebaseAuthService();
    _eventGateway = EventService(auth: _authGateway);
    _currentUser = _authGateway.currentUser;
    _authSubscription = _authGateway.authStateChanges().listen((user) {
      if (!mounted) return;
      setState(() => _currentUser = user);
    });
    _loadAccountData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    if (_ownsProductSearchGateway &&
        _productSearchGateway is ProductSearchService) {
      _productSearchGateway.close();
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

  Future<void> _loadAccountData() async {
    final saved = await _accountDataService.loadSaved();
    final access = await _accountDataService.isNotificationAccessGranted();
    if (!mounted) return;
    setState(() {
      if (saved != null) _accountData = saved;
      _notificationAccessGranted = access;
    });
    if (access) await _syncTossNotifications(silent: true);
  }

  Future<void> _refreshNotificationAccess({
    bool syncWhenGranted = false,
  }) async {
    final granted = await _accountDataService.isNotificationAccessGranted();
    if (!mounted) return;
    setState(() => _notificationAccessGranted = granted);
    if (granted && syncWhenGranted) {
      await _syncTossNotifications(silent: true);
    }
  }

  Future<AccountActionResult> _importAccountData() async {
    try {
      final result = await _accountDataService.importDocument(
        _accountData,
        requestPassword: _requestExcelPassword,
      );
      if (result == null) {
        return const AccountActionResult(
          succeeded: false,
          message: '파일 가져오기를 취소했어요.',
        );
      }
      if (mounted) setState(() => _accountData = result.data);
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
    try {
      final result = await _accountDataService.syncNotifications(_accountData);
      if (mounted && !identical(result.data, _accountData)) {
        setState(() => _accountData = result.data);
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
      await _accountDataService.openNotificationAccessSettings();
      return const AccountActionResult(
        succeeded: true,
        message: '설정에서 아이뱅크매니저의 알림 접근을 허용해 주세요.',
      );
    } on AccountImportException catch (error) {
      return AccountActionResult(succeeded: false, message: error.message);
    }
  }

  AppPalette get _palette => AppPalette.fromChoice(_themeChoice);

  void _changeTab(AppTab tab) {
    setState(() {
      _activeTab = tab;
      if (tab == AppTab.spending) _spendingFilter = null;
    });
  }

  void _openNotifications() {
    setState(() {
      _unreadCount = 0;
      _activeTab = AppTab.notifications;
    });
  }

  Future<void> _openAccount() async {
    final user = _currentUser;
    if (user == null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LoginScreen(authGateway: _authGateway),
        ),
      );
      return;
    }

    final signOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('계정'),
        content: Text(user.email ?? user.uid),
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

  void _openSpending([String? category]) {
    setState(() {
      _spendingFilter = category;
      _activeTab = AppTab.spending;
    });
  }

  void _changePeriod(SavingPeriod period) {
    setState(() => _goal = _goal.copyWith(savingPeriod: period));
  }

  void _changeSavingAmount(int amount) {
    setState(() => _goal = _goal.copyWith(savingAmount: amount));
  }

  void _addFixedExpense(FixedExpense expense) {
    setState(() => _fixedExpenses.add(expense));
  }

  void _updateFixedExpense(FixedExpense expense) {
    setState(() {
      final index = _fixedExpenses.indexWhere((item) => item.id == expense.id);
      if (index != -1) _fixedExpenses[index] = expense;
    });
  }

  void _deleteFixedExpense(FixedExpense expense) {
    setState(() => _fixedExpenses.removeWhere((item) => item.id == expense.id));
  }

  void _selectWishItem(WishItem item) {
    setState(() {
      _goal = _goal.copyWith(
        name: item.name,
        price: item.price,
        imageUrl: item.imageUrl,
        clearImage: true,
      );
      _activeTab = AppTab.home;
    });
  }

  void _addWishItem(WishItem item) {
    setState(() {
      _wishItems.add(item);
      _goal = _goal.copyWith(
        name: item.name,
        price: item.price,
        imageUrl: item.imageUrl,
        clearImage: true,
      );
      _activeTab = AppTab.home;
    });
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
  }

  void _deleteWishItem(WishItem item) {
    setState(() => _wishItems.removeWhere((entry) => entry.id == item.id));
  }

  void _finishPayment(AppTab destination) {
    final leftover = _goal.saved > _goal.price ? _goal.saved - _goal.price : 0;
    setState(() {
      _goal = _goal.copyWith(saved: leftover);
      _activeTab = destination;
    });
  }

  Widget _screen() {
    return switch (_activeTab) {
      AppTab.home => HomeScreen(
        goal: _goal,
        themeChoice: _themeChoice,
        unreadCount: _unreadCount,
        accountBalance: _accountData.balance,
        transactions: _accountData.transactions,
        isDemoData: _accountData.isDemo,
        isLoggedIn: _currentUser != null,
        onThemeChanged: (choice) => setState(() => _themeChoice = choice),
        onOpenNotifications: _openNotifications,
        onOpenAccount: _openAccount,
        onPeriodChanged: _changePeriod,
        onAmountChanged: _changeSavingAmount,
        onOpenSpending: _openSpending,
        onBuy: () => setState(() => _activeTab = AppTab.payment),
      ),
      AppTab.notifications => NotificationsScreen(
        onBack: () => setState(() => _activeTab = AppTab.home),
      ),
      AppTab.habits => HabitsScreen(transactions: _accountData.transactions),
      AppTab.insights => InsightsScreen(
        goal: _goal,
        transactions: _accountData.transactions,
        onOpenCategory: _openSpending,
        onSeeGoal: () => setState(() => _activeTab = AppTab.home),
      ),
      AppTab.spending => SpendingScreen(
        key: ValueKey(_spendingFilter ?? 'all'),
        initialCategory: _spendingFilter,
        transactions: _accountData.transactions,
        isDemoData: _accountData.isDemo,
        lastUpdated: _accountData.lastUpdated,
        notificationAccessGranted: _notificationAccessGranted,
        onImportAccountData: _importAccountData,
        onSyncNotifications: _syncTossNotifications,
        onOpenNotificationSettings: _openNotificationSettings,
        fixedExpenses: _fixedExpenses,
        onAddFixedExpense: _addFixedExpense,
        onUpdateFixedExpense: _updateFixedExpense,
        onDeleteFixedExpense: _deleteFixedExpense,
      ),
      AppTab.shop => ShoppingScreen(
        goal: _goal,
        wishItems: _wishItems,
        productSearchGateway: _productSearchGateway,
        onPeriodChanged: _changePeriod,
        onAmountChanged: _changeSavingAmount,
        onAddWishItem: _addWishItem,
        onUpdateWishItem: _updateWishItem,
        onDeleteWishItem: _deleteWishItem,
        onSelectWishItem: _selectWishItem,
      ),
      AppTab.event => EventScreen(eventGateway: _eventGateway),
      AppTab.payment => PaymentScreen(
        goal: _goal,
        onCancel: () => setState(() => _activeTab = AppTab.home),
        onFinishHome: () => _finishPayment(AppTab.home),
        onPickNextGoal: () => _finishPayment(AppTab.shop),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final palette = _palette;
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: '아이뱅크매니저',
      scrollBehavior: const AppScrollBehavior(),
      theme: _buildAppTheme(palette),
      home: ThemeScope(
        palette: palette,
        child: PopScope(
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
                  color: Colors.white,
                  child: Column(
                    children: [
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: KeyedSubtree(
                            key: ValueKey(_activeTab),
                            child: _screen(),
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
