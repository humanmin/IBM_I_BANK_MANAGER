import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'models.dart';

String formatNumber(int amount) {
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[index]);
  }
  return amount < 0 ? '-$buffer' : buffer.toString();
}

String formatWon(int amount) => '${formatNumber(amount)}원';

bool isMonth(DateTime date, int year, int month) =>
    date.year == year && date.month == month;

int monthSpent(List<MoneyTransaction> items, int year, int month) => items
    .where((transaction) => isMonth(transaction.date, year, month))
    .fold(0, (sum, transaction) => sum + transaction.amount);

double dailySavingRate(SavingsGoal goal) =>
    goal.savingAmount / goal.savingPeriod.days;

int remainingFor(SavingsGoal goal) => math.max(goal.price - goal.saved, 0);

int progressFor(SavingsGoal goal) {
  if (goal.price <= 0) return 100;
  return ((goal.saved / goal.price) * 100).round().clamp(0, 100);
}

int daysToGoal(SavingsGoal goal) {
  final remaining = remainingFor(goal);
  final dailyRate = dailySavingRate(goal);
  if (remaining == 0 || dailyRate <= 0) return 0;
  return (remaining / dailyRate).ceil();
}

int daysToAfford(int price, double dailyRate) {
  if (dailyRate <= 0) return 0;
  return (price / dailyRate).ceil();
}

List<MoneyTransaction> recentTransactions(
  List<MoneyTransaction> items,
  int year,
  int month,
) {
  return items.where((item) => isMonth(item.date, year, month)).toList()
    ..sort((left, right) => right.date.compareTo(left.date));
}

List<CategoryTotal> categoryTotals(
  List<MoneyTransaction> items,
  int year,
  int month,
  Map<String, CategoryInfo> metadata,
) {
  final monthItems = items
      .where((item) => isMonth(item.date, year, month))
      .toList();
  final total = monthItems.fold(0, (sum, item) => sum + item.amount);
  final amounts = <String, int>{};
  for (final item in monthItems) {
    amounts[item.category] = (amounts[item.category] ?? 0) + item.amount;
  }
  final result = amounts.entries.map((entry) {
    return CategoryTotal(
      category: entry.key,
      amount: entry.value,
      percent: total == 0 ? 0 : ((entry.value / total) * 100).round(),
      info:
          metadata[entry.key] ??
          const CategoryInfo(color: Color(0xFFC8C8C8), emoji: '•'),
    );
  }).toList();
  result.sort((left, right) => right.amount.compareTo(left.amount));
  return result;
}

SpendingStatsData spendingStats(
  List<MoneyTransaction> items,
  int thisYear,
  int thisMonth,
  int lastYear,
  int lastMonth, {
  DateTime? asOf,
}) {
  final current = items
      .where((item) => isMonth(item.date, thisYear, thisMonth))
      .toList();
  final currentSpent = current.fold(0, (sum, item) => sum + item.amount);
  final previousSpent = monthSpent(items, lastYear, lastMonth);
  final count = current.length;
  final referenceDate = asOf ?? DateTime.now();
  final elapsedDays =
      referenceDate.year == thisYear && referenceDate.month == thisMonth
      ? referenceDate.day
      : DateTime(thisYear, thisMonth + 1, 0).day;
  final byCategory = <String, int>{};
  final byMerchant = <String, int>{};
  for (final item in current) {
    byCategory[item.category] = (byCategory[item.category] ?? 0) + item.amount;
    byMerchant[item.merchant] = (byMerchant[item.merchant] ?? 0) + item.amount;
  }
  final sorted = byCategory.entries.toList()
    ..sort((left, right) => right.value.compareTo(left.value));
  final merchants = byMerchant.entries.toList()
    ..sort((left, right) => right.value.compareTo(left.value));
  return SpendingStatsData(
    thisMonthSpent: currentSpent,
    lastMonthSpent: previousSpent,
    count: count,
    averagePerTransaction: count == 0 ? 0 : (currentSpent / count).round(),
    averagePerDay: elapsedDays == 0 ? 0 : (currentSpent / elapsedDays).round(),
    topCategory: sorted.isEmpty ? null : sorted.first.key,
    topCategoryAmount: sorted.isEmpty ? 0 : sorted.first.value,
    topMerchant: merchants.isEmpty ? null : merchants.first.key,
    topMerchantAmount: merchants.isEmpty ? 0 : merchants.first.value,
  );
}

