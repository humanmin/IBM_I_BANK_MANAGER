import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';

import 'models.dart';
import 'money_utils.dart';

const _widgetProviderName =
    'com.ibm.money.ibm_money_app.SavingsGoalWidgetProvider';

class GoalWidgetSnapshot {
  const GoalWidgetSnapshot({
    required this.hasGoal,
    required this.name,
    required this.targetDate,
    required this.goalSignature,
    required this.imageSignature,
    required this.imageProvider,
  });

  final bool hasGoal;
  final String name;
  final DateTime? targetDate;
  final String goalSignature;
  final String imageSignature;
  final ImageProvider? imageProvider;

  String dDayLabel(DateTime now) {
    final target = targetDate;
    if (!hasGoal || target == null) return '목표 없음';
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(target.year, target.month, target.day);
    final days = targetDay.difference(today).inDays.clamp(0, 99999);
    return days == 0 ? 'D-DAY' : 'D-$days';
  }
}

GoalWidgetSnapshot buildGoalWidgetSnapshot({
  required SavingsGoal goal,
  required bool hasSelectedGoal,
  DateTime? now,
}) {
  if (!hasSelectedGoal) {
    return const GoalWidgetSnapshot(
      hasGoal: false,
      name: '갖고 싶은 상품을 골라보세요',
      targetDate: null,
      goalSignature: 'no-goal',
      imageSignature: 'no-image',
      imageProvider: null,
    );
  }

  final reference = now ?? DateTime.now();
  final today = DateTime(reference.year, reference.month, reference.day);
  final targetDate = today.add(Duration(days: daysToGoal(goal)));
  final imageAsset = goal.imageAsset;
  final imageUrl = goal.imageUrl;
  ImageProvider? imageProvider;
  if (imageAsset != null && imageAsset.isNotEmpty) {
    imageProvider = AssetImage(imageAsset);
  } else if (imageUrl != null && imageUrl.isNotEmpty) {
    imageProvider = NetworkImage(imageUrl);
  }

  return GoalWidgetSnapshot(
    hasGoal: true,
    name: goal.name,
    targetDate: targetDate,
    goalSignature: jsonEncode({
      'name': goal.name,
      'price': goal.price,
      'saved': goal.saved,
      'savingAmount': goal.savingAmount,
      'savingPeriod': goal.savingPeriod.name,
    }),
    imageSignature: jsonEncode({'asset': imageAsset, 'url': imageUrl}),
    imageProvider: imageProvider,
  );
}

abstract interface class GoalWidgetGateway {
  Future<void> syncGoal({
    required SavingsGoal goal,
    required bool hasSelectedGoal,
  });

  Future<void> clear();
}

class HomeGoalWidgetService implements GoalWidgetGateway {
  static const goalAvailableKey = 'goal_available';
  static const goalNameKey = 'goal_name';
  static const goalTargetMillisKey = 'goal_target_millis';
  static const goalSignatureKey = 'goal_signature';
  static const goalImageSignatureKey = 'goal_image_signature';
  static const goalImageKey = 'goal_image';

  bool get _isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<void> syncGoal({
    required SavingsGoal goal,
    required bool hasSelectedGoal,
  }) async {
    if (!_isSupported) return;
    try {
      final snapshot = buildGoalWidgetSnapshot(
        goal: goal,
        hasSelectedGoal: hasSelectedGoal,
      );
      if (!snapshot.hasGoal) {
        await clear();
        return;
      }

      final previousSignature = await HomeWidget.getWidgetData<String>(
        goalSignatureKey,
      );
      final previousImageSignature = await HomeWidget.getWidgetData<String>(
        goalImageSignatureKey,
      );
      final previousTarget = await HomeWidget.getWidgetData<int>(
        goalTargetMillisKey,
      );
      final targetMillis =
          previousSignature == snapshot.goalSignature && previousTarget != null
          ? previousTarget
          : snapshot.targetDate!.millisecondsSinceEpoch;

      await HomeWidget.saveWidgetData<bool>(goalAvailableKey, true);
      await HomeWidget.saveWidgetData<String>(goalNameKey, snapshot.name);
      await HomeWidget.saveWidgetData<int>(goalTargetMillisKey, targetMillis);
      await HomeWidget.saveWidgetData<String>(
        goalSignatureKey,
        snapshot.goalSignature,
      );

      if (previousImageSignature != snapshot.imageSignature) {
        final imageProvider = snapshot.imageProvider;
        if (imageProvider == null) {
          await HomeWidget.saveWidgetData<String>(goalImageKey, null);
        } else {
          try {
            await HomeWidget.saveImage(
              goalImageKey,
              imageProvider,
            ).timeout(const Duration(seconds: 12));
            await HomeWidget.saveWidgetData<String>(
              goalImageSignatureKey,
              snapshot.imageSignature,
            );
          } catch (_) {
            await HomeWidget.saveWidgetData<String>(goalImageKey, null);
          }
        }
      }

      await _updateWidget();
    } catch (error) {
      debugPrint('Home goal widget sync skipped: $error');
    }
  }

  @override
  Future<void> clear() async {
    if (!_isSupported) return;
    try {
      await HomeWidget.saveWidgetData<bool>(goalAvailableKey, false);
      await HomeWidget.saveWidgetData<String>(goalNameKey, '갖고 싶은 상품을 골라보세요');
      await HomeWidget.saveWidgetData<int>(goalTargetMillisKey, 0);
      await HomeWidget.saveWidgetData<String>(goalSignatureKey, 'no-goal');
      await HomeWidget.saveWidgetData<String>(goalImageSignatureKey, null);
      await HomeWidget.saveWidgetData<String>(goalImageKey, null);
      await _updateWidget();
    } catch (error) {
      debugPrint('Home goal widget clear skipped: $error');
    }
  }

  Future<void> _updateWidget() =>
      HomeWidget.updateWidget(qualifiedAndroidName: _widgetProviderName);
}
