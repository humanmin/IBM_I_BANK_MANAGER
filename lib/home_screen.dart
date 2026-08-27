import 'package:flutter/material.dart';

import 'app_widgets.dart';
import 'models.dart';
import 'money_utils.dart';
import 'seed_data.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.currentUser,
    required this.goal,
    required this.unreadCount,
    required this.transactions,
    required this.onOpenNotifications,
    required this.onPeriodChanged,
    required this.onAmountChanged,
    required this.onSavePressed,
    required this.onOpenSpending,
    required this.onOpenShop,
    required this.onBuy,
    this.hasSelectedGoal = false,
    super.key,
  });

  final AppUser currentUser;
  final SavingsGoal goal;
  final int unreadCount;
  final List<MoneyTransaction> transactions;
  final VoidCallback onOpenNotifications;
  final ValueChanged<SavingPeriod> onPeriodChanged;
  final ValueChanged<int> onAmountChanged;
  final VoidCallback onSavePressed;
  final VoidCallback onOpenSpending;
  final ValueChanged<BuildContext> onOpenShop;
  final VoidCallback onBuy;
  final bool hasSelectedGoal;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const PageStorageKey('home-scroll'),
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      child: Column(
        children: [
          _DashboardHeader(
            currentUser: currentUser,
            unreadCount: unreadCount,
            onOpenNotifications: onOpenNotifications,
          ),
          const SizedBox(height: 22),
          if (currentUser.isFirstTime)
            _FirstTimeUserHome(
              userName: currentUser.displayName ?? '사용자',
              goal: goal,
              hasSelectedGoal: hasSelectedGoal,
              hasAccountData: transactions.isNotEmpty,
              onOpenShop: () => onOpenShop(context),
              onOpenSpending: onOpenSpending,
              onPeriodChanged: onPeriodChanged,
              onAmountChanged: onAmountChanged,
              onSavePressed: onSavePressed,
              onBuy: onBuy,
            )
          else ...[
            SavingPlanCard(
              goal: goal,
              onPeriodChanged: onPeriodChanged,
              onAmountChanged: onAmountChanged,
              onSavePressed: onSavePressed,
            ),
            const SizedBox(height: 16),
            _GoalCard(
              goal: goal,
              onBuy: onBuy,
              onOpenShop: () => onOpenShop(context),
            ),
          ],
        ],
      ),
    );
  }
}

class _FirstTimeUserHome extends StatelessWidget {
  const _FirstTimeUserHome({
    required this.userName,
    required this.goal,
    required this.hasSelectedGoal,
    required this.hasAccountData,
    required this.onOpenShop,
    required this.onOpenSpending,
    required this.onPeriodChanged,
    required this.onAmountChanged,
    required this.onSavePressed,
    required this.onBuy,
  });

