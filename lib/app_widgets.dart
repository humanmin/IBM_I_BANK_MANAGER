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
    this.size = 72,
    this.radius = 20,
    super.key,
  });

  final String? imageAsset;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.paletteOf(context);
    final asset = imageAsset;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: asset == null
            ? ColoredBox(
                color: Colors.white.withValues(alpha: 0.7),
                child: Icon(
                  Icons.card_giftcard_rounded,
                  color: palette.textSoft,
                  size: size * 0.42,
                ),
              )
            : Image.asset(asset, fit: BoxFit.cover),
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
    return SoftCard(
      color: cardColor,
      radius: widget.compact ? 16 : 28,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          Row(
            children: [
              PopupMenuButton<SavingPeriod>(
                key: const Key('saving-period-menu'),
                initialValue: widget.goal.savingPeriod,
                onSelected: widget.onPeriodChanged,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                itemBuilder: (context) => SavingPeriod.values
                    .map(
                      (period) => PopupMenuItem(
                        value: period,
                        child: Text(
                          period.label,
                          style: const TextStyle(fontWeight: FontWeight.w700),
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
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  key: const Key('saving-amount-field'),
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onSubmitted: (_) => _commitAmount(),
                  onTapOutside: (_) {
                    _commitAmount();
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.only(bottom: 3),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: palette.text, width: 2),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: palette.text, width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '원을',
                style: TextStyle(
                  color: palette.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
            ],
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
