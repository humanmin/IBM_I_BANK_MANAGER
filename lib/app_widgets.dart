import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'money_utils.dart';

const mutedBackground = Color(0xFFF4F4F4);
const dividerColor = Color(0xFFECECEC);

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {this.subtitle, super.key});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.paletteOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: palette.text,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
          ),
        ),
        if (subtitle case final subtitle?) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: palette.textMuted, fontSize: 13),
          ),
        ],
      ],
    );
  }
}

class AppSheetHeader extends StatelessWidget {
  const AppSheetHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onClose,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.paletteOf(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: palette.accentSoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: palette.accentBorder),
          ),
          child: Icon(icon, color: palette.textSoft, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: palette.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  color: palette.textMuted,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: '닫기',
          onPressed: onClose,
          style: IconButton.styleFrom(
            backgroundColor: mutedBackground,
            foregroundColor: palette.textSoft,
          ),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }
}

class AppDeleteDialog extends StatelessWidget {
  const AppDeleteDialog({
    required this.title,
    required this.message,
    super.key,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
      icon: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: colors.errorContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.delete_outline_rounded, color: colors.error),
      ),
      title: Text(title, textAlign: TextAlign.center),
      content: Text(message, textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: colors.error,
            foregroundColor: colors.onError,
          ),
          child: const Text('삭제'),
        ),
      ],
    );
  }
}

class SoftCard extends StatelessWidget {
  const SoftCard({
    required this.child,
    required this.color,
    this.padding = const EdgeInsets.all(20),
    this.radius = 28,
    this.onTap,
    super.key,
  });

  final Widget child;
  final Color color;
  final EdgeInsets padding;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 28,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Semantics(
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class GoalImage extends StatelessWidget {
  const GoalImage({
    required this.imageAsset,
    this.imageUrl,
    this.size = 72,
    this.radius = 20,
    super.key,
  });

  final String? imageAsset;
  final String? imageUrl;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.paletteOf(context);
    final asset = imageAsset;
    final networkUrl = imageUrl;
    Widget placeholder() => ColoredBox(
      color: Colors.white.withValues(alpha: 0.7),
      child: Icon(
        Icons.card_giftcard_rounded,
        color: palette.textSoft,
        size: size * 0.42,
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: asset != null
            ? Image.asset(asset, fit: BoxFit.cover)
            : networkUrl != null && networkUrl.isNotEmpty
            ? Image.network(
                networkUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : placeholder(),
                errorBuilder: (context, error, stackTrace) => placeholder(),
              )
            : placeholder(),
      ),
    );
  }
}

class ThemeScope extends InheritedWidget {
  const ThemeScope({required this.palette, required super.child, super.key});

  final AppPalette palette;

  static AppPalette paletteOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    assert(scope != null, 'ThemeScope is missing above this widget.');
    return scope!.palette;
  }

  @override
  bool updateShouldNotify(ThemeScope oldWidget) => palette != oldWidget.palette;
}

class SavingPlanCard extends StatefulWidget {
  const SavingPlanCard({
    required this.goal,
    required this.onPeriodChanged,
    required this.onAmountChanged,
    this.compact = false,
    super.key,
  });

  final SavingsGoal goal;
  final ValueChanged<SavingPeriod> onPeriodChanged;
  final ValueChanged<int> onAmountChanged;
  final bool compact;

  @override
  State<SavingPlanCard> createState() => _SavingPlanCardState();
}

class _SavingPlanCardState extends State<SavingPlanCard> {
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: formatNumber(widget.goal.savingAmount),
    );
  }

  @override
  void didUpdateWidget(covariant SavingPlanCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.goal.savingAmount != widget.goal.savingAmount) {
      _amountController.text = formatNumber(widget.goal.savingAmount);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _commitAmount() {
    final value = int.tryParse(_amountController.text.replaceAll(',', ''));
    if (value == null || value < 1) {
      _amountController.text = formatNumber(widget.goal.savingAmount);
      return;
    }
    widget.onAmountChanged(value);
    _amountController.text = formatNumber(value);
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.paletteOf(context);
    final cardColor = widget.compact ? mutedBackground : palette.accentSoft;
    final amountTextStyle = TextStyle(
      color: palette.text,
      fontSize: 22,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.7,
    );
    final amountText = _amountController.text.isEmpty
        ? '0'
        : _amountController.text;
    final extraAmountCharacters = amountText.length > 5
        ? amountText.length - 5
        : 0;
    final amountFieldWidth = (70.0 + extraAmountCharacters * 11)
        .clamp(70.0, 160.0)
        .toDouble();
    return SoftCard(
      color: cardColor,
      radius: widget.compact ? 16 : 28,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '저축 계획',
            style: TextStyle(
              color: palette.textSoft,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            key: const Key('saving-sentence-wrap'),
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            runSpacing: 2,
            children: [
              PopupMenuButton<SavingPeriod>(
                key: const Key('saving-period-menu'),
                initialValue: widget.goal.savingPeriod,
                onSelected: widget.onPeriodChanged,
                offset: const Offset(0, 8),
                itemBuilder: (context) => SavingPeriod.values
                    .map(
                      (period) => PopupMenuItem(
                        value: period,
                        height: 48,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                period.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (period == widget.goal.savingPeriod)
                              Icon(
                                Icons.check_circle_rounded,
                                color: palette.textSoft,
                                size: 19,
                              ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                child: Container(
                  padding: const EdgeInsets.only(bottom: 2),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: palette.text, width: 2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.goal.savingPeriod.label,
                        style: TextStyle(
                          color: palette.text,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.7,
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: palette.textSoft,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
              Text(
                '마다',
                style: TextStyle(
                  color: palette.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
              SizedBox(
                width: amountFieldWidth,
                child: TextField(
                  key: const Key('saving-amount-field'),
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _commitAmount(),
                  onTapOutside: (_) {
                    _commitAmount();
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                  style: amountTextStyle,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: false,
                    contentPadding: const EdgeInsets.only(bottom: 3),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: palette.text, width: 2),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      // width is weight of the border
                      borderSide: BorderSide(color: palette.text, width: 2),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: palette.text, width: 1),
                    ),
                  ),
                ),
              ),
              Text(
                '원을',
                style: TextStyle(
                  color: palette.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
              Text(
                '저축하기',
                style: TextStyle(
                  color: palette.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    required this.activeTab,
    required this.onChanged,
    super.key,
  });

  final AppTab activeTab;
  final ValueChanged<AppTab> onChanged;

  static const items = <(AppTab, IconData, String)>[
    (AppTab.home, Icons.home_outlined, '홈'),
    (AppTab.insights, Icons.chat_bubble_outline, '피드백'),
    (AppTab.spending, Icons.bar_chart_rounded, '통계'),
    (AppTab.event, Icons.card_giftcard_rounded, '이벤트'),
    (AppTab.shop, Icons.shopping_cart_outlined, '쇼핑'),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.paletteOf(context);
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: dividerColor)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        child: Row(
          children: items.map((item) {
            final (tab, icon, label) = item;
            final selected = activeTab == tab;
            return Expanded(
              child: InkWell(
                key: Key('nav-${tab.name}'),
                onTap: () => onChanged(tab),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: selected ? palette.accent : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          size: 22,
                          color: selected
                              ? palette.text
                              : const Color(0xFF9A9A9A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: TextStyle(
                          color: selected
                              ? palette.text
                              : const Color(0xFF9A9A9A),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
