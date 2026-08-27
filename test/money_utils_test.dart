import 'package:flutter_test/flutter_test.dart';
import 'package:ibm_money_app/models.dart';
import 'package:ibm_money_app/money_utils.dart';

MoneyTransaction _tx(int day, int amount, {int month = 8}) {
  return MoneyTransaction(
    id: '$month-$day-$amount',
    merchant: '가게',
    category: '식비',
    amount: amount,
    date: DateTime(2026, month, day, 12),
  );
}

void main() {
  test(
    'recentSpendingDays takes the 7 newest days with spend, not empty days',
    () {
      final days = recentSpendingDays([
        _tx(20, 1000),
        _tx(19, 2000),
        _tx(15, 3000),
        _tx(14, 4000),
        _tx(13, 5000),
        _tx(12, 6000),
        _tx(9, 7000),
        _tx(8, 8000),
      ]);

      expect(days.map((day) => day.date.day).toList(), [
        9,
        12,
        13,
        14,
        15,
        19,
        20,
      ]);
      expect(days.last.amount, 1000);
    },
  );

  test('recentSpendingDays sums same-day transactions', () {
    final days = recentSpendingDays([
      _tx(20, 1000),
      _tx(20, 500),
      _tx(19, 2000),
    ]);

    expect(days, hasLength(2));
    expect(days.last.amount, 1500);
  });
}
