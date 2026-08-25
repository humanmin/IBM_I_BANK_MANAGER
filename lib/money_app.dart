import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'app_widgets.dart';
import 'commerce_screens.dart';
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

class _MoneyAppState extends State<MoneyApp> {
  AppTab _activeTab = AppTab.home;
  SavingsGoal _goal = initialGoal;
  ThemeChoice _themeChoice = ThemeChoice.green;
  int _unreadCount = demoNotifications.length;
  String? _spendingFilter;
  final List<FixedExpense> _fixedExpenses = [];
  final List<WishItem> _wishItems = [];
  late final ProductSearchGateway _productSearchGateway;
  late final bool _ownsProductSearchGateway;

  @override
  void initState() {
    super.initState();
    _ownsProductSearchGateway = widget.productSearchGateway == null;
    _productSearchGateway =
        widget.productSearchGateway ?? ProductSearchService();
  }

  @override
  void dispose() {
    if (_ownsProductSearchGateway &&
        _productSearchGateway is ProductSearchService) {
      _productSearchGateway.close();
    }
    super.dispose();
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
        onThemeChanged: (choice) => setState(() => _themeChoice = choice),
        onOpenNotifications: _openNotifications,
        onPeriodChanged: _changePeriod,
        onAmountChanged: _changeSavingAmount,
        onOpenSpending: _openSpending,
        onBuy: () => setState(() => _activeTab = AppTab.payment),
      ),
      AppTab.notifications => NotificationsScreen(
        onBack: () => setState(() => _activeTab = AppTab.home),
      ),
      AppTab.habits => const HabitsScreen(),
      AppTab.insights => InsightsScreen(
        goal: _goal,
        onOpenCategory: _openSpending,
        onSeeGoal: () => setState(() => _activeTab = AppTab.home),
      ),
      AppTab.spending => SpendingScreen(
        key: ValueKey(_spendingFilter ?? 'all'),
        initialCategory: _spendingFilter,
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
