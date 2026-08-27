import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_widgets.dart';
import 'models.dart';
import 'money_utils.dart';
import 'seed_data.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.paletteOf(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, size: 17),
            label: const Text('홈으로'),
            style: TextButton.styleFrom(
              foregroundColor: palette.textSoft,
              padding: EdgeInsets.zero,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const SectionHeading('알림', subtitle: '소비 리포트와 한도 알림이에요'),
        const SizedBox(height: 16),
        ...demoNotifications.map(
          (notification) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: const TextStyle(
                            color: Color(0xFF222222),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        notification.timeLabel,
                        style: const TextStyle(
                          color: Color(0xFF9A9A9A),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.body,
                    style: const TextStyle(
                      color: Color(0xFF6A6A6A),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InsightsSection extends StatelessWidget {
  const _InsightsSection({
    required this.goal,
    required this.transactions,
    required this.onOpenCategory,
    required this.onSeeGoal,
    this.remoteInsights,
    this.loading = false,
  });

  final SavingsGoal goal;
  final List<MoneyTransaction> transactions;
  final ValueChanged<String> onOpenCategory;
  final VoidCallback onSeeGoal;
  final List<Insight>? remoteInsights;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.paletteOf(context);
    final insights = remoteInsights != null && remoteInsights!.isNotEmpty
        ? remoteInsights!
        : insightsFor(transactions, goal);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '이번 달 한마디',
          style: TextStyle(
            color: palette.text,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          loading ? '이번 달 소비를 살펴보는 중이에요' : '소비 습관에서 눈에 띄는 점을 짚어줘요',
          style: TextStyle(color: palette.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        if (insights.isEmpty)
          _InsightCard(
            title: '이번 달은 무난해요',
            body: '크게 늘어난 소비가 없어요. ${goal.name}까지 남은 날을 한번 확인해 볼까요?',
            actionLabel: '목표 다시 보기',
            onAction: onSeeGoal,
          )
        else
          ...insights.map(
            (insight) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _InsightCard(
                title: insight.title,
                body: insight.body,
                actionLabel: insight.actionLabel,
                onAction: insight.actionCategory.isEmpty
                    ? onSeeGoal
                    : () => onOpenCategory(insight.actionCategory),
              ),
            ),
          ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.accentSoft,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '${goal.name}까지 ${daysToGoal(goal)}일 남았어요. 작은 소비 하나가 도착 날짜를 바꿔요.',
            style: TextStyle(
              color: palette.textSoft,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.paletteOf(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: mutedBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: palette.text,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(
              color: palette.textSoft,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: palette.text,
              padding: EdgeInsets.zero,
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _BoundedPointerScrollController extends ScrollController {
  _BoundedPointerScrollController();

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return _BoundedPointerScrollPosition(
      physics: physics,
      context: context,
      initialPixels: initialScrollOffset,
      keepScrollOffset: keepScrollOffset,
      oldPosition: oldPosition,
      debugLabel: debugLabel,
    );
  }
}

class _BoundedPointerScrollPosition extends ScrollPositionWithSingleContext {
  _BoundedPointerScrollPosition({
    required super.physics,
    required super.context,
    required super.initialPixels,
    required super.keepScrollOffset,
    super.oldPosition,
    super.debugLabel,
  });

  static const _maximumDelta = 120.0;

  @override
  void pointerScroll(double delta) {
    super.pointerScroll(delta.clamp(-_maximumDelta, _maximumDelta).toDouble());
  }
}

class SpendingScreen extends StatefulWidget {
  const SpendingScreen({
    required this.goal,
    required this.transactions,
    required this.isDemoData,
    required this.lastUpdated,
    required this.notificationAccessGranted,
    required this.onImportAccountData,
    required this.onSyncNotifications,
    required this.onOpenNotificationSettings,
    required this.onSeeGoal,
    required this.onOpenHistory,
    required this.fixedExpenses,
    required this.onAddFixedExpense,
    required this.onUpdateFixedExpense,
    required this.onDeleteFixedExpense,
    this.remoteInsights,
    this.insightsLoading = false,
    super.key,
  });

  final SavingsGoal goal;
  final List<MoneyTransaction> transactions;
  final bool isDemoData;
  final DateTime? lastUpdated;
  final bool notificationAccessGranted;
  final Future<AccountActionResult> Function() onImportAccountData;
  final Future<AccountActionResult> Function() onSyncNotifications;
  final Future<AccountActionResult> Function() onOpenNotificationSettings;
  final VoidCallback onSeeGoal;
  final ValueChanged<String> onOpenHistory;
  final List<FixedExpense> fixedExpenses;
  final ValueChanged<FixedExpense> onAddFixedExpense;
  final ValueChanged<FixedExpense> onUpdateFixedExpense;
  final ValueChanged<FixedExpense> onDeleteFixedExpense;
  final List<Insight>? remoteInsights;
  final bool insightsLoading;

  @override
  State<SpendingScreen> createState() => _SpendingScreenState();
}

class _SpendingScreenState extends State<SpendingScreen> {
  late final ScrollController _scrollController;
  bool _accountActionInProgress = false;

  @override
  void initState() {
    super.initState();
    _scrollController = _BoundedPointerScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openFixedExpenseEditor([FixedExpense? expense]) async {
    final palette = ThemeScope.paletteOf(context);
    final result = await showModalBottomSheet<FixedExpense>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => ThemeScope(
        palette: palette,
        child: _FixedExpenseEditor(expense: expense),
      ),
    );
    if (result == null || !mounted) return;
    if (expense == null) {
      widget.onAddFixedExpense(result);
    } else {
      widget.onUpdateFixedExpense(result);
    }
  }

  Future<void> _confirmFixedExpenseDelete(FixedExpense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AppDeleteDialog(
        title: '고정지출을 삭제할까요?',
        message: '${expense.name}을 목록에서 삭제해요.',
      ),
    );
    if (confirmed == true) widget.onDeleteFixedExpense(expense);
  }

  Future<void> _runAccountAction(
    Future<AccountActionResult> Function() action,
  ) async {
    if (_accountActionInProgress) return;
    setState(() => _accountActionInProgress = true);
    final result = await action();
    if (!mounted) return;
    setState(() => _accountActionInProgress = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(result.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final categories = categoryTotals(
      widget.transactions,
      now.year,
      now.month,
      categoryMeta,
    );
    return ListView(
      key: const PageStorageKey('spending-scroll'),
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      children: [
        const SectionHeading('이번 달 소비 통계', subtitle: '숫자가 많을수록, 고칠 점도 보여요'),
        const SizedBox(height: 18),
        _AccountDataSection(
          isDemoData: widget.isDemoData,
          lastUpdated: widget.lastUpdated,
          notificationAccessGranted: widget.notificationAccessGranted,
          busy: _accountActionInProgress,
          onImport: () => _runAccountAction(widget.onImportAccountData),
          onNotificationAction: () => _runAccountAction(
            widget.notificationAccessGranted
                ? widget.onSyncNotifications
                : widget.onOpenNotificationSettings,
          ),
        ),
        const SizedBox(height: 28),
        _CategoryPieCard(categories: categories),
        const SizedBox(height: 28),
        _SpendingBarCard(transactions: widget.transactions, referenceDate: now),
        const SizedBox(height: 28),
        _FixedExpensesSection(
          expenses: widget.fixedExpenses,
          onAdd: _openFixedExpenseEditor,
          onEdit: _openFixedExpenseEditor,
          onDelete: _confirmFixedExpenseDelete,
        ),
        const SizedBox(height: 28),
        _InsightsSection(
          goal: widget.goal,
          transactions: widget.transactions,
          onOpenCategory: widget.onOpenHistory,
          onSeeGoal: widget.onSeeGoal,
          remoteInsights: widget.remoteInsights,
          loading: widget.insightsLoading,
        ),
      ],
    );
  }
}

class _CategoryPieCard extends StatelessWidget {
  const _CategoryPieCard({required this.categories});

  final List<CategoryTotal> categories;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.paletteOf(context);
    final total = categories.fold<int>(0, (sum, item) => sum + item.amount);
    return Column(
      key: const Key('category-pie-card'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '소비 카테고리 비율',
          style: TextStyle(
            color: palette.text,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '이번 달 어디에 가장 많이 썼는지 보여요',
          style: TextStyle(color: palette.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        if (categories.isEmpty)
          SizedBox(
            height: 120,
            child: Center(
              child: Text(
                '표시할 소비 내역이 없어요',
                style: TextStyle(
                  color: palette.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
        else
          Row(
            children: [
              SizedBox(
                width: 124,
                height: 124,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      key: const Key('category-pie-chart'),
                      size: const Size.square(124),
                      painter: _CategoryPiePainter(categories),
                    ),
                    SizedBox(
                      width: 72,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '전체',
                            style: TextStyle(
                              color: palette.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              formatWon(total),
                              style: TextStyle(
                                color: palette.text,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: categories.take(5).map((category) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: category.info.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              category.category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: palette.textSoft,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            '${category.percent}%',
                            style: TextStyle(
                              color: palette.text,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _CategoryPiePainter extends CustomPainter {
  const _CategoryPiePainter(this.categories);

  final List<CategoryTotal> categories;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 12;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const strokeWidth = 18.0;
    final backgroundPaint = Paint()
      ..color = mutedBackground
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, backgroundPaint);

    final total = categories.fold<int>(0, (sum, item) => sum + item.amount);
    if (total <= 0) return;
    var start = -math.pi / 2;
    for (final category in categories) {
      final sweep = math.pi * 2 * category.amount / total;
      final visibleSweep = math.max(0.008, sweep - 0.035);
      final paint = Paint()
        ..color = category.info.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, start, visibleSweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _CategoryPiePainter oldDelegate) => true;
}

enum _SpendingBarPeriod { daily, weekly }

class _ChartBar {
  const _ChartBar({required this.label, required this.amount});

  final String label;
  final int amount;
}

class _SpendingBarCard extends StatefulWidget {
  const _SpendingBarCard({
    required this.transactions,
    required this.referenceDate,
  });

  final List<MoneyTransaction> transactions;
  final DateTime referenceDate;

  @override
  State<_SpendingBarCard> createState() => _SpendingBarCardState();
}

class _SpendingBarCardState extends State<_SpendingBarCard> {
  _SpendingBarPeriod _period = _SpendingBarPeriod.daily;

  List<_ChartBar> get _dailyBars {
    final today = DateTime(
      widget.referenceDate.year,
      widget.referenceDate.month,
      widget.referenceDate.day,
    );
    return List.generate(7, (index) {
      final date = today.subtract(Duration(days: 6 - index));
      final amount = widget.transactions
          .where(
            (item) =>
                item.date.year == date.year &&
                item.date.month == date.month &&
                item.date.day == date.day,
          )
          .fold<int>(0, (sum, item) => sum + item.amount);
      return _ChartBar(label: '${date.day}일', amount: amount);
    });
  }

  List<_ChartBar> get _weeklyBars {
    final year = widget.referenceDate.year;
    final month = widget.referenceDate.month;
    final weekCount = (DateTime(year, month + 1, 0).day / 7).ceil();
    return List.generate(weekCount, (index) {
      final amount = widget.transactions
          .where(
            (item) =>
                item.date.year == year &&
                item.date.month == month &&
                (item.date.day - 1) ~/ 7 == index,
          )
          .fold<int>(0, (sum, item) => sum + item.amount);
      return _ChartBar(label: '${index + 1}주', amount: amount);
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.paletteOf(context);
    final bars = _period == _SpendingBarPeriod.daily ? _dailyBars : _weeklyBars;
    final maximum = bars.fold<int>(
      0,
      (value, bar) => math.max(value, bar.amount),
    );
    return Column(
      key: const Key('spending-bar-card'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '소비 흐름',
                    style: TextStyle(
                      color: palette.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _period == _SpendingBarPeriod.daily
                        ? '최근 7일 사용량'
                        : '이번 달 주간별 사용량',
                    style: TextStyle(color: palette.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: mutedBackground,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  _periodButton('일별', _SpendingBarPeriod.daily),
                  _periodButton('주별', _SpendingBarPeriod.weekly),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 150,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: bars.map((bar) {
              final ratio = maximum == 0 ? 0.0 : bar.amount / maximum;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        height: 17,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _compactChartAmount(bar.amount),
                            style: TextStyle(
                              color: palette.textSoft,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      SizedBox(
                        height: 96,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: AnimatedContainer(
                            key: Key('spending-bar-${bar.label}'),
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeOutCubic,
                            width: _period == _SpendingBarPeriod.daily
                                ? 20
                                : 30,
                            height: bar.amount == 0
                                ? 3
                                : math.max(8, 96 * ratio),
                            decoration: BoxDecoration(
                              color: bar.amount == 0
                                  ? palette.accentTrack
                                  : palette.accent,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(7),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        bar.label,
                        style: TextStyle(
                          color: palette.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _periodButton(String label, _SpendingBarPeriod period) {
    final palette = ThemeScope.paletteOf(context);
    final selected = _period == period;
    return TextButton(
      key: Key('spending-bar-${period.name}'),
      onPressed: () => setState(() => _period = period),
      style: TextButton.styleFrom(
        foregroundColor: selected ? palette.text : palette.textMuted,
        backgroundColor: selected ? palette.surface : Colors.transparent,
        minimumSize: const Size(46, 30),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        shape: const StadiumBorder(),
      ),
      child: Text(label),
    );
  }
}

String _compactChartAmount(int amount) {
  if (amount == 0) return '0';
  if (amount >= 100000000) {
    return '${(amount / 100000000).toStringAsFixed(1)}억';
  }
  if (amount >= 10000) {
    final value = amount / 10000;
    return '${value >= 100 ? value.round() : value.toStringAsFixed(1)}만';
  }
  return formatNumber(amount);
}

class RecentTransactionsScreen extends StatefulWidget {
  const RecentTransactionsScreen({
    required this.transactions,
    this.initialCategory,
    super.key,
  });

  final List<MoneyTransaction> transactions;
  final String? initialCategory;

  @override
  State<RecentTransactionsScreen> createState() =>
      _RecentTransactionsScreenState();
}

class _RecentTransactionsScreenState extends State<RecentTransactionsScreen> {
  late final Set<String> _selectedCategories;
  var _chipsExpanded = true;

  @override
  void initState() {
    super.initState();
    _selectedCategories = {
      if (widget.initialCategory case final category?) category,
    };
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.paletteOf(context);
    final now = DateTime.now();
    final previousMonth = DateTime(now.year, now.month - 1);
    final stats = spendingStats(
      widget.transactions,
      now.year,
      now.month,
      previousMonth.year,
      previousMonth.month,
      asOf: now,
    );
    final monthItems = recentTransactions(
      widget.transactions,
      now.year,
      now.month,
    );
    final visible = _selectedCategories.isEmpty
        ? monthItems
        : monthItems
              .where((item) => _selectedCategories.contains(item.category))
              .toList();
    // One scroll view for the header cards and the transaction list.
    // A Column + Expanded ListView would pin the top cards while only
    // the rows below moved.
    return CustomScrollView(
      key: const Key('recent-transactions-sheet'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '최근 내역',
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '이번 달 ${monthItems.length}건',
                  style: TextStyle(color: palette.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _StatsTile(label: '거래 횟수', value: '${stats.count}번'),
                    const SizedBox(width: 8),
                    _StatsTile(
                      label: '건당 평균',
                      value: formatWon(stats.averagePerTransaction),
                    ),
                    const SizedBox(width: 8),
                    _StatsTile(
                      label: '하루 평균',
                      value: formatWon(stats.averagePerDay),
                    ),
                  ],
                ),
                if (stats.topCategory case final topCategory?) ...[
                  const SizedBox(height: 14),
                  _TopCategoryCard(
                    category: topCategory,
                    amount: stats.topCategoryAmount,
                  ),
                ],
                const SizedBox(height: 12),
                ChipTheme(
                  data: ChipTheme.of(context).copyWith(
                    labelStyle: TextStyle(
                      color: palette.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 0,
                    ),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 5),
                  ),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ChoiceChip(
                        key: const Key('recent-filter-all'),
                        label: const Text('전체'),
                        selected: _selectedCategories.isEmpty,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onSelected: (_) => setState(_selectedCategories.clear),
                        showCheckmark: false,
                      ),
                      ...categoryMeta.entries
                          .where(
                            (entry) =>
                                _chipsExpanded ||
                                _selectedCategories.contains(entry.key),
                          )
                          .map((entry) {
                            final selected = _selectedCategories.contains(
                              entry.key,
                            );
                            return FilterChip(
                              key: Key('recent-filter-${entry.key}'),
                              label: Text('${entry.value.emoji} ${entry.key}'),
                              selected: selected,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              onSelected: (_) {
                                setState(() {
                                  if (selected) {
                                    _selectedCategories.remove(entry.key);
                                  } else {
                                    _selectedCategories.add(entry.key);
                                  }
                                });
                              },
                              showCheckmark: false,
                            );
                          }),
                      InkWell(
                        key: const Key('fold-chips-button'),
                        onTap: () =>
                            setState(() => _chipsExpanded = !_chipsExpanded),
                        borderRadius: BorderRadius.circular(999),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            _chipsExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 22,
                            color: palette.textSoft,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (visible.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                '선택한 카테고리의 내역이 없어요',
                style: TextStyle(
                  color: palette.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                _transactionWidgets(visible, palette),
              ),
            ),
          ),
      ],
    );
  }
}

class _TopCategoryCard extends StatelessWidget {
  const _TopCategoryCard({required this.category, required this.amount});

  final String category;
  final int amount;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.paletteOf(context);
    return Container(
      key: const Key('top-category-card'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.accentSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '가장 많이 쓴 카테고리',
            style: TextStyle(
              color: palette.textSoft,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      categoryMeta[category]?.emoji ?? '•',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: palette.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                formatWon(amount),
                style: TextStyle(
                  color: palette.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

List<Widget> _transactionWidgets(
  List<MoneyTransaction> items,
  AppPalette palette,
) {
  final widgets = <Widget>[];
  DateTime? currentDay;
  for (final item in items) {
    if (currentDay == null ||
        currentDay.year != item.date.year ||
        currentDay.month != item.date.month ||
        currentDay.day != item.date.day) {
      currentDay = item.date;
      widgets.add(
        Padding(
          padding: EdgeInsets.only(top: widgets.isEmpty ? 22 : 20, bottom: 4),
          child: Row(
            children: [
              Text(
                '${item.date.month}월 ${item.date.day}일',
                style: TextStyle(
                  color: palette.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Divider(height: 1, thickness: 1, color: dividerColor),
              ),
            ],
          ),
        ),
      );
    }
    widgets.add(_TransactionRow(transaction: item));
  }
  return widgets;
}

class _AccountDataSection extends StatelessWidget {
  const _AccountDataSection({
    required this.isDemoData,
    required this.lastUpdated,
    required this.notificationAccessGranted,
    required this.busy,
    required this.onImport,
    required this.onNotificationAction,
  });

  final bool isDemoData;
  final DateTime? lastUpdated;
  final bool notificationAccessGranted;
  final bool busy;
  final VoidCallback onImport;
  final VoidCallback onNotificationAction;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.paletteOf(context);
    final updatedLabel = lastUpdated == null
        ? '아직 가져온 내역이 없어요'
        : '마지막 반영 ${lastUpdated!.month}월 ${lastUpdated!.day}일 '
              '${lastUpdated!.hour.toString().padLeft(2, '0')}:'
              '${lastUpdated!.minute.toString().padLeft(2, '0')}';
    return Container(
      key: const Key('account-data-card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.accentSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: palette.text,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '내 소비 데이터',
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      isDemoData ? '예시 데이터로 표시 중' : updatedLabel,
                      style: TextStyle(
                        color: palette.textMuted,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: isDemoData ? mutedBackground : palette.accentSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isDemoData ? 'DEMO' : '내 데이터',
                  style: TextStyle(
                    color: palette.textSoft,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  key: const Key('import-account-data-button'),
                  onPressed: busy ? null : onImport,
                  icon: const Icon(Icons.file_open_outlined, size: 18),
                  label: const Text('내역 가져오기'),
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.surface,
                    foregroundColor: palette.text,
                    minimumSize: const Size(44, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('notification-capture-button'),
                  onPressed: busy ? null : onNotificationAction,
                  icon: Icon(
                    notificationAccessGranted
                        ? Icons.sync_rounded
                        : Icons.notifications_active_outlined,
                    size: 18,
                  ),
                  label: Text(
                    notificationAccessGranted ? '새 알림 반영' : '알림 자동 등록',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: palette.text,
                    side: BorderSide(color: palette.accentBorder),
                    minimumSize: const Size(44, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

const _fixedExpenseCategories = <String>[
  'OTT·구독',
  '통신비',
  '관리비',
  '월세',
  '보험',
  '기타',
];

String _fixedExpenseEmoji(String category) {
  return switch (category) {
    'OTT·구독' => '📺',
    '통신비' => '📱',
    '관리비' => '🏢',
    '월세' => '🏠',
    '보험' => '🛡️',
    _ => '📌',
  };
}

class _FixedExpensesSection extends StatelessWidget {
  const _FixedExpensesSection({
    required this.expenses,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final List<FixedExpense> expenses;
  final VoidCallback onAdd;
  final ValueChanged<FixedExpense> onEdit;
  final ValueChanged<FixedExpense> onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.paletteOf(context);
    final monthlyTotal = expenses.fold<int>(
      0,
      (total, expense) => total + expense.amount,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '구독·고정지출',
          style: TextStyle(
            color: palette.text,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '매달 빠져나가는 비용을 직접 관리해요',
          style: TextStyle(color: palette.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.accentSoft,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Text(
                '월 고정지출',
                style: TextStyle(
                  color: palette.textSoft,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                formatWon(monthlyTotal),
                style: TextStyle(
                  color: palette.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        if (expenses.isNotEmpty) ...[
          const SizedBox(height: 10),
          ...expenses.map(
            (expense) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.fromLTRB(12, 8, 2, 8),
              decoration: BoxDecoration(
                color: mutedBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Text(
                      _fixedExpenseEmoji(expense.category),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${expense.category} · 매월 ${expense.billingDay}일',
                          style: TextStyle(
                            color: palette.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatWon(expense.amount),
                    style: TextStyle(
                      color: palette.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    key: Key('edit-fixed-${expense.id}'),
                    tooltip: '수정',
                    onPressed: () => onEdit(expense),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    color: palette.textMuted,
                  ),
                  IconButton(
                    key: Key('delete-fixed-${expense.id}'),
                    tooltip: '삭제',
                    onPressed: () => onDelete(expense),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    color: palette.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            key: const Key('add-fixed-expense-button'),
            onPressed: onAdd,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF9A9A9A),
              backgroundColor: mutedBackground,
              minimumSize: const Size.fromHeight(44),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('+ 등록'),
          ),
        ),
      ],
    );
  }
}

class _FixedExpenseEditor extends StatefulWidget {
  const _FixedExpenseEditor({this.expense});

  final FixedExpense? expense;

  @override
  State<_FixedExpenseEditor> createState() => _FixedExpenseEditorState();
}

class _FixedExpenseEditorState extends State<_FixedExpenseEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _billingDayController;
  late String _category;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.expense?.name ?? '');
    _amountController = TextEditingController(
      text: widget.expense == null ? '' : '${widget.expense!.amount}',
    );
    _billingDayController = TextEditingController(
      text: widget.expense == null ? '' : '${widget.expense!.billingDay}',
    );
    _category = widget.expense?.category ?? _fixedExpenseCategories.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _billingDayController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      FixedExpense(
        id:
            widget.expense?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        amount: int.parse(_amountController.text),
        category: _category,
        billingDay: int.parse(_billingDayController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.paletteOf(context);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        24,
        20,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSheetHeader(
              icon: Icons.receipt_long_rounded,
              title: widget.expense == null ? '고정지출 등록' : '고정지출 수정',
              subtitle: '구독, 통신비, 관리비, 월세를 한곳에서 관리하세요.',
              onClose: () => Navigator.pop(context),
            ),
            const SizedBox(height: 24),
            TextFormField(
              key: const Key('fixed-name-field'),
              controller: _nameController,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: '지출 이름',
                hintText: '예: 넷플릭스',
                prefixIcon: Icon(Icons.edit_note_rounded),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? '지출 이름을 입력해 주세요'
                  : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: '분류',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: _fixedExpenseCategories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text('${_fixedExpenseEmoji(category)} $category'),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    key: const Key('fixed-amount-field'),
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: '월 금액',
                      suffixText: '원',
                    ),
                    validator: (value) {
                      final amount = int.tryParse(value ?? '');
                      return amount == null || amount < 1
                          ? '금액을 입력해 주세요'
                          : null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    key: const Key('fixed-day-field'),
                    controller: _billingDayController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onFieldSubmitted: (_) => _save(),
                    decoration: const InputDecoration(
                      labelText: '결제일',
                      suffixText: '일',
                    ),
                    validator: (value) {
                      final day = int.tryParse(value ?? '');
                      return day == null || day < 1 || day > 31
                          ? '1~31일'
                          : null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('save-fixed-expense-button'),
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: palette.accent,
                  foregroundColor: palette.text,
                  minimumSize: const Size.fromHeight(52),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
                child: const Text('저장'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsTile extends StatelessWidget {
  const _StatsTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.paletteOf(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 12),
        decoration: BoxDecoration(
          color: mutedBackground,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(color: palette.textMuted, fontSize: 11),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  color: palette.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction});

  final MoneyTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.paletteOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: mutedBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              categoryMeta[transaction.category]?.emoji ?? '•',
              style: const TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.merchant,
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  transaction.category,
                  style: TextStyle(color: palette.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            formatWon(transaction.amount.abs()),
            style: TextStyle(
              color: palette.text,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class HabitsScreen extends StatelessWidget {
  const HabitsScreen({required this.transactions, super.key});

  final List<MoneyTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.paletteOf(context);
    final now = DateTime.now();
    final categories = categoryTotals(
      transactions,
      now.year,
      now.month,
      categoryMeta,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      children: [
        const SectionHeading('어디에 썼나요?', subtitle: '이번 달 습관을 한눈에 봐요'),
        const SizedBox(height: 16),
        ...categories.map(
          (category) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(category.info.emoji),
                    const SizedBox(width: 8),
                    Text(
                      category.category,
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      formatWon(category.amount),
                      style: TextStyle(color: palette.textSoft, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: math.max(category.percent / 100, 0.02),
                    minHeight: 8,
                    backgroundColor: mutedBackground,
                    valueColor: AlwaysStoppedAnimation(category.info.color),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
