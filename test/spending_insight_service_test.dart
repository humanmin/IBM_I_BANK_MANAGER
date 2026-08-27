import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ibm_money_app/models.dart';
import 'package:ibm_money_app/spending_insight_service.dart';

void main() {
  test(
    'requests AI only for real data on the spending tab when data changed',
    () {
      const fingerprint = 'month-a';
      expect(
        shouldRequestSpendingInsights(
          isDemoData: true,
          isSpendingTabVisible: true,
          fingerprint: fingerprint,
          lastRequestedFingerprint: null,
        ),
        isFalse,
      );
      expect(
        shouldRequestSpendingInsights(
          isDemoData: false,
          isSpendingTabVisible: false,
          fingerprint: fingerprint,
          lastRequestedFingerprint: null,
        ),
        isFalse,
      );
      expect(
        shouldRequestSpendingInsights(
          isDemoData: false,
          isSpendingTabVisible: true,
          fingerprint: fingerprint,
          lastRequestedFingerprint: fingerprint,
        ),
        isFalse,
      );
      expect(
        shouldRequestSpendingInsights(
          isDemoData: false,
          isSpendingTabVisible: true,
          fingerprint: fingerprint,
          lastRequestedFingerprint: null,
        ),
        isTrue,
      );
    },
  );

  test('fingerprint changes when monthly totals change', () {
    const goal = SavingsGoal(
      name: 'AirPods',
      imageAsset: null,
      price: 299000,
      saved: 100000,
      savingAmount: 10000,
      savingPeriod: SavingPeriod.daily,
    );
    final quietMonth = buildSpendingInsightRequest(
      transactions: [
        MoneyTransaction(
          id: '1',
          merchant: '카페',
          category: '카페',
          amount: 4500,
          date: DateTime(2026, 8, 2),
        ),
      ],
      goal: goal,
      isDemo: false,
      asOf: DateTime(2026, 8, 27),
    );
    final busyMonth = buildSpendingInsightRequest(
      transactions: [
        MoneyTransaction(
          id: '1',
          merchant: '카페',
          category: '카페',
          amount: 4500,
          date: DateTime(2026, 8, 2),
        ),
        MoneyTransaction(
          id: '2',
          merchant: '배달',
          category: '배달',
          amount: 22000,
          date: DateTime(2026, 8, 3),
        ),
      ],
      goal: goal,
      isDemo: false,
      asOf: DateTime(2026, 8, 27),
    );

    expect(quietMonth.fingerprint, isNot(busyMonth.fingerprint));
    expect(quietMonth.toJson()['thisMonthSpent'], 4500);
    expect(busyMonth.toJson()['thisMonthSpent'], 26500);
  });

  test('insight service posts a summary and parses insights', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/insights');
      expect(request.body, contains('thisMonthSpent'));
      expect(request.body, isNot(contains('스타벅스역삼')));
      return http.Response(
        '{"insights":[{"id":"delivery","title":"배달이 늘었어요","body":"한 끼만 줄여 보세요.","actionLabel":"배달 내역 확인하기","actionCategory":"배달"}]}',
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final service = SpendingInsightService(
      client: client,
      baseUrl: 'https://api.example.com',
    );
    addTearDown(service.close);

    final insights = await service.fetch(
      const SpendingInsightRequest(
        year: 2026,
        month: 8,
        thisMonthSpent: 50000,
        lastMonthSpent: 30000,
        count: 4,
        averagePerDay: 2000,
        categories: [(name: '배달', amount: 40000)],
        topCategory: '배달',
        goalName: 'AirPods',
        goalPrice: 299000,
        daysToGoal: 20,
        dailySavingAmount: 10000,
        isDemo: false,
      ),
    );

    expect(insights, hasLength(1));
    expect(insights.single.title, '배달이 늘었어요');
    expect(insights.single.actionCategory, '배달');
  });
}
