import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';
import 'models.dart';
import 'seed_data.dart';

abstract interface class EventGateway {
  Future<PointBalance> fetchPoints();
  Future<PointBalance> checkIn();
  Future<List<SurveyEvent>> fetchSurveys();
  Future<int> submitSurveyResponse(
    String surveyId,
    Map<String, String> answers,
  );
  Future<ReferralInfo> fetchReferralInfo();
  Future<List<RewardCoupon>> fetchRewards();
  Future<void> redeemReward(String rewardId);

  /// 지금 데모 데이터로 동작 중인지 여부. 화면에 "예시 데이터" 배지를 띄우는 데 사용.
  bool get isDemoMode;
}

class EventException implements Exception {
  const EventException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// 실제 서버(Firebase Auth + Firestore)를 우선 시도하고,
/// 로그인이 안 됐거나 서버/Firebase가 아직 준비되지 않았으면 조용히 데모 데이터로 전환합니다.
///
/// 해커톤 데모 특성상 "발표 당일 백엔드가 100% 살아있지 않아도 화면은 항상 보여줘야 한다"는
/// 요구에 맞춘 설계입니다. 실제 백엔드 연동 코드(HTTP 호출, Firebase 인증 헤더 등)는
/// 그대로 존재하므로, 서버가 준비되는 순간 자동으로 실데이터로 전환됩니다 —
/// 데모 모드는 예외 상황의 폴백이지, 별도로 분기해서 관리하는 모드가 아닙니다.
class EventService implements EventGateway {
  EventService({
    required AuthGateway auth,
    http.Client? client,
    String? baseUrl,
  }) : _auth = auth,
       _client = client ?? http.Client(),
       _baseUrl = baseUrl ?? _configuredBaseUrl;

  static const _configuredBaseUrl = String.fromEnvironment(
    'PRODUCT_SEARCH_API_URL', // 기존 서버 주소 설정을 그대로 재사용
    defaultValue: 'http://10.0.2.2:8080',
  );

  final AuthGateway _auth;
  final http.Client _client;
  final String _baseUrl;

  bool _demoMode = false;
  @override
  bool get isDemoMode => _demoMode;

  // 데모 모드일 때 로컬에서만 유지하는 상태 (앱 재시작하면 초기화됨 — 데모용이므로 충분)
  PointBalance _demoPoints = demoPointBalance;
  final List<SurveyEvent> _demoSurveys = List.of(demoSurveys);
  final List<RewardCoupon> _demoRewards = List.of(demoRewards);

