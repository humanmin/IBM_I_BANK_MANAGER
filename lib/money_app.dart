import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'account_data_service.dart';
import 'app_widgets.dart';
import 'auth_screens.dart';
import 'auth_service.dart';
import 'commerce_screens.dart';
import 'event_screens.dart';
import 'event_service.dart';
import 'bank_deeplink.dart';
import 'home_screen.dart';
import 'models.dart';
import 'report_screens.dart';
import 'seed_data.dart';
import 'settings_screen.dart';
import 'product_search_service.dart';
import 'spending_insight_service.dart';

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
    super.key,
  });

  final ProductSearchGateway? productSearchGateway;
  final SpendingInsightGateway? spendingInsightGateway;
  final AuthGateway? authGateway;

  @override
  State<MoneyApp> createState() => _MoneyAppState();
}

class _MoneyAppState extends State<MoneyApp> with WidgetsBindingObserver {
  static const _selectedProfileStorageKey = 'selected_home_user_profile_v1';
  static const _firstTimeAccountStorageKey = 'account_data_kim_minjin_v1';
  static const _displayNameStorageKey = 'signed_in_display_name_v1';

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  AppTab _activeTab = AppTab.home;
  HomeUserProfile _selectedProfile = HomeUserProfile.returningUser;
  SavingsGoal _goal = initialGoal;
  bool _firstTimeHasSelectedGoal = false;
  ThemeChoice _themeChoice = ThemeChoice.green;
  final bool _isDarkMode = false;
  int _unreadCount = demoNotifications.length;
  String? _historyFilter;
  final List<FixedExpense> _fixedExpenses = [];
  final List<WishItem> _wishItems = [];
  final AccountDataService _accountDataService = AccountDataService();
  final AccountDataService _firstTimeAccountDataService = AccountDataService(
    storageKey: _firstTimeAccountStorageKey,
  );
  AccountData _accountData = AccountData(
    balance: remainingBalance,
    transactions: List.unmodifiable(transactions),
    isDemo: true,
  );
  AccountData _firstTimeAccountData = const AccountData(
    balance: 0,
    transactions: [],
    isDemo: false,
  );
  bool _notificationAccessGranted = false;
  late final ProductSearchGateway _productSearchGateway;
  late final bool _ownsProductSearchGateway;
  late final SpendingInsightGateway _spendingInsightGateway;
  late final bool _ownsSpendingInsightGateway;
  // AI feedback state for the 통계 tab. Filled only when the user taps the
  // button; never pre-filled with local dummy cards.
  List<Insight>? _remoteInsights;
  bool _insightsLoading = false;
  String? _insightError;
  int _insightRequestId = 0;
  late final AuthGateway _authGateway;
  late final EventGateway _eventGateway;
  AppUser? _currentUser;
  String? _localDisplayName;
  StreamSubscription<AppUser?>? _authSubscription;

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
    _eventGateway = EventService(auth: _authGateway);
    _currentUser = _authGateway.currentUser;
    _authSubscription = _authGateway.authStateChanges().listen((user) {
      if (!mounted) return;
      setState(() {
        _currentUser = user;
        if (user == null) {
          _localDisplayName = null;
        } else {
          final authName = user.displayName?.trim();
          if (authName != null && authName.isNotEmpty) {
            _localDisplayName = authName;
          }
        }
      });
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

  Future<void> _loadAccountData() async {
    final saved = await _accountDataService.loadSaved();
    final firstTimeSaved = await _firstTimeAccountDataService.loadSaved();
    final preferences = await SharedPreferences.getInstance();
    final savedProfileName = preferences.getString(_selectedProfileStorageKey);
    if (!mounted) return;
    setState(() {
      if (saved != null) _accountData = saved;
      if (firstTimeSaved != null) _firstTimeAccountData = firstTimeSaved;
      _selectedProfile = HomeUserProfile.values.firstWhere(
        (profile) => profile.name == savedProfileName,
        orElse: () => HomeUserProfile.returningUser,
      );
      if (_currentUser != null) {
        _localDisplayName = preferences.getString(_displayNameStorageKey);
      }
    });

    final access = await _accountDataService.isNotificationAccessGranted();
    if (!mounted) return;
    setState(() {
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
    final profile = _selectedProfile;
    final service = _accountDataServiceFor(profile);
    final currentData = _accountDataFor(profile);
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
        setState(() => _setAccountDataFor(profile, result.data));
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
    final profile = _selectedProfile;
    final service = _accountDataServiceFor(profile);
    final currentData = _accountDataFor(profile);
    try {
      final result = await service.syncNotifications(currentData);
      if (mounted && !identical(result.data, currentData)) {
        setState(() => _setAccountDataFor(profile, result.data));
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

  AppPalette get _palette =>
      AppPalette.fromChoice(_themeChoice, isDark: _isDarkMode);

  AccountDataService _accountDataServiceFor(HomeUserProfile profile) =>
      profile.isFirstTime ? _firstTimeAccountDataService : _accountDataService;

  AccountData _accountDataFor(HomeUserProfile profile) =>
      profile.isFirstTime ? _firstTimeAccountData : _accountData;

  AccountData get _activeAccountData => _accountDataFor(_selectedProfile);

  void _setAccountDataFor(HomeUserProfile profile, AccountData data) {
    if (profile.isFirstTime) {
      _firstTimeAccountData = data;
    } else {
      _accountData = data;
    }
  }

  void _changeTab(AppTab tab) {
    setState(() {
      _activeTab = tab;
      if (tab == AppTab.history) _historyFilter = null;
    });
  }

  void _openNotifications() {
    setState(() {
      _unreadCount = 0;
      _activeTab = AppTab.notifications;
    });
  }

  /// Runs only when the user taps the AI button on the 통계 tab.
  /// Opening the tab never calls the model, so quota is spent on purpose.
  Future<void> _requestSpendingInsights() async {
    if (!shouldRequestSpendingInsights(isLoading: _insightsLoading)) return;

    final request = buildSpendingInsightRequest(
      transactions: _activeAccountData.transactions,
      goal: _goal,
    );
    // If the user switches profiles while we wait, this id no longer matches
    // and we throw the late response away instead of showing stale cards.
    final requestId = ++_insightRequestId;
    setState(() {
      _insightsLoading = true;
      _insightError = null;
    });

    try {
      final insights = await _spendingInsightGateway.fetch(request);
      if (!mounted || requestId != _insightRequestId) return;
      setState(() {
        _remoteInsights = insights;
        _insightsLoading = false;
      });
    } on SpendingInsightException catch (error) {
      if (!mounted || requestId != _insightRequestId) return;
      setState(() {
        _insightsLoading = false;
        _insightError = error.message;
      });
    } catch (_) {
      if (!mounted || requestId != _insightRequestId) return;
      setState(() {
        _insightsLoading = false;
        _insightError = 'AI 피드백을 받지 못했어요. 잠시 후 다시 시도해 주세요.';
      });
    }
  }

  Future<void> _changeProfile(HomeUserProfile profile) async {
    setState(() {
      _selectedProfile = profile;
      _historyFilter = null;
      _activeTab = AppTab.home;
      _remoteInsights = null;
      _insightsLoading = false;
      _insightError = null;
      _insightRequestId++;
    });
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_selectedProfileStorageKey, profile.name);
  }

  String? get _homePersonalName {
    if (_currentUser == null) return null;
    final authName = _currentUser!.displayName?.trim();
    if (authName != null && authName.isNotEmpty) return authName;
    final localName = _localDisplayName?.trim();
    if (localName != null && localName.isNotEmpty) return localName;
    return null;
  }

  Future<void> _openAccount() async {
    final navigatorContext = _navigatorKey.currentContext;
    if (!mounted || navigatorContext == null) return;

    final user = _currentUser;
    if (user == null) {
      final loggedIn = await Navigator.of(navigatorContext).push<bool>(
        MaterialPageRoute(
          builder: (_) => LoginScreen(authGateway: _authGateway),
        ),
      );
      if (!mounted) return;
      if (loggedIn == true || _currentUser != null) {
        await _promptDisplayNameIfNeeded();
      }
      return;
    }

    final signOut = await showDialog<bool>(
      context: navigatorContext,
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
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(_displayNameStorageKey);
      if (!mounted) return;
      setState(() => _localDisplayName = null);
    }
  }

  Future<void> _promptDisplayNameIfNeeded() async {
    final existing = _homePersonalName;
    if (existing != null) return;
    final context = _navigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    final palette = ThemeScope.paletteOf(context);
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: palette.surface,
      barrierColor: const Color(0x99101D14),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (sheetContext) {
        return ThemeScope(
          palette: palette,
          child: DisplayNameSheet(initialName: existing),
        );
      },
    );
    if (name == null || name.isEmpty || !mounted) return;
    await _saveDisplayName(name);
  }

  Future<void> _saveDisplayName(String name) async {
    try {
      await _authGateway.updateDisplayName(name);
    } on AuthException {
      // Firebase에 저장하지 못해도 홈 화면에는 이름을 바로 반영합니다.
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_displayNameStorageKey, name);
    if (!mounted) return;
    final user = _currentUser;
    setState(() {
      _localDisplayName = name;
      if (user != null) {
        _currentUser = AppUser(
          uid: user.uid,
          email: user.email,
          displayName: name,
        );
      }
    });
  }

  void _openSpending() {
    _changeTab(AppTab.spending);
  }

  void _openHistory([String? category]) {
    setState(() {
      _historyFilter = category;
      _activeTab = AppTab.history;
    });
  }

  void _changePeriod(SavingPeriod period) {
    setState(() => _goal = _goal.copyWith(savingPeriod: period));
  }

  void _changeSavingAmount(int amount) {
    setState(() => _goal = _goal.copyWith(savingAmount: amount));
  }

  Future<void> _saveWithBank([BuildContext? hostContext]) async {
    final context = hostContext ?? _navigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    final confirmed = await runSaveWithBankFlow(
      context: context,
      amount: _goal.savingAmount,
      goalName: _goal.name,
    );
    if (!confirmed || !mounted) return;
    setState(() {
      _goal = _goal.copyWith(saved: _goal.saved + _goal.savingAmount);
    });
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

  void _applyWishItemToGoal(WishItem item) {
    final isFirstGoal =
        _selectedProfile.isFirstTime && !_firstTimeHasSelectedGoal;
    _goal = _goal.copyWith(
      name: item.name,
      price: item.price,
      imageUrl: item.imageUrl,
      clearImage: true,
      saved: isFirstGoal ? 0 : null,
    );
    if (_selectedProfile.isFirstTime) {
      _firstTimeHasSelectedGoal = true;
    }
  }

  void _selectWishItem(WishItem item) {
    setState(() => _applyWishItemToGoal(item));
  }

  void _addWishItem(WishItem item) {
    setState(() {
      _wishItems.add(item);
      _applyWishItemToGoal(item);
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
                showEmptyState:
                    _selectedProfile.isFirstTime && !_firstTimeHasSelectedGoal,
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
                onSavePressed: () => _saveWithBank(context),
              );
            },
          ),
        );
      },
    );
  }

  Widget _screen() {
    final activeAccountData = _activeAccountData;
    return switch (_activeTab) {
      AppTab.home || AppTab.shop => HomeScreen(
        key: ValueKey(_selectedProfile),
        selectedProfile: _selectedProfile,
        signedInDisplayName: _homePersonalName,
        goal: _goal,
        unreadCount: _unreadCount,
        transactions: activeAccountData.transactions,
        onProfileChanged: _changeProfile,
        onOpenNotifications: _openNotifications,
        onPeriodChanged: _changePeriod,
        onAmountChanged: _changeSavingAmount,
        onSavePressed: _saveWithBank,
        onOpenSpending: _openSpending,
        onOpenShop: (context) => _openWishlistSheet(context),
        onBuy: () => setState(() => _activeTab = AppTab.payment),
        hasSelectedGoal: _firstTimeHasSelectedGoal,
      ),
      AppTab.settings => SettingsScreen(
        currentUser: _currentUser,
        themeChoice: _themeChoice,
        onThemeChanged: (choice) => setState(() => _themeChoice = choice),
        onOpenAccount: _openAccount,
      ),
      AppTab.notifications => NotificationsScreen(
        onBack: () => setState(() => _activeTab = AppTab.home),
      ),
      AppTab.habits => HabitsScreen(
        transactions: activeAccountData.transactions,
      ),
      AppTab.spending => SpendingScreen(
        key: ValueKey(_selectedProfile),
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
        insightError: _insightError,
        onRequestInsights: _requestSpendingInsights,
        showEmptyState:
            _selectedProfile.isFirstTime &&
            activeAccountData.transactions.isEmpty &&
            activeAccountData.lastUpdated == null,
      ),
      AppTab.history => RecentTransactionsScreen(
        key: ValueKey('${_selectedProfile.name}-${_historyFilter ?? 'all'}'),
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
        home: PopScope(
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
                          layoutBuilder: (currentChild, previousChildren) {
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
