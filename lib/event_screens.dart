import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_widgets.dart';
import 'event_service.dart';
import 'models.dart';
import 'money_utils.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({required this.eventGateway, super.key});

  final EventGateway eventGateway;

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  PointBalance? _points;
  List<SurveyEvent> _surveys = const [];
  ReferralInfo? _referral;
  List<RewardCoupon> _rewards = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.eventGateway.fetchPoints(),
        widget.eventGateway.fetchSurveys(),
        widget.eventGateway.fetchReferralInfo(),
        widget.eventGateway.fetchRewards(),
      ]);
      if (!mounted) return;
      setState(() {
        _points = results[0] as PointBalance;
        _surveys = results[1] as List<SurveyEvent>;
        _referral = results[2] as ReferralInfo;
        _rewards = results[3] as List<RewardCoupon>;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is EventException ? error.message : '이벤트 정보를 불러오지 못했어요.';
        _loading = false;
      });
    }
  }

  Future<void> _checkIn() async {
    try {
      final updated = await widget.eventGateway.checkIn();
      if (!mounted) return;
      setState(() => _points = updated);
      _showSnack('오늘 출석 완료! +50P');
    } catch (error) {
      _showSnack(error is EventException ? error.message : '출석 체크에 실패했어요.');
    }
  }

  Future<void> _redeem(RewardCoupon reward) async {
    final points = _points;
    if (points == null || points.totalPoints < reward.costPoints) {
      _showSnack('포인트가 부족해요.');
      return;
    }
    try {
      await widget.eventGateway.redeemReward(reward.id);
      if (!mounted) return;
      setState(() {
        _points = PointBalance(
          totalPoints: points.totalPoints - reward.costPoints,
          currentStreakDays: points.currentStreakDays,
          lastCheckInDate: points.lastCheckInDate,
        );
      });
      _showSnack('${reward.name} 교환 완료!');
    } catch (error) {
      _showSnack(error is EventException ? error.message : '교환에 실패했어요.');
    }
  }

  void _copyReferralCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    _showSnack('추천 코드를 복사했어요.');
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final error = _error;
    if (error != null) {
      return _ErrorState(message: error, onRetry: _loadAll);
    }

    final palette = ThemeScope.paletteOf(context);
    final points = _points ?? PointBalance.empty;
    final now = DateTime.now();
    final checkedInToday = points.checkedInToday(now);

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: SingleChildScrollView(
        key: const PageStorageKey('event-scroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      '이벤트',
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.7,
                      ),
                    ),
                    if (widget.eventGateway.isDemoMode) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: palette.accentTrack,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '예시 데이터',
                          style: TextStyle(
                            color: palette.textSoft,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                _PointPill(points: points.totalPoints, palette: palette),
              ],
            ),
            const SizedBox(height: 16),
            _PointBannerCard(points: points.totalPoints, palette: palette),
            const SizedBox(height: 18),
            _AttendanceSection(
              points: points,
              checkedInToday: checkedInToday,
              onCheckIn: _checkIn,
            ),
            const SizedBox(height: 18),
            if (_surveys.isNotEmpty) ...[
              Text(
                '참여하고 포인트 받기',
                style: TextStyle(
                  color: palette.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              ..._surveys.map(
                (survey) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _SurveyCard(survey: survey, onReload: _loadAll),
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (_referral case final referral?) ...[
              _ReferralCard(referral: referral, onCopy: _copyReferralCode),
              const SizedBox(height: 18),
            ],
            if (_rewards.isNotEmpty) ...[
              Text(
                '리워드 교환소',
                style: TextStyle(
                  color: palette.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _rewards.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.35,
                ),
                itemBuilder: (context, index) {
                  final reward = _rewards[index];
                  return _RewardCard(
                    reward: reward,
                    affordable: points.totalPoints >= reward.costPoints,
                    onRedeem: () => _redeem(reward),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PointPill extends StatelessWidget {
  const _PointPill({required this.points, required this.palette});

  final int points;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.accentBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.monetization_on_outlined, size: 16, color: palette.textSoft),
          const SizedBox(width: 6),
          Text(
            '${formatNumber(points)}P',
            style: TextStyle(
              color: palette.text,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PointBannerCard extends StatelessWidget {
  const _PointBannerCard({required this.points, required this.palette});

  final int points;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      color: Colors.white,
      radius: 20,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '이번 달 모은 리워드',
                  style: TextStyle(
                    color: palette.textSoft,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${formatNumber(points)}P',
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceSection extends StatelessWidget {
  const _AttendanceSection({
    required this.points,
    required this.checkedInToday,
    required this.onCheckIn,
  });

  final PointBalance points;
  final bool checkedInToday;
  final VoidCallback onCheckIn;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.paletteOf(context);
    final streakInWeek = points.currentStreakDays % 7;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '출석 스탬프',
              style: TextStyle(
                color: palette.text,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${points.currentStreakDays}일 연속 출석중',
              style: TextStyle(color: palette.textSoft, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(7, (index) {
            final filled = index < streakInWeek;
            final isToday = index == streakInWeek && !checkedInToday;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index == 6 ? 0 : 7),
                child: GestureDetector(
                  onTap: isToday ? onCheckIn : null,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: filled ? palette.accent : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: isToday
                            ? Border.all(color: palette.textSoft, width: 1.6)
                            : Border.all(color: palette.accentBorder, width: 0.5),
                      ),
                      child: Center(
                        child: filled
                            ? Icon(Icons.check, size: 15, color: palette.text)
                            : isToday
                            ? Text(
                                'D${index + 1}',
                                style: TextStyle(
                                  color: palette.text,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _SurveyCard extends StatelessWidget {
  const _SurveyCard({required this.survey, required this.onReload});

  final SurveyEvent survey;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.paletteOf(context);
    return SoftCard(
      color: Colors.white,
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${survey.title} · ${survey.durationLabel}',
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  survey.completed ? '참여 완료' : '+${survey.rewardPoints}P 지급',
                  style: TextStyle(color: palette.textSoft, fontSize: 12),
                ),
              ],
            ),
          ),
          if (!survey.completed)
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: palette.accentSoft,
                foregroundColor: palette.text,
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () => _openSurvey(context),
              child: const Text('참여하기'),
            ),
        ],
      ),
    );
  }

  Future<void> _openSurvey(BuildContext context) async {
    // TODO: 실제 설문 폼 화면으로 교체. 지금은 자리표시 다이얼로그만 연결.
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(survey.title),
        content: const Text('설문 폼 화면은 추후 연결 예정입니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
    onReload();
  }
}

class _ReferralCard extends StatelessWidget {
  const _ReferralCard({required this.referral, required this.onCopy});

  final ReferralInfo referral;
  final ValueChanged<String> onCopy;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.paletteOf(context);
    return SoftCard(
      color: palette.accentSoft,
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.group_add_outlined, color: palette.text, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '친구 초대하고 최대 ${formatNumber(referral.maxRewardPoints)}P 받기',
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    referral.code,
                    style: TextStyle(
                      color: palette.textSoft,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: palette.text,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => onCopy(referral.code),
                child: const Text('복사'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.reward,
    required this.affordable,
    required this.onRedeem,
  });

  final RewardCoupon reward;
  final bool affordable;
  final VoidCallback onRedeem;

  IconData get _icon => switch (reward.category) {
    'cafe' => Icons.local_cafe_outlined,
    'ott' => Icons.smart_display_outlined,
    _ => Icons.card_giftcard_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final palette = ThemeScope.paletteOf(context);
    return SoftCard(
      color: Colors.white,
      radius: 16,
      padding: const EdgeInsets.all(14),
      onTap: affordable ? onRedeem : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: palette.accentSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon, size: 17, color: palette.text),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reward.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${formatNumber(reward.costPoints)}P',
                style: TextStyle(
                  color: affordable ? palette.textSoft : Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}
