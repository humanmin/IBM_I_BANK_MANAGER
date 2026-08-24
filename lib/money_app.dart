import 'package:flutter/material.dart';

import 'app_widgets.dart';
import 'commerce_screens.dart';
import 'home_screen.dart';
import 'models.dart';
import 'report_screens.dart';
import 'seed_data.dart';

class MoneyApp extends StatefulWidget {
  const MoneyApp({super.key});

  @override
  State<MoneyApp> createState() => _MoneyAppState();
}

class _MoneyAppState extends State<MoneyApp> {
  AppTab _activeTab = AppTab.home;
  SavingsGoal _goal = initialGoal;
  ThemeChoice _themeChoice = ThemeChoice.green;
  int _unreadCount = demoNotifications.length;
  String? _spendingFilter;

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

  void _selectProduct(ShopProduct product) {
    setState(() {
      _goal = _goal.copyWith(
        name: product.shortName,
        imageAsset: product.imageAsset,
        price: product.price,
      );
      _activeTab = AppTab.home;
    });
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
      ),
      AppTab.shop => ShoppingScreen(
        goal: _goal,
        onPeriodChanged: _changePeriod,
        onAmountChanged: _changeSavingAmount,
        onSelectProduct: _selectProduct,
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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: palette.accent,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: palette.pageBackground,
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: palette.text,
          displayColor: palette.text,
          fontFamily: 'sans-serif',
        ),
        splashFactory: InkRipple.splashFactory,
      ),
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
