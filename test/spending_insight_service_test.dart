import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ibm_money_app/models.dart';
import 'package:ibm_money_app/spending_insight_service.dart';

void main() {
  test(
    'requests AI only when the user taps and a call is not already running',
    () {
      expect(shouldRequestSpendingInsights(isLoading: true), isFalse);
      expect(shouldRequestSpendingInsights(isLoading: false), isTrue);
    },
  );

  test('summary contains monthly totals but no merchant names', () {
    const goal = SavingsGoal(
      name: 'AirPods',
      imageAsset: null,
      price: 299000,
      saved: 100000,
      savingAmount: 10000,
      savingPeriod: SavingPeriod.daily,
    );
    final request = buildSpendingInsightRequest(
      transactions: [
        MoneyTransaction(
          id: '1',
          merchant: '스타벅스역삼',
          category: '카페',
          amount: 4500,
          date: DateTime(2026, 8, 2),
        ),
        MoneyTransaction(
          id: '2',
          merchant: '배민',
          category: '배달',
          amount: 22000,
          date: DateTime(2026, 8, 3),
        ),
        MoneyTransaction(
          id: '3',
          merchant: '지난달 거래',
          category: '카페',
          amount: 9000,
          date: DateTime(2026, 7, 20),
        ),
      ],
      goal: goal,
      asOf: DateTime(2026, 8, 27),
    );
    final json = request.toJson();

    expect(json['thisMonthSpent'], 26500);
    expect(json['lastMonthSpent'], 9000);
    expect(json['topCategory'], '배달');
    expect(json.toString(), isNot(contains('스타벅스역삼')));
    expect((json['goal'] as Map<String, dynamic>)['name'], 'AirPods');
  });

  test('insight service posts a summary and parses insights', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/insights');
      expect(request.body, contains('thisMonthSpent'));
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
      ),
    );

    expect(insights, hasLength(1));
    expect(insights.single.title, '배달이 늘었어요');
    expect(insights.single.actionCategory, '배달');
  });

  test('insight service surfaces the server error message', () async {
    final client = MockClient((request) async {
      return http.Response(
        '{"error":"WATSONX_MODEL_ID / WATSONX_PROJECT_ID 설정이 필요합니다."}',
        503,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final service = SpendingInsightService(
      client: client,
      baseUrl: 'https://api.example.com',
    );
    addTearDown(service.close);

    await expectLater(
      service.fetch(
        const SpendingInsightRequest(
          year: 2026,
          month: 8,
          thisMonthSpent: 50000,
          lastMonthSpent: 30000,
          count: 4,
          averagePerDay: 2000,
          categories: [],
          goalName: 'AirPods',
          goalPrice: 299000,
          daysToGoal: 20,
          dailySavingAmount: 10000,
        ),
      ),
      throwsA(
        isA<SpendingInsightException>().having(
          (error) => error.message,
          'message',
          contains('WATSONX_MODEL_ID'),
        ),
      ),
    );
  });

  test('insight service explains a stale server route', () async {
    final client = MockClient((request) async {
      return http.Response(
        '{"error":"요청한 API를 찾을 수 없습니다."}',
        404,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final service = SpendingInsightService(
      client: client,
      baseUrl: 'https://api.example.com',
    );
    addTearDown(service.close);

    await expectLater(
      service.fetch(
        const SpendingInsightRequest(
          year: 2026,
          month: 8,
          thisMonthSpent: 50000,
          lastMonthSpent: 30000,
          count: 4,
          averagePerDay: 2000,
          categories: [],
          goalName: 'AirPods',
          goalPrice: 299000,
          daysToGoal: 20,
          dailySavingAmount: 10000,
        ),
      ),
      throwsA(
        isA<SpendingInsightException>().having(
          (error) => error.message,
          'message',
          contains('예전 버전의 서버'),
        ),
      ),
    );
  });
}