int _sumCategory(
  List<MoneyTransaction> items,
  int year,
  int month,
  String category,
) {
  return items
      .where(
        (item) => isMonth(item.date, year, month) && item.category == category,
      )
      .fold(0, (sum, item) => sum + item.amount);
}

List<Insight> insightsFor(
  List<MoneyTransaction> items,
  SavingsGoal goal, {
  DateTime? asOf,
}) {
  final referenceDate = asOf ?? DateTime.now();
  final previousMonth = DateTime(referenceDate.year, referenceDate.month - 1);
  final insights = <Insight>[];
  final deliveryThis = _sumCategory(
    items,
    referenceDate.year,
    referenceDate.month,
    '배달',
  );
  final deliveryLast = _sumCategory(
    items,
    previousMonth.year,
    previousMonth.month,
    '배달',
  );
  final cafeThis = _sumCategory(
    items,
    referenceDate.year,
    referenceDate.month,
    '카페',
  );
  final cafeLast = _sumCategory(
    items,
    previousMonth.year,
    previousMonth.month,
    '카페',
  );
  final subscriptionThis = _sumCategory(
    items,
    referenceDate.year,
    referenceDate.month,
    '구독',
  );

  final dailyRate = dailySavingRate(goal);

  if (deliveryThis > deliveryLast) {
    final extra = deliveryThis - deliveryLast;
    final faster = math.max(1, (extra / dailyRate).floor());
    insights.add(
      Insight(
        id: 'delivery',
        title: '배달이 조금 늘었어요',
        body:
            '이번 달 배달 음식이 지난달보다 ${formatWon(extra)} 더 나갔어요. 한 끼만 직접 해먹으면 ${goal.name}까지 약 $faster일 빨라질 수 있어요.',
        actionLabel: '배달 내역 확인하기',
        actionCategory: '배달',
      ),
    );
  }

  if (cafeThis > cafeLast) {
    final extra = cafeThis - cafeLast;
    final faster = math.max(1, (extra / dailyRate).floor());
    insights.add(
      Insight(
        id: 'cafe',
        title: '카페, 줄이면 목표가 당겨져요',
        body:
            '이번 달 카페에서 ${formatWon(cafeThis)}을 썼어요. 일주일에 한 번만 줄여도 ${goal.name}까지 약 $faster일 더 빨라져요.',
        actionLabel: '카페 내역 확인하기',
        actionCategory: '카페',
      ),
    );
  }

  if (subscriptionThis > 0) {
    insights.add(
      Insight(
        id: 'subscription',
        title: '구독은 잘 쓰고 있나요?',
        body:
            '매달 ${formatWon(subscriptionThis)}이 구독으로 빠져나가요. 안 보는 서비스가 있다면 정리하는 것만으로도 저축이 쉬워져요.',
        actionLabel: '구독 내역 확인하기',
        actionCategory: '구독',
      ),
    );
  }

  return insights.take(3).toList();
}

/// Calendar days that actually have spending, newest first, then oldest→newest
/// for the chart. Prefers the latest spend date plus up to 6 earlier spend days
/// so empty calendar days are skipped instead of shown as zero bars.
List<({DateTime date, int amount})> recentSpendingDays(
  List<MoneyTransaction> items, {
  int dayCount = 7,
}) {
  final amountsByDay = <DateTime, int>{};
  for (final item in items) {
    if (item.amount <= 0) continue;
    final day = DateTime(item.date.year, item.date.month, item.date.day);
    amountsByDay[day] = (amountsByDay[day] ?? 0) + item.amount;
  }
  final newestFirst = amountsByDay.keys.toList()
    ..sort((left, right) => right.compareTo(left));
  final selected = newestFirst.take(dayCount).toList()
    ..sort((left, right) => left.compareTo(right));
  return [for (final day in selected) (date: day, amount: amountsByDay[day]!)];
}
