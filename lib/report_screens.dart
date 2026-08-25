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
    required this.fixedExpenses,
    required this.onAddFixedExpense,
    required this.onUpdateFixedExpense,
    required this.onDeleteFixedExpense,
    this.initialCategory,
    super.key,
  });

  final String? initialCategory;
  final List<FixedExpense> fixedExpenses;
  final ValueChanged<FixedExpense> onAddFixedExpense;
  final ValueChanged<FixedExpense> onUpdateFixedExpense;
  final ValueChanged<FixedExpense> onDeleteFixedExpense;

  @override
  State<SpendingScreen> createState() => _SpendingScreenState();
}

class _SpendingScreenState extends State<SpendingScreen> {
  late final Set<String> _selectedCategories;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _selectedCategories = {?widget.initialCategory};
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
      controller: _scrollController,
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
        _FixedExpensesSection(
          expenses: widget.fixedExpenses,
          onAdd: _openFixedExpenseEditor,
          onEdit: _openFixedExpenseEditor,
          onDelete: _confirmFixedExpenseDelete,
        ),
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
        Row(
          children: [
            Expanded(
              child: Column(
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
                ],
              ),
            ),
            FilledButton.icon(
              key: const Key('add-fixed-expense-button'),
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('등록'),
              style: FilledButton.styleFrom(
                backgroundColor: palette.accent,
                foregroundColor: palette.text,
                padding: const EdgeInsets.symmetric(horizontal: 13),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
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
        const SizedBox(height: 10),
        if (expenses.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: mutedBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '등록된 고정지출이 없어요',
              style: TextStyle(
                color: palette.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        else
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
                      color: Colors.white,
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
