import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';
import 'money_utils.dart';

/// Compact month summary sent to watsonx. We do **not** send every
/// transaction (merchant names, dates, raw rows) — only totals the model
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
    required this.isDemo,
    this.topCategory,
    this.lastUpdated,
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
  final bool isDemo;
  final DateTime? lastUpdated;

  /// Same fingerprint => same payload. Used so we do not call AI again
  /// until the month, totals, goal, or imported file actually change.
  String get fingerprint {
    final categoryPart = categories
        .map((item) => '${item.name}:${item.amount}')
        .join(',');
    return [
      year,
      month,
      thisMonthSpent,
      lastMonthSpent,
      count,
      lastUpdated?.millisecondsSinceEpoch ?? 0,
      goalName,
      goalPrice,
      daysToGoal,
      dailySavingAmount,
      isDemo,
      categoryPart,
    ].join('|');
  }

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
  required bool isDemo,
  DateTime? lastUpdated,
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
    isDemo: isDemo,
    lastUpdated: lastUpdated,
  );
}

/// Decides **when** the app should call watsonx for 통계 feedback.
///
/// Call it only when all of these are true:
/// 1. Data is real (imported file / 알림 동기화), not the built-in demo seed.
/// 2. The 통계 tab is actually on screen — opening Home should not spend AI quota.
/// 3. The spending snapshot changed since the last request (fingerprint).
///
/// Rebuilds, scrolling, and theme changes do not change the fingerprint,
/// so they never trigger a new request.
bool shouldRequestSpendingInsights({
  required bool isDemoData,
  required bool isSpendingTabVisible,
  required String fingerprint,
  required String? lastRequestedFingerprint,
}) {
  if (isDemoData) return false;
  if (!isSpendingTabVisible) return false;
  if (fingerprint == lastRequestedFingerprint) return false;
  return true;
}

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
  Future<List<Insight>>? _inFlight;
  String? _inFlightFingerprint;

  @override
  Future<List<Insight>> fetch(SpendingInsightRequest request) {
    if (_inFlight != null && _inFlightFingerprint == request.fingerprint) {
      return _inFlight!;
    }

    final future = _fetch(request);
    _inFlight = future;
    _inFlightFingerprint = request.fingerprint;
    return future.whenComplete(() {
      if (_inFlightFingerprint == request.fingerprint) {
        _inFlight = null;
        _inFlightFingerprint = null;
      }
    });
  }

  Future<List<Insight>> _fetch(SpendingInsightRequest request) async {
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
          .timeout(const Duration(seconds: 25));
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
