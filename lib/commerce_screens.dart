import 'package:flutter/material.dart';

import 'app_widgets.dart';
import 'models.dart';
import 'money_utils.dart';
import 'seed_data.dart';

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({
    required this.goal,
    required this.onPeriodChanged,
    required this.onAmountChanged,
    required this.onSelectProduct,
    super.key,
  });

  final SavingsGoal goal;
  final ValueChanged<SavingPeriod> onPeriodChanged;
  final ValueChanged<int> onAmountChanged;
  final ValueChanged<ShopProduct> onSelectProduct;

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  String _activeTab = 'ranking';

  static const tabs = <(String, String)>[
    ('ranking', '랭킹'),
    ('new', '신상품'),
    ('sale', '세일'),
    ('special', '스페셜'),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.paletteOf(context);
    final products = shopProducts
        .where((product) => product.tabs.contains(_activeTab))
        .toList();
    return ListView(
      key: const PageStorageKey('shop-scroll'),
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      children: [
        Text(
          '위시 스토어',
          style: TextStyle(
            color: palette.text,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '물건을 누르면 저축 목표가 바뀌어요',
          style: TextStyle(color: palette.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tabs.map((tab) {
            final (id, label) = tab;
            final selected = id == _activeTab;
            return ChoiceChip(
              label: Text(label),
              selected: selected,
              showCheckmark: false,
              onSelected: (_) => setState(() => _activeTab = id),
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
        const SizedBox(height: 16),
        SavingPlanCard(
          goal: widget.goal,
          compact: true,
          onPeriodChanged: widget.onPeriodChanged,
          onAmountChanged: widget.onAmountChanged,
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.48,
          ),
          itemBuilder: (context, index) {
            final product = products[index];
            return _ProductCard(
              product: product,
              selected: product.shortName == widget.goal.name,
              dailyRate: dailySavingRate(widget.goal),
              onTap: () => widget.onSelectProduct(product),
            );
          },
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.selected,
    required this.dailyRate,
    required this.onTap,
  });

  final ShopProduct product;
  final bool selected;
  final double dailyRate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.paletteOf(context);
    return Material(
      color: selected ? palette.accentSoft : mutedBackground,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('product-${product.id}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${product.rank}',
                style: TextStyle(
                  color: palette.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(product.imageAsset, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      product.brand,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: palette.textSoft, fontSize: 10),
                    ),
                  ),
                  if (product.rankChange != 0)
                    Text(
                      '${product.rankChange > 0 ? '▲' : '▼'}${product.rankChange.abs()}',
                      style: TextStyle(
                        color: product.rankChange > 0
                            ? const Color(0xFFE53935)
                            : const Color(0xFF1E88E5),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.text,
                  fontSize: 11,
                  height: 1.25,
                ),
              ),
              const Spacer(),
              Text(
                '${daysToAfford(product.originalPrice, dailyRate)}일',
                style: TextStyle(
                  color: palette.textMuted,
                  fontSize: 10,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              Text(
                '${daysToAfford(product.price, dailyRate)}일',
                style: TextStyle(
                  color: palette.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: product.colors
                    .map(
                      (color) => Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(color: dividerColor),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    required this.goal,
    required this.onCancel,
    required this.onFinishHome,
    required this.onPickNextGoal,
    super.key,
  });

  final SavingsGoal goal;
  final VoidCallback onCancel;
  final VoidCallback onFinishHome;
  final VoidCallback onPickNextGoal;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _completed = false;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.paletteOf(context);
    if (_completed) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.accent,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, color: palette.text, size: 32),
              ),
              const SizedBox(height: 18),
              Text(
                '결제 완료',
                style: TextStyle(
                  color: palette.text,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.goal.name}를 샀어요. 남은 저축은 ${formatWon(widget.goal.saved > widget.goal.price ? widget.goal.saved - widget.goal.price : 0)}이에요.',
                textAlign: TextAlign.center,
                style: TextStyle(color: palette.textSoft, fontSize: 15),
              ),
              const SizedBox(height: 28),
              _PrimaryButton(label: '홈으로', onPressed: widget.onFinishHome),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: widget.onPickNextGoal,
                  style: FilledButton.styleFrom(
                    backgroundColor: mutedBackground,
                    foregroundColor: palette.textSoft,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: const Text('다음 목표 고르기'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: widget.onCancel,
                    style: TextButton.styleFrom(
                      foregroundColor: palette.textSoft,
                      padding: EdgeInsets.zero,
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('취소'),
                  ),
                ),
              ),
              Text(
                '결제',
                style: TextStyle(
                  color: palette.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    height: 26,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: palette.accentSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '데모',
                      style: TextStyle(
                        color: palette.textSoft,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  widget.goal.imageAsset,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '구매할 물건',
                    style: TextStyle(
                      color: palette.textSoft,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.goal.name,
                    style: TextStyle(
                      color: palette.text,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _PaymentSummary(
                label: '결제 금액',
                value: formatWon(widget.goal.price),
              ),
              const SizedBox(width: 8),
              _PaymentSummary(
                label: '모은 돈',
                value: formatWon(widget.goal.saved),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '결제 수단',
            style: TextStyle(
              color: palette.text,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: palette.accentSoft,
              border: Border.all(color: palette.accentBorder),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  accountLabel,
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '모은 돈으로 바로 결제해요',
                  style: TextStyle(color: palette.textSoft, fontSize: 13),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            '실제 결제는 되지 않는 연습 화면이에요',
            style: TextStyle(color: palette.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          _PrimaryButton(
            label: '${formatWon(widget.goal.price)} 결제하기',
            onPressed: () => setState(() => _completed = true),
          ),
        ],
      ),
    );
  }
}

class _PaymentSummary extends StatelessWidget {
  const _PaymentSummary({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.paletteOf(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: mutedBackground,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(color: palette.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: palette.text,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.paletteOf(context);
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: palette.accent,
          foregroundColor: palette.text,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        child: Text(label),
      ),
    );
  }
}
