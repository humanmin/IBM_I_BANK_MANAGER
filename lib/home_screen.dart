import 'package:flutter/material.dart';

import 'app_widgets.dart';
import 'models.dart';
import 'money_utils.dart';
import 'seed_data.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.goal,
    required this.themeChoice,
    required this.unreadCount,
    required this.onThemeChanged,
    required this.onOpenNotifications,
    required this.onPeriodChanged,
    required this.onAmountChanged,
    required this.onOpenSpending,
    required this.onBuy,
    super.key,
  });

  final SavingsGoal goal;
  final ThemeChoice themeChoice;
  final int unreadCount;
  final ValueChanged<ThemeChoice> onThemeChanged;
  final VoidCallback onOpenNotifications;
  final ValueChanged<SavingPeriod> onPeriodChanged;
  final ValueChanged<int> onAmountChanged;
  final VoidCallback onOpenSpending;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.paletteOf(context);
    return SingleChildScrollView(
      key: const PageStorageKey('home-scroll'),
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      child: Column(
        children: [
          _DashboardHeader(
            themeChoice: themeChoice,
            unreadCount: unreadCount,
            onThemeChanged: onThemeChanged,
            onOpenNotifications: onOpenNotifications,
          ),
          const SizedBox(height: 22),
          SavingPlanCard(
            goal: goal,
            onPeriodChanged: onPeriodChanged,
            onAmountChanged: onAmountChanged,
          ),
          const SizedBox(height: 16),
          _GoalCard(goal: goal, onBuy: onBuy),
          const SizedBox(height: 16),
          SoftCard(
            color: palette.accentSoft,
            onTap: onOpenSpending,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '남은 돈',
                  style: TextStyle(
                    color: palette.textSoft,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  formatWon(remainingBalance),
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '이번 달 지출 ${formatWon(monthSpent(transactions, 2026, 8))}',
                      style: TextStyle(color: palette.textSoft, fontSize: 12),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right,
                      color: palette.textSoft,
                      size: 18,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.themeChoice,
    required this.unreadCount,
    required this.onThemeChanged,
    required this.onOpenNotifications,
  });

  final ThemeChoice themeChoice;
  final int unreadCount;
  final ValueChanged<ThemeChoice> onThemeChanged;
  final VoidCallback onOpenNotifications;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.paletteOf(context);
    const themeColors = <ThemeChoice, Color>{
      ThemeChoice.yellow: Color(0xFFFDE932),
      ThemeChoice.navy: Color(0xFF7D8FAD),
      ThemeChoice.green: Color(0xFF9FC4A6),
    };
    return Row(
      children: [
        Text(
          userName,
          style: TextStyle(
            color: palette.text,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: 26,
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
        Row(
          mainAxisSize: MainAxisSize.min,
          children: ThemeChoice.values.map((choice) {
            final selected = choice == themeChoice;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Semantics(
                label: '${choice.name} 테마',
                selected: selected,
                button: true,
                child: GestureDetector(
                  onTap: () => onThemeChanged(choice),
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: themeColors[choice],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: selected ? 0.32 : 0.15,
                          ),
                          spreadRadius: selected ? 1.5 : 0.5,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
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
        ClipOval(
          child: Image.asset(
            'assets/images/avatar.png',
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal, required this.onBuy});

  final SavingsGoal goal;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.paletteOf(context);
    final remaining = remainingFor(goal);
    final progress = progressFor(goal);
    final days = daysToGoal(goal);
    return SoftCard(
      color: palette.accentSoft,
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  goal.imageAsset,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                ),
              ),
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
          color: Colors.white,
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