  final String userName;
  final SavingsGoal goal;
  final bool hasSelectedGoal;
  final bool hasAccountData;
  final VoidCallback onOpenShop;
  final VoidCallback onOpenSpending;
  final ValueChanged<SavingPeriod> onPeriodChanged;
  final ValueChanged<int> onAmountChanged;
  final VoidCallback onSavePressed;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.paletteOf(context);
    final savingPlanCard = SavingPlanCard(
      key: const Key('first-time-saving-plan'),
      goal: goal,
      onPeriodChanged: onPeriodChanged,
      onAmountChanged: onAmountChanged,
      onSavePressed: onSavePressed,
    );
    return Column(
      key: const Key('first-time-user-home'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        savingPlanCard,
        const SizedBox(height: 16),
        if (hasSelectedGoal)
          _GoalCard(goal: goal, onBuy: onBuy, onOpenShop: onOpenShop)
        else
          SoftCard(
            color: palette.accentSoft,
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surface.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '처음 시작',
                    style: TextStyle(
                      color: palette.textSoft,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  '$userName님, 반가워요!',
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '갖고 싶은 상품을 고르면 목표 금액과\n저축 계획을 함께 만들어 드릴게요.',
                  style: TextStyle(
                    color: palette.textSoft,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key('first-goal-button'),
                    onPressed: onOpenShop,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('첫 저축 목표 만들기'),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        SoftCard(
          color: mutedBackground,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      hasAccountData
                          ? Icons.check_circle_outline_rounded
                          : Icons.account_balance_wallet_outlined,
                      color: palette.text,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasAccountData ? '소비 데이터 연결 완료' : '아직 소비 데이터가 없어요',
                          style: TextStyle(
                            color: palette.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasAccountData
                              ? '통계 탭에서 내 소비 습관을 확인해 보세요.'
                              : '거래내역을 불러오면 자동으로 분석해요.',
                          style: TextStyle(
                            color: palette.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const _OnboardingStep(number: '1', label: '갖고 싶은 상품 고르기'),
              const SizedBox(height: 10),
              const _OnboardingStep(number: '2', label: '나만의 저축 계획 정하기'),
              const SizedBox(height: 10),
              const _OnboardingStep(number: '3', label: '소비 내역 불러오기'),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const Key('first-import-button'),
                  onPressed: onOpenSpending,
                  icon: const Icon(Icons.file_open_outlined, size: 19),
                  label: Text(hasAccountData ? '소비 통계 확인하기' : '소비 데이터 가져오기'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OnboardingStep extends StatelessWidget {
  const _OnboardingStep({required this.number, required this.label});

  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.paletteOf(context);
    return Row(
      children: [
        Container(
          width: 25,
          height: 25,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: palette.accentSoft,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: TextStyle(
              color: palette.textSoft,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: palette.textSoft,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.currentUser,
    required this.unreadCount,
    required this.onOpenNotifications,
  });

  final AppUser currentUser;
  final int unreadCount;
  final VoidCallback onOpenNotifications;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.paletteOf(context);
    return Row(
      children: [
        Text(
          currentUser.displayName ?? currentUser.email ?? '사용자',
          style: TextStyle(
            color: palette.text,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          key: const Key('account-label'),
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: mutedBackground,
            borderRadius: BorderRadius.all(Radius.circular(999)),
          ),
          child: Text(
            accountLabel,
            style: TextStyle(
              color: palette.textSoft,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Spacer(),
        Stack(
          clipBehavior: Clip.none,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onOpenNotifications,
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: mutedBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_none,
                  color: palette.text,
                  size: 21,
                ),
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                top: 2,
                right: 1,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 16),
                  height: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: palette.accent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$unreadCount',
                    style: TextStyle(
                      color: palette.text,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 10),
        _ProfileAvatar(
          imageUrl: currentUser.photoUrl,
          useDemoAsset: !currentUser.isFirstTime,
        ),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.imageUrl, required this.useDemoAsset});

  final String? imageUrl;
  final bool useDemoAsset;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.paletteOf(context);
    final fallback = Container(
      width: 40,
      height: 40,
      color: palette.accentSoft,
      alignment: Alignment.center,
      child: Icon(Icons.person_rounded, color: palette.textSoft, size: 23),
    );
    final url = imageUrl;
    return ClipOval(
      child: url != null && url.isNotEmpty
          ? Image.network(
              url,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
            )
          : useDemoAsset
          ? Image.asset(
              'assets/images/avatar.png',
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            )
          : fallback,
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.onBuy,
    required this.onOpenShop,
  });

  final SavingsGoal goal;
  final VoidCallback onBuy;
  final VoidCallback onOpenShop;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.paletteOf(context);
    final remaining = remainingFor(goal);
    final progress = progressFor(goal);
    final days = daysToGoal(goal);
    return SoftCard(
      color: palette.accentSoft,
      onTap: onOpenShop,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GoalImage(imageAsset: goal.imageAsset, imageUrl: goal.imageUrl),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '갖고 싶은 것',
                      style: TextStyle(
                        color: palette.textSoft,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      goal.name,
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
              Icon(
                Icons.chevron_right,
                key: const Key('open-shop-button'),
                color: palette.textSoft,
                size: 22,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _GoalStat(label: '가격', value: formatWon(goal.price)),
              const SizedBox(width: 8),
              _GoalStat(label: '모은 돈', value: formatWon(goal.saved)),
              const SizedBox(width: 8),
              _GoalStat(label: '남은 금액', value: formatWon(remaining)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '진행률 $progress%',
                style: TextStyle(
                  color: palette.textSoft,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${goal.savingPeriod.label} ${formatWon(goal.savingAmount)}',
                style: TextStyle(
                  color: palette.textSoft,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 10,
              backgroundColor: palette.accentTrack,
              valueColor: AlwaysStoppedAnimation(palette.accent),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('goal-action'),
              onPressed: days == 0 ? onBuy : null,
              style: FilledButton.styleFrom(
                backgroundColor: palette.accent,
                disabledBackgroundColor: palette.accent,
                disabledForegroundColor: palette.text,
                foregroundColor: palette.text,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: Text(days > 0 ? '$days일 후면 살 수 있어요!' : '지금 사기'),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalStat extends StatelessWidget {
  const _GoalStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.paletteOf(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(color: palette.textMuted, fontSize: 11),
            ),
            const SizedBox(height: 4),
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
