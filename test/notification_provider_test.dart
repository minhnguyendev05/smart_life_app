import 'package:flutter_test/flutter_test.dart';
import 'package:smart_life_app/providers/notification_provider.dart';

void main() {
  test('Notification feedback increases relevance score when marked useful', () async {
    final provider = NotificationProvider();
    provider.addSystemNotice('Test', 'Body');

    final id = provider.notifications.first.id;
    final before = provider.relevanceScoreOf(id);

    await provider.rateNotification(id: id, useful: true);
    final after = provider.relevanceScoreOf(id);

    expect(after, greaterThan(before));
  });
}
