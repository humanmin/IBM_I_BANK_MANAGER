import 'dart:math' as math;

import 'package:flutter/material.dart';

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

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({
    required this.goal,
    required this.onOpenCategory,
    required this.onSeeGoal,
    super.key,
  });

  final SavingsGoal goal;
  final ValueChanged<String> onOpenCategory;
  final VoidCallback onSeeGoal;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.paletteOf(context);
    final insights = insightsFor(transactions, goal);
    return ListView(
      key: const PageStorageKey('insights-scroll'),
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      children: [
        const SectionHeading('이번 달 한마디'),
        const SizedBox(height: 16),
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
                onAction: () => onOpenCategory(insight.actionCategory),
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

class SpendingScreen extends StatefulWidget {
  const SpendingScreen({this.initialCategory, super.key});

  final String? initialCategory;

  @override
  State<SpendingScreen> createState() => _SpendingScreenState();
}

class _SpendingScreenState extends State<SpendingScreen> {
  late final Set<String> _selectedCategories;

  @override
  void initState() {
    super.initState();
    _selectedCategories = {?widget.initialCategory};
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.paletteOf(context);
    final stats = spendingStats(transactions, 2026, 8, 2026, 7);
    final recent = recentTransactions(transactions, 2026, 8);
    final visible = _selectedCategories.isEmpty
        ? recent
        : recent
              .where((item) => _selectedCategories.contains(item.category))
              .toList();
    final difference = stats.difference;
    final comparison = difference > 0
        ? '지난달보다 ${formatWon(difference)} 더 썼어요'
        : difference < 0
        ? '지난달보다 ${formatWon(difference.abs())} 덜 썼어요'
        : '지난달과 비슷하게 썼어요';
    return ListView(
      key: const PageStorageKey('spending-scroll'),
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      children: [
        const SectionHeading('이번 달 소비 통계', subtitle: '숫자가 많을수록, 고칠 점도 보여요'),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: palette.accentSoft,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '이번 달 총 지출',
                style: TextStyle(
                  color: palette.textSoft,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                formatWon(stats.thisMonthSpent),
                style: TextStyle(
                  color: palette.text,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                comparison,
                style: TextStyle(
                  color: palette.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
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
            _StatsTile(label: '하루 평균', value: formatWon(stats.averagePerDay)),
          ],
        ),
        if (stats.topCategory case final topCategory?) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: palette.accentSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '가장 많이 쓴 곳',
                  style: TextStyle(
                    color: palette.textSoft,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(categoryMeta[topCategory]?.emoji ?? '•'),
                    const SizedBox(width: 8),
                    Text(
                      topCategory,
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      formatWon(stats.topCategoryAmount),
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
          ),
        ],
        const SizedBox(height: 28),
        Text(
          '최근 내역',
          style: TextStyle(
            color: palette.text,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categoryMeta.entries.map((entry) {
            final selected = _selectedCategories.contains(entry.key);
            return FilterChip(
              label: Text('${entry.value.emoji} ${entry.key}'),
              selected: selected,
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
              selectedColor: palette.accent,
              backgroundColor: mutedBackground,
              side: BorderSide.none,
              shape: const StadiumBorder(),
              labelStyle: TextStyle(
                color: selected ? palette.text : palette.textSoft,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        if (visible.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: mutedBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              '선택한 카테고리의 내역이 없어요',
              style: TextStyle(
                color: palette.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        else
          ..._transactionWidgets(visible, palette),
      ],
    );
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
            padding: const EdgeInsets.only(top: 10, bottom: 2),
            child: Row(
              children: [
                Text(
                  '${item.date.month}월 ${item.date.day}일',
                  style: TextStyle(
                    color: palette.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(child: Divider(color: dividerColor)),
              ],
            ),
          ),
        );
      }
      widgets.add(_TransactionRow(transaction: item));
    }
    return widgets;
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: dividerColor)),
      ),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  transaction.category,
                  style: TextStyle(color: palette.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '-${formatWon(transaction.amount)}',
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
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.paletteOf(context);
    final categories = categoryTotals(transactions, 2026, 8, categoryMeta);
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
