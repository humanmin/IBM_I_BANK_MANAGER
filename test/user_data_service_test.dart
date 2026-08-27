import 'package:flutter_test/flutter_test.dart';
import 'package:ibm_money_app/models.dart';
import 'package:ibm_money_app/user_data_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'restores goal, wishlist, and fixed expenses for the same user',
    () async {
      final service = UserDataService(userId: 'kakao:123');
      const goal = SavingsGoal(
        name: '독거미 키보드',
        imageAsset: null,
        imageUrl: 'https://example.com/keyboard.png',
        price: 89000,
        saved: 20000,
        savingAmount: 5000,
        savingPeriod: SavingPeriod.daily,
      );
      const wish = WishItem(
        id: 'wish-1',
        name: '독거미 키보드',
        price: 89000,
        imageUrl: 'https://example.com/keyboard.png',
        productUrl: 'https://example.com/keyboard',
        source: '테스트몰',
      );
      const expense = FixedExpense(
        id: 'fixed-1',
        name: '넷플릭스',
        amount: 17000,
        category: 'OTT·구독',
        billingDay: 15,
      );

      await service.save(
        goal: goal,
        hasSelectedGoal: true,
        wishItems: const [wish],
        fixedExpenses: const [expense],
      );

      final restored = await UserDataService(userId: 'kakao:123').load();
      expect(restored, isNotNull);
      expect(restored!.goal.name, '독거미 키보드');
      expect(restored.goal.saved, 20000);
      expect(restored.hasSelectedGoal, isTrue);
      expect(restored.wishItems.single.productUrl, wish.productUrl);
      expect(restored.fixedExpenses.single.name, '넷플릭스');
    },
  );

  test('keeps different users data isolated', () async {
    final first = UserDataService(userId: 'user-1');
    final second = UserDataService(userId: 'user-2');
    const goal = SavingsGoal(
      name: '첫 번째 목표',
      imageAsset: null,
      price: 10000,
      saved: 0,
      savingAmount: 1000,
      savingPeriod: SavingPeriod.weekly,
    );

    await first.save(
      goal: goal,
      hasSelectedGoal: true,
      wishItems: const [],
      fixedExpenses: const [],
    );

    expect(await first.load(), isNotNull);
    expect(await second.load(), isNull);
  });
}
