import 'package:flutter/material.dart';

enum AppTab {
  home,
  notifications,
  habits,
  insights,
  spending,
  shop,
  payment,
  event,
  settings,
}

enum ThemeChoice { yellow, navy, green }

enum SavingPeriod {
  daily('하루', 1),
  everyTwoDays('이틀', 2),
  weekly('일주일', 7),
  biweekly('2주', 14),
  monthly('한 달', 30);

  const SavingPeriod(this.label, this.days);

  final String label;
  final int days;
}

@immutable
class AppPalette {
  const AppPalette({
    required this.accent,
    required this.accentSoft,
    required this.accentBorder,
    required this.accentTrack,
    required this.pageBackground,
    required this.text,
    required this.textMuted,
    required this.textSoft,
  });

  factory AppPalette.fromChoice(ThemeChoice choice) {
    return switch (choice) {
      ThemeChoice.yellow => const AppPalette(
        accent: Color(0xFFFFEF5B),
        accentSoft: Color(0xFFFFF6A2),
        accentBorder: Color(0xFFF3E27A),
        accentTrack: Color(0xFFEFE7B3),
        pageBackground: Color(0xFFFFF9C3),
        text: Color(0xFF1F3528),
        textMuted: Color(0xFF7A8F7E),
        textSoft: Color(0xFF4D6354),
      ),
      ThemeChoice.navy => const AppPalette(
        accent: Color(0xFF93ADD9),
        accentSoft: Color(0xFFD1DFF3),
        accentBorder: Color(0xFFB7C5D8),
        accentTrack: Color(0xFFC5D1E0),
        pageBackground: Color(0xFFE6EDF6),
        text: Color(0xFF243552),
        textMuted: Color(0xFF8A96A8),
        textSoft: Color(0xFF51627A),
      ),
      ThemeChoice.green => const AppPalette(
        accent: Color(0xFF9FC4A6),
        accentSoft: Color(0xFFD4EAD8),
        accentBorder: Color(0xFFB4D4B8),
        accentTrack: Color(0xFFC4DCC8),
        pageBackground: Color(0xFFE5F3E8),
        text: Color(0xFF1F3528),
        textMuted: Color(0xFF7A8F7E),
        textSoft: Color(0xFF4D6354),
      ),
    };
  }

  final Color accent;
  final Color accentSoft;
  final Color accentBorder;
  final Color accentTrack;
  final Color pageBackground;
  final Color text;
  final Color textMuted;
  final Color textSoft;
}

@immutable
class SavingsGoal {
  const SavingsGoal({
    required this.name,
    required this.imageAsset,
    this.imageUrl,
    required this.price,
    required this.saved,
    required this.savingAmount,
    required this.savingPeriod,
  });

  final String name;
  final String? imageAsset;
  final String? imageUrl;
  final int price;
  final int saved;
  final int savingAmount;
  final SavingPeriod savingPeriod;

  SavingsGoal copyWith({
    String? name,
    String? imageAsset,
    String? imageUrl,
    bool clearImage = false,
    int? price,
    int? saved,
    int? savingAmount,
    SavingPeriod? savingPeriod,
  }) {
    return SavingsGoal(
      name: name ?? this.name,
      imageAsset: clearImage ? null : imageAsset ?? this.imageAsset,
      imageUrl: clearImage ? imageUrl : imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      saved: saved ?? this.saved,
      savingAmount: savingAmount ?? this.savingAmount,
      savingPeriod: savingPeriod ?? this.savingPeriod,
    );
  }
}

@immutable
class WishItem {
  const WishItem({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.productUrl,
    required this.source,
  });

  final String id;
  final String name;
  final int price;
  final String imageUrl;
  final String productUrl;
  final String source;

  WishItem copyWith({
    String? name,
    int? price,
    String? imageUrl,
    String? productUrl,
    String? source,
  }) {
    return WishItem(
      id: id,
      name: name ?? this.name,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      productUrl: productUrl ?? this.productUrl,
      source: source ?? this.source,
    );
  }
}

