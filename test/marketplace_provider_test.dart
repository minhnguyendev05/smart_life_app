import 'package:flutter_test/flutter_test.dart';
import 'package:smart_life_app/providers/marketplace_provider.dart';

void main() {
  test('MarketplaceProvider denies add listing without admin permission', () {
    final provider = MarketplaceProvider();
    final initial = provider.items.length;

    final ok = provider.addListing(
      title: 'San pham test',
      price: 100000,
      seller: 'User A',
    );

    expect(ok, isFalse);
    expect(provider.items.length, initial);
  });

  test('MarketplaceProvider allows add listing for admin', () {
    final provider = MarketplaceProvider();
    provider.setPostingPermission(isAdmin: true);
    final initial = provider.items.length;

    final ok = provider.addListing(
      title: 'San pham admin',
      price: 120000,
      seller: 'Admin',
    );

    expect(ok, isTrue);
    expect(provider.items.length, initial + 1);
  });
}
