import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';
import 'money_utils.dart';

/// Compact month summary sent to watsonx. We do **not** send every
/// transaction (merchant names, dates, raw rows) — only the totals the model
/// needs to write the 통계 "이번 달 한마디" cards.
class SpendingInsightRequest {
  const SpendingInsightRequest({
    required this.year,
    required this.month,
    required this.thisMonthSpent,
    required this.lastMonthSpent,
    required this.count,
    required this.averagePerDay,
    required this.categories,
    required this.goalName,
    required this.goalPrice,
    required this.daysToGoal,
    required this.dailySavingAmount,
    this.topCategory,
  });

  final int year;
  final int month;
  final int thisMonthSpent;
  final int lastMonthSpent;
  final int count;
  final int averagePerDay;
  final List<({String name, int amount})> categories;
  final String? topCategory;
  final String goalName;
  final int goalPrice;
  final int daysToGoal;
  final int dailySavingAmount;

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'month': month,
      'thisMonthSpent': thisMonthSpent,
      'lastMonthSpent': lastMonthSpent,
      'count': count,
      'averagePerDay': averagePerDay,
      'topCategory': topCategory,
      'categories': [
        for (final item in categories)
          {'name': item.name, 'amount': item.amount},
      ],
      'goal': {
        'name': goalName,
        'price': goalPrice,
        'daysToGoal': daysToGoal,
        'dailySavingAmount': dailySavingAmount,
      },
    };
  }
}

SpendingInsightRequest buildSpendingInsightRequest({
  required List<MoneyTransaction> transactions,
  required SavingsGoal goal,
  DateTime? asOf,
}) {
  final now = asOf ?? DateTime.now();
  final previousMonth = DateTime(now.year, now.month - 1);
  final stats = spendingStats(
    transactions,
    now.year,
    now.month,
    previousMonth.year,
    previousMonth.month,
    asOf: now,
  );
  final totals = <String, int>{};
  for (final item in transactions) {
    if (!isMonth(item.date, now.year, now.month)) continue;
    totals[item.category] = (totals[item.category] ?? 0) + item.amount;
  }
  final ranked = totals.entries.toList()
    ..sort((left, right) => right.value.compareTo(left.value));

  return SpendingInsightRequest(
    year: now.year,
    month: now.month,
    thisMonthSpent: stats.thisMonthSpent,
    lastMonthSpent: stats.lastMonthSpent,
    count: stats.count,
    averagePerDay: stats.averagePerDay,
    topCategory: stats.topCategory,
    categories: [
      for (final entry in ranked.take(8))
        (name: entry.key, amount: entry.value),
    ],
    goalName: goal.name,
    goalPrice: goal.price,
    daysToGoal: daysToGoal(goal),
    dailySavingAmount: goal.savingAmount,
  );
}

/// The AI runs only when the user taps the button, so the single rule is:
/// don't start a second request while one is already running.
bool shouldRequestSpendingInsights({required bool isLoading}) => !isLoading;

abstract interface class SpendingInsightGateway {
  Future<List<Insight>> fetch(SpendingInsightRequest request);
}

class SpendingInsightException implements Exception {
  const SpendingInsightException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SpendingInsightService implements SpendingInsightGateway {
  SpendingInsightService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? _configuredBaseUrl;

  static const _configuredBaseUrl = String.fromEnvironment(
    'PRODUCT_SEARCH_API_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  final http.Client _client;
  final String _baseUrl;

  @override
  Future<List<Insight>> fetch(SpendingInsightRequest request) async {
    final root = _baseUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$root/api/insights');

    try {
      final response = await _client
          .post(
            uri,
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 30));
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode != 200) {
        final message = body is Map<String, dynamic>
            ? body['error'] as String?
            : null;
        throw SpendingInsightException(message ?? '소비 피드백을 만들지 못했어요.');
      }
      if (body is! Map<String, dynamic> || body['insights'] is! List) {
        throw const SpendingInsightException('피드백 형식을 확인할 수 없어요.');
      }
      return (body['insights'] as List)
          .whereType<Map<String, dynamic>>()
          .map(Insight.fromJson)
          .where((item) => item.title.isNotEmpty && item.body.isNotEmpty)
          .take(3)
          .toList();
    } on SpendingInsightException {
      rethrow;
    } on FormatException {
      throw const SpendingInsightException('피드백 서버 응답을 읽을 수 없어요.');
    } catch (_) {
      throw const SpendingInsightException(
        '피드백 서버에 연결할 수 없어요. PC 서버 실행과 휴대폰 연결을 확인해 주세요.',
      );
    }
  }

  void close() => _client.close();
}