@immutable
class ProductSearchResult {
  const ProductSearchResult({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.productUrl,
    required this.source,
  });

  final String id;
  final String name;
  final int price;
  final String imageUrl;
  final String productUrl;
  final String source;

  factory ProductSearchResult.fromJson(Map<String, dynamic> json) {
    return ProductSearchResult(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).round(),
      imageUrl: json['imageUrl'] as String? ?? '',
      productUrl: json['productUrl'] as String? ?? '',
      source: json['source'] as String? ?? '온라인 쇼핑',
    );
  }

  WishItem toWishItem({String? wishId}) {
    return WishItem(
      id: wishId ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      price: price,
      imageUrl: imageUrl,
      productUrl: productUrl,
      source: source,
    );
  }
}

@immutable
class FixedExpense {
  const FixedExpense({
    required this.id,
    required this.name,
    required this.amount,
    required this.category,
    required this.billingDay,
  });

  final String id;
  final String name;
  final int amount;
  final String category;
  final int billingDay;

  FixedExpense copyWith({
    String? name,
    int? amount,
    String? category,
    int? billingDay,
  }) {
    return FixedExpense(
      id: id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      billingDay: billingDay ?? this.billingDay,
    );
  }
}

@immutable
class MoneyTransaction {
  const MoneyTransaction({
    required this.id,
    required this.merchant,
    required this.category,
    required this.amount,
    required this.date,
  });

  final String id;
  final String merchant;
  final String category;
  final int amount;
  final DateTime date;
}

@immutable
class AccountData {
  const AccountData({
    required this.balance,
    required this.transactions,
    required this.isDemo,
    this.lastUpdated,
  });

  final int balance;
  final List<MoneyTransaction> transactions;
  final bool isDemo;
  final DateTime? lastUpdated;

