import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class StoredUserData {
  const StoredUserData({
    required this.goal,
    required this.hasSelectedGoal,
    required this.wishItems,
    required this.fixedExpenses,
  });

  final SavingsGoal goal;
  final bool hasSelectedGoal;
  final List<WishItem> wishItems;
  final List<FixedExpense> fixedExpenses;
}

/// 목표 상품, 위시리스트, 고정지출처럼 계정에 속하는 화면 데이터를 저장합니다.
///
/// UID를 키에 포함해 로그아웃해도 같은 계정으로 다시 로그인하면 복원되고,
/// 다른 계정의 데이터와는 섞이지 않게 합니다.
class UserDataService {
  UserDataService({required String userId}) : _storageKey = keyForUser(userId);

  static String keyForUser(String userId) {
    final encoded = base64Url.encode(utf8.encode(userId)).replaceAll('=', '');
    return 'user_app_data_v1_$encoded';
  }

  final String _storageKey;

  Future<StoredUserData?> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(_storageKey);
      if (raw == null || raw.isEmpty) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final goalJson = json['goal'] as Map<String, dynamic>;
      return StoredUserData(
        goal: _goalFromJson(goalJson),
        hasSelectedGoal: json['hasSelectedGoal'] as bool? ?? false,
        wishItems: (json['wishItems'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(_wishItemFromJson)
            .toList(),
        fixedExpenses: (json['fixedExpenses'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(_fixedExpenseFromJson)
            .toList(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save({
    required SavingsGoal goal,
    required bool hasSelectedGoal,
    required List<WishItem> wishItems,
    required List<FixedExpense> fixedExpenses,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _storageKey,
      jsonEncode({
        'goal': _goalToJson(goal),
        'hasSelectedGoal': hasSelectedGoal,
        'wishItems': wishItems.map(_wishItemToJson).toList(),
        'fixedExpenses': fixedExpenses.map(_fixedExpenseToJson).toList(),
      }),
    );
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey);
  }

  static Map<String, dynamic> _goalToJson(SavingsGoal goal) => {
    'name': goal.name,
    'imageAsset': goal.imageAsset,
    'imageUrl': goal.imageUrl,
    'price': goal.price,
    'saved': goal.saved,
    'savingAmount': goal.savingAmount,
    'savingPeriod': goal.savingPeriod.name,
  };

  static SavingsGoal _goalFromJson(Map<String, dynamic> json) {
    final periodName = json['savingPeriod'] as String?;
    final period = SavingPeriod.values.firstWhere(
      (value) => value.name == periodName,
      orElse: () => SavingPeriod.daily,
    );
    return SavingsGoal(
      name: json['name'] as String? ?? '',
      imageAsset: json['imageAsset'] as String?,
      imageUrl: json['imageUrl'] as String?,
      price: (json['price'] as num?)?.round() ?? 0,
      saved: (json['saved'] as num?)?.round() ?? 0,
      savingAmount: (json['savingAmount'] as num?)?.round() ?? 5000,
      savingPeriod: period,
    );
  }

  static Map<String, dynamic> _wishItemToJson(WishItem item) => {
    'id': item.id,
    'name': item.name,
    'price': item.price,
    'imageUrl': item.imageUrl,
    'productUrl': item.productUrl,
    'source': item.source,
  };

  static WishItem _wishItemFromJson(Map<String, dynamic> json) => WishItem(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    price: (json['price'] as num?)?.round() ?? 0,
    imageUrl: json['imageUrl'] as String? ?? '',
    productUrl: json['productUrl'] as String? ?? '',
    source: json['source'] as String? ?? '온라인 쇼핑',
  );

  static Map<String, dynamic> _fixedExpenseToJson(FixedExpense expense) => {
    'id': expense.id,
    'name': expense.name,
    'amount': expense.amount,
    'category': expense.category,
    'billingDay': expense.billingDay,
  };

  static FixedExpense _fixedExpenseFromJson(Map<String, dynamic> json) =>
      FixedExpense(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        amount: (json['amount'] as num?)?.round() ?? 0,
        category: json['category'] as String? ?? '기타',
        billingDay: (json['billingDay'] as num?)?.round() ?? 1,
      );
}