  Future<Map<String, String>?> _tryAuthHeaders() async {
    try {
      final token = await _auth.currentIdToken();
      if (token == null) return null;
      return {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
    } catch (_) {
      // Firebase 미초기화 등 — 인증 자체가 아직 준비 안 된 상태
      return null;
    }
  }

  Uri _uri(String path) =>
      Uri.parse('${_baseUrl.replaceAll(RegExp(r'/+$'), '')}$path');

  Map<String, dynamic> _decode(http.Response response) =>
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

  @override
  Future<PointBalance> fetchPoints() async {
    final headers = await _tryAuthHeaders();
    if (headers == null) return _enterDemoMode<PointBalance>(_demoPoints);
    try {
      final response = await _client
          .get(_uri('/api/events/points'), headers: headers)
          .timeout(const Duration(seconds: 6));
      final body = _decode(response);
      if (response.statusCode != 200) {
        return _enterDemoMode<PointBalance>(_demoPoints);
      }
      _demoMode = false;
      return PointBalance.fromJson(body);
    } catch (_) {
      return _enterDemoMode<PointBalance>(_demoPoints);
    }
  }

  @override
  Future<PointBalance> checkIn() async {
    final headers = await _tryAuthHeaders();
    if (headers == null) return _demoCheckIn();
    try {
      final response = await _client
          .post(_uri('/api/events/checkin'), headers: headers)
          .timeout(const Duration(seconds: 6));
      final body = _decode(response);
      if (response.statusCode == 409) {
        throw EventException(body['error']?.toString() ?? '오늘은 이미 출석했어요.');
      }
      if (response.statusCode != 200) return _demoCheckIn();
      _demoMode = false;
      return PointBalance.fromJson(body);
    } on EventException {
      rethrow;
    } catch (_) {
      return _demoCheckIn();
    }
  }

  PointBalance _demoCheckIn() {
    final now = DateTime.now();
    if (_demoPoints.checkedInToday(now)) {
      throw const EventException('오늘은 이미 출석했어요.');
    }
    _demoPoints = PointBalance(
      totalPoints: _demoPoints.totalPoints + 50,
      currentStreakDays: _demoPoints.currentStreakDays + 1,
      lastCheckInDate: now,
    );
    return _enterDemoMode<PointBalance>(_demoPoints);
  }

  @override
  Future<List<SurveyEvent>> fetchSurveys() async {
    final headers = await _tryAuthHeaders();
    if (headers == null) return _enterDemoModeList<SurveyEvent>(_demoSurveys);
    try {
      final response = await _client
          .get(_uri('/api/events/surveys'), headers: headers)
          .timeout(const Duration(seconds: 6));
      final body = _decode(response);
      if (response.statusCode != 200 || body['items'] is! List) {
        return _enterDemoModeList<SurveyEvent>(_demoSurveys);
      }
      _demoMode = false;
      return (body['items'] as List)
          .whereType<Map<String, dynamic>>()
          .map(SurveyEvent.fromJson)
          .toList();
    } catch (_) {
      return _enterDemoModeList<SurveyEvent>(_demoSurveys);
    }
  }

  @override
  Future<int> submitSurveyResponse(
    String surveyId,
    Map<String, String> answers,
  ) async {
    final headers = await _tryAuthHeaders();
    if (headers == null) return _demoSubmitSurvey(surveyId);
    try {
      final response = await _client
          .post(
            _uri('/api/events/surveys/$surveyId/response'),
            headers: headers,
            body: jsonEncode({
              'answers': answers.entries
                  .map((e) => {'questionId': e.key, 'value': e.value})
                  .toList(),
            }),
          )
          .timeout(const Duration(seconds: 6));
      final body = _decode(response);
      if (response.statusCode != 200) return _demoSubmitSurvey(surveyId);
      _demoMode = false;
      return (body['pointsEarned'] as num?)?.round() ?? 0;
    } catch (_) {
      return _demoSubmitSurvey(surveyId);
    }
  }

  int _demoSubmitSurvey(String surveyId) {
    final index = _demoSurveys.indexWhere((survey) => survey.id == surveyId);
    if (index == -1) throw const EventException('존재하지 않는 설문이에요.');
    final survey = _demoSurveys[index];
    if (survey.completed) throw const EventException('이미 참여한 설문이에요.');
    _demoSurveys[index] = SurveyEvent(
      id: survey.id,
      title: survey.title,
      durationLabel: survey.durationLabel,
      rewardPoints: survey.rewardPoints,
      completed: true,
    );
    _demoPoints = PointBalance(
      totalPoints: _demoPoints.totalPoints + survey.rewardPoints,
      currentStreakDays: _demoPoints.currentStreakDays,
      lastCheckInDate: _demoPoints.lastCheckInDate,
    );
    _demoMode = true;
    return survey.rewardPoints;
  }

  @override
  Future<ReferralInfo> fetchReferralInfo() async {
    final headers = await _tryAuthHeaders();
    if (headers == null) return _enterDemoMode<ReferralInfo>(demoReferralInfo);
    try {
      final response = await _client
          .get(_uri('/api/events/referral'), headers: headers)
          .timeout(const Duration(seconds: 6));
      final body = _decode(response);
      if (response.statusCode != 200) {
        return _enterDemoMode<ReferralInfo>(demoReferralInfo);
      }
      _demoMode = false;
      return ReferralInfo.fromJson(body);
    } catch (_) {
      return _enterDemoMode<ReferralInfo>(demoReferralInfo);
    }
  }

  @override
  Future<List<RewardCoupon>> fetchRewards() async {
    final headers = await _tryAuthHeaders();
    if (headers == null) return _enterDemoModeList<RewardCoupon>(_demoRewards);
    try {
      final response = await _client
          .get(_uri('/api/events/rewards'), headers: headers)
          .timeout(const Duration(seconds: 6));
      final body = _decode(response);
      if (response.statusCode != 200 || body['items'] is! List) {
        return _enterDemoModeList<RewardCoupon>(_demoRewards);
      }
      _demoMode = false;
      return (body['items'] as List)
          .whereType<Map<String, dynamic>>()
          .map(RewardCoupon.fromJson)
          .toList();
    } catch (_) {
      return _enterDemoModeList<RewardCoupon>(_demoRewards);
    }
  }

  @override
  Future<void> redeemReward(String rewardId) async {
    final headers = await _tryAuthHeaders();
    if (headers == null) return _demoRedeem(rewardId);
    try {
      final response = await _client
          .post(_uri('/api/events/rewards/$rewardId/redeem'), headers: headers)
          .timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return _demoRedeem(rewardId);
      _demoMode = false;
    } catch (_) {
      _demoRedeem(rewardId);
    }
  }

  void _demoRedeem(String rewardId) {
    final reward = _demoRewards.firstWhere(
      (item) => item.id == rewardId,
      orElse: () => throw const EventException('존재하지 않는 리워드예요.'),
    );
    if (_demoPoints.totalPoints < reward.costPoints) {
      throw const EventException('포인트가 부족해요.');
    }
    _demoPoints = PointBalance(
      totalPoints: _demoPoints.totalPoints - reward.costPoints,
      currentStreakDays: _demoPoints.currentStreakDays,
      lastCheckInDate: _demoPoints.lastCheckInDate,
    );
    _demoMode = true;
  }

  T _enterDemoMode<T>(T value) {
    _demoMode = true;
    return value;
  }

  List<T> _enterDemoModeList<T>(List<T> value) {
    _demoMode = true;
    return value;
  }

  void close() => _client.close();
}