  AccountData copyWith({
    int? balance,
    List<MoneyTransaction>? transactions,
    bool? isDemo,
    DateTime? lastUpdated,
  }) {
    return AccountData(
      balance: balance ?? this.balance,
      transactions: transactions ?? this.transactions,
      isDemo: isDemo ?? this.isDemo,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

@immutable
class AccountActionResult {
  const AccountActionResult({required this.succeeded, required this.message});

  final bool succeeded;
  final String message;
}

@immutable
class CategoryInfo {
  const CategoryInfo({required this.color, required this.emoji});

  final Color color;
  final String emoji;
}

@immutable
class ShopProduct {
  const ShopProduct({
    required this.id,
    required this.rank,
    required this.rankChange,
    required this.brand,
    required this.name,
    required this.shortName,
    required this.originalPrice,
    required this.price,
    required this.imageAsset,
    required this.colors,
    required this.tabs,
  });

  final String id;
  final int rank;
  final int rankChange;
  final String brand;
  final String name;
  final String shortName;
  final int originalPrice;
  final int price;
  final String imageAsset;
  final List<Color> colors;
  final Set<String> tabs;
}

@immutable
class DemoNotification {
  const DemoNotification({
    required this.id,
    required this.title,
    required this.timeLabel,
    required this.body,
  });

  final String id;
  final String title;
  final String timeLabel;
  final String body;
}

@immutable
class Insight {
  const Insight({
    required this.id,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.actionCategory,
  });

  final String id;
  final String title;
  final String body;
  final String actionLabel;
  final String actionCategory;
}

@immutable
class CategoryTotal {
  const CategoryTotal({
    required this.category,
    required this.amount,
    required this.percent,
    required this.info,
  });

  final String category;
  final int amount;
  final int percent;
  final CategoryInfo info;
}

@immutable
class SpendingStatsData {
  const SpendingStatsData({
    required this.thisMonthSpent,
    required this.lastMonthSpent,
    required this.count,
    required this.averagePerTransaction,
    required this.averagePerDay,
    required this.topCategory,
    required this.topCategoryAmount,
    required this.topMerchant,
    required this.topMerchantAmount,
  });

  final int thisMonthSpent;
  final int lastMonthSpent;
  final int count;
  final int averagePerTransaction;
  final int averagePerDay;
  final String? topCategory;
  final int topCategoryAmount;
  final String? topMerchant;
  final int topMerchantAmount;

  int get difference => thisMonthSpent - lastMonthSpent;
}

@immutable
class AppUser {
  const AppUser({required this.uid, this.email, this.displayName});

  final String uid;
  final String? email;
  final String? displayName;
}

@immutable
class BankAccount {
  const BankAccount({
    required this.id,
    required this.bankName,
    required this.maskedAccountNumber,
    required this.balance,
    this.lastSyncedAt,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id']?.toString() ?? '',
      bankName: json['bankName']?.toString() ?? '',
      maskedAccountNumber: json['maskedAccountNumber']?.toString() ?? '',
      balance: (json['balance'] as num?)?.round() ?? 0,
      lastSyncedAt: DateTime.tryParse(json['lastSyncedAt']?.toString() ?? ''),
    );
  }

  final String id;
  final String bankName;
  final String maskedAccountNumber;
  final int balance;
  final DateTime? lastSyncedAt;
}

@immutable
class PointBalance {
  const PointBalance({
    required this.totalPoints,
    required this.currentStreakDays,
    this.lastCheckInDate,
  });

  factory PointBalance.fromJson(Map<String, dynamic> json) {
    return PointBalance(
      totalPoints: (json['totalPoints'] as num?)?.round() ?? 0,
      currentStreakDays: (json['currentStreakDays'] as num?)?.round() ?? 0,
      lastCheckInDate: DateTime.tryParse(
        json['lastCheckInDate']?.toString() ?? '',
      ),
    );
  }

  static const empty = PointBalance(totalPoints: 0, currentStreakDays: 0);

  final int totalPoints;
  final int currentStreakDays;
  final DateTime? lastCheckInDate;

  bool checkedInToday(DateTime now) {
    final last = lastCheckInDate;
    if (last == null) return false;
    return last.year == now.year &&
        last.month == now.month &&
        last.day == now.day;
  }
}

@immutable
class SurveyEvent {
  const SurveyEvent({
    required this.id,
    required this.title,
    required this.durationLabel,
    required this.rewardPoints,
    required this.completed,
  });

  factory SurveyEvent.fromJson(Map<String, dynamic> json) {
    return SurveyEvent(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      durationLabel: json['durationLabel']?.toString() ?? '',
      rewardPoints: (json['rewardPoints'] as num?)?.round() ?? 0,
      completed: json['completed'] == true,
    );
  }

  final String id;
  final String title;
  final String durationLabel;
  final int rewardPoints;
  final bool completed;
}

@immutable
class ReferralInfo {
  const ReferralInfo({
    required this.code,
    required this.invitedCount,
    required this.earnedPoints,
    required this.rewardPerInvite,
    required this.maxRewardPoints,
  });

  factory ReferralInfo.fromJson(Map<String, dynamic> json) {
    return ReferralInfo(
      code: json['code']?.toString() ?? '',
      invitedCount: (json['invitedCount'] as num?)?.round() ?? 0,
      earnedPoints: (json['earnedPoints'] as num?)?.round() ?? 0,
      rewardPerInvite: (json['rewardPerInvite'] as num?)?.round() ?? 0,
      maxRewardPoints: (json['maxRewardPoints'] as num?)?.round() ?? 0,
    );
  }

  final String code;
  final int invitedCount;
  final int earnedPoints;
  final int rewardPerInvite;
  final int maxRewardPoints;
}

@immutable
class RewardCoupon {
  const RewardCoupon({
    required this.id,
    required this.name,
    required this.costPoints,
    required this.category,
    required this.inStock,
  });

  factory RewardCoupon.fromJson(Map<String, dynamic> json) {
    return RewardCoupon(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      costPoints: (json['costPoints'] as num?)?.round() ?? 0,
      category: json['category']?.toString() ?? '',
      inStock: json['inStock'] != false,
    );
  }

  final String id;
  final String name;
  final int costPoints;
  final String category;
  final bool inStock;
}
