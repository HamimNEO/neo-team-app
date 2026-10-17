import 'package:flutter_test/flutter_test.dart';
import 'package:neonecy_team_app/core/network/api_client.dart';
import 'package:neonecy_team_app/features/auth/presentation/controllers/auth_session.dart';
import 'package:neonecy_team_app/features/more/data/datasources/notification_api.dart';
import 'package:neonecy_team_app/features/more/data/notification_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationStore routing', () {
    test('routes direct message from Super Admin to specific person screen', () {
      final store = NotificationStore.createForTesting(
        api: NotificationApi(ApiClient(baseUrl: () => '', accessToken: () => null)),
      );

      final route = store.mapRouteForTesting(
        type: 'message',
        entity: {'type': 'conversation', 'id': '1'},
        data: {'conversation_id': '1'},
        title: 'New message from Super Admin',
      );

      expect(route, '/messages/${AuthSession.adminEmployeeId}');
    });

    test('routes group chat message to group conversation screen', () {
      final store = NotificationStore.createForTesting(
        api: NotificationApi(ApiClient(baseUrl: () => '', accessToken: () => null)),
      );

      final route = store.mapRouteForTesting(
        type: 'message',
        entity: {'type': 'group_conversation', 'id': 'grp_123'},
        data: {'group_id': 'grp_123', 'type': 'group'},
        title: 'New message in Operations Team',
      );

      expect(route, '/message-groups/grp_123');
    });

    test('routes leads to specific lead screen', () {
      final store = NotificationStore.createForTesting(
        api: NotificationApi(ApiClient(baseUrl: () => '', accessToken: () => null)),
      );

      final route = store.mapRouteForTesting(
        type: 'lead',
        entity: {'id': '42'},
        data: null,
        title: 'New Lead Assigned',
      );

      expect(route, '/leads/42');
    });
    test('resolveRoute redirects direct message to conversation screen even with stale group route', () {
      final store = NotificationStore.createForTesting(
        api: NotificationApi(ApiClient(baseUrl: () => '', accessToken: () => null)),
      );

      final route = store.resolveRoute({
        'title': 'New message from Super Admin',
        'subtitle': 'Great job Yeapas! Release build is passing all lint checks.',
        'category': 'Messages',
        'targetRoute': '/message-groups/1', // old stale route
        'raw': {
          'type': 'message',
          'data': {'conversation_id': '1', 'route': '/message-groups/1'},
        },
      });

      expect(route, '/messages/${AuthSession.adminEmployeeId}');
    });
  });
}
