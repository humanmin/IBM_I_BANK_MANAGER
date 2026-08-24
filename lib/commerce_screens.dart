import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_widgets.dart';
import 'models.dart';
import 'money_utils.dart';
import 'seed_data.dart';

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({
    required this.goal,
    required this.wishItems,
    required this.onPeriodChanged,
    required this.onAmountChanged,
    required this.onAddWishItem,
    required this.onUpdateWishItem,
    required this.onDeleteWishItem,
    required this.onSelectWishItem,
    super.key,
  });

  final SavingsGoal goal;
  final List<WishItem> wishItems;
  final ValueChanged<SavingPeriod> onPeriodChanged;
  final ValueChanged<int> onAmountChanged;
  final ValueChanged<WishItem> onAddWishItem;
  final ValueChanged<WishItem> onUpdateWishItem;
  final ValueChanged<WishItem> onDeleteWishItem;
  final ValueChanged<WishItem> onSelectWishItem;

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  Future<void> _openEditor([WishItem? item]) async {
    final palette = ThemeScope.paletteOf(context);
    final result = await showModalBottomSheet<WishItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => ThemeScope(
        palette: palette,
        child: _WishItemEditor(item: item),
      ),
    );
    if (result == null || !mounted) return;
    if (item == null) {
      widget.onAddWishItem(result);
    } else {
      widget.onUpdateWishItem(result);
    }
  }

  Future<void> _confirmDelete(WishItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('목표를 삭제할까요?'),
        content: Text('${item.name}을 위시리스트에서 삭제해요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.onDeleteWishItem(item);
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.paletteOf(context);
    return ListView(
      key: const PageStorageKey('shop-scroll'),
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      children: [
        Text(
          '내 위시리스트',
          style: TextStyle(
            color: palette.text,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '갖고 싶은 물건과 가격을 직접 등록해요',
          style: TextStyle(color: palette.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.accentSoft,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              GoalImage(
                imageAsset: widget.goal.imageAsset,
                size: 56,
                radius: 16,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '현재 저축 목표',
                      style: TextStyle(color: palette.textSoft, fontSize: 12),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.goal.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      formatWon(widget.goal.price),
                      style: TextStyle(color: palette.textSoft, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const Key('add-wish-button'),
            onPressed: _openEditor,
            icon: const Icon(Icons.add_rounded),
            label: const Text('갖고 싶은 것 추가'),
            style: FilledButton.styleFrom(
              backgroundColor: palette.accent,
              foregroundColor: palette.text,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: mutedBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                color: palette.textMuted,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI로 가격 자동 찾기',
                      style: TextStyle(
                        color: palette.textSoft,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '후순위 기능 · 준비 중',
                      style: TextStyle(color: palette.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.lock_clock_outlined,
                color: Color(0xFFAAAAAA),
                size: 18,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SavingPlanCard(
          goal: widget.goal,
          compact: true,
          onPeriodChanged: widget.onPeriodChanged,
          onAmountChanged: widget.onAmountChanged,
        ),
        const SizedBox(height: 24),
        Text(
          '내가 등록한 목표',
          style: TextStyle(
            color: palette.text,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        if (widget.wishItems.isEmpty)
          Container(
            padding: const EdgeInsets.all(22),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: mutedBackground,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Icon(Icons.favorite_border_rounded, color: palette.textMuted),
                const SizedBox(height: 8),
                Text(
                  '아직 등록한 목표가 없어요',
                  style: TextStyle(
                    color: palette.textSoft,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          )
        else
          ...widget.wishItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _WishItemCard(
                item: item,
                selected:
                    widget.goal.imageAsset == null &&
                    widget.goal.name == item.name &&
                    widget.goal.price == item.price,
                dailyRate: dailySavingRate(widget.goal),
                onSelect: () => widget.onSelectWishItem(item),
                onEdit: () => _openEditor(item),
                onDelete: () => _confirmDelete(item),
              ),
            ),
          ),
      ],
    );
  }
}

class _WishItemCard extends StatelessWidget {
  const _WishItemCard({
    required this.item,
    required this.selected,
    required this.dailyRate,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  final WishItem item;
  final bool selected;
  final double dailyRate;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.paletteOf(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        color: selected ? palette.accentSoft : mutedBackground,
        borderRadius: BorderRadius.circular(18),
        border: selected ? Border.all(color: palette.accentBorder) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(Icons.card_giftcard_rounded, color: palette.textSoft),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              key: Key('wish-${item.id}'),
              onTap: onSelect,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${formatWon(item.price)} · ${daysToAfford(item.price, dailyRate)}일 예상',
                    style: TextStyle(color: palette.textSoft, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            key: Key('edit-wish-${item.id}'),
            tooltip: '수정',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 19),
            color: palette.textMuted,
          ),
          IconButton(
            key: Key('delete-wish-${item.id}'),
            tooltip: '삭제',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded, size: 19),
            color: palette.textMuted,
          ),
        ],
      ),
    );
  }
}

class _WishItemEditor extends StatefulWidget {
  const _WishItemEditor({this.item});

  final WishItem? item;

  @override
  State<_WishItemEditor> createState() => _WishItemEditorState();
}

class _WishItemEditorState extends State<_WishItemEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _priceController = TextEditingController(
      text: widget.item == null ? '' : '${widget.item!.price}',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      WishItem(
        id: widget.item?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        price: int.parse(_priceController.text),
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
            Text(
              widget.item == null ? '갖고 싶은 것 추가' : '목표 수정',
              style: TextStyle(
                color: palette.text,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '물건 이름과 예상 가격을 입력해 주세요.',
              style: TextStyle(color: palette.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: const Key('wish-name-field'),
              controller: _nameController,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: '물건 이름',
                hintText: '예: 무선 키보드',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? '물건 이름을 입력해 주세요'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('wish-price-field'),
              controller: _priceController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onFieldSubmitted: (_) => _save(),
              decoration: const InputDecoration(
                labelText: '예상 가격',
                suffixText: '원',
                hintText: '예: 120000',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final price = int.tryParse(value ?? '');
                return price == null || price < 1 ? '1원 이상의 가격을 입력해 주세요' : null;
              },
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('save-wish-button'),
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: palette.accent,
                  foregroundColor: palette.text,
                  minimumSize: const Size.fromHeight(52),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
                child: const Text('저장하고 목표로 설정'),
              ),
            ),
          ],
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
              GoalImage(imageAsset: widget.goal.imageAsset),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ],
                ),
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
