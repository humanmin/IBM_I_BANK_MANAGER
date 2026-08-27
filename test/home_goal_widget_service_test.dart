import 'package:flutter_test/flutter_test.dart';
import 'package:ibm_money_app/home_goal_widget_service.dart';
import 'package:ibm_money_app/models.dart';

void main() {
  const goal = SavingsGoal(
    name: '독거미 키보드',
    imageAsset: null,
    imageUrl: 'https://example.com/keyboard.jpg',
    price: 200000,
    saved: 80000,
    savingAmount: 5000,
    savingPeriod: SavingPeriod.daily,
  );

  test('builds a stable D-Day snapshot for the selected goal', () {
    final snapshot = buildGoalWidgetSnapshot(
      goal: goal,
      hasSelectedGoal: true,
      now: DateTime(2026, 8, 27, 23, 30),
    );

    expect(snapshot.hasGoal, isTrue);
    expect(snapshot.name, '독거미 키보드');
    expect(snapshot.targetDate, DateTime(2026, 9, 20));
    expect(snapshot.dDayLabel(DateTime(2026, 8, 27)), 'D-24');
    expect(snapshot.dDayLabel(DateTime(2026, 9, 20)), 'D-DAY');
  });

  test('builds an empty widget state before a goal is selected', () {
    final snapshot = buildGoalWidgetSnapshot(
      goal: goal,
      hasSelectedGoal: false,
    );

    expect(snapshot.hasGoal, isFalse);
    expect(snapshot.imageProvider, isNull);
    expect(snapshot.dDayLabel(DateTime(2026, 8, 27)), '목표 없음');
  });
}
