import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:istakipmobil/core/network/api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('ApiClient Network & Error Handling Tests', () {
    test('testConnection returns false and sets connection error for invalid URL', () async {
      final success = await ApiClient.testConnection('http://127.0.0.1:59999');
      expect(success, isFalse);
      expect(ApiClient.lastErrorType, equals(ApiErrorType.connection));
      expect(ApiClient.lastErrorMessage, contains('Sunucuya ulaşılamadı'));
    });

    test('fetchWorkers returns empty list and sets error when server is unreachable', () async {
      await ApiClient.resetClient();
      final workers = await ApiClient.fetchWorkers();
      expect(workers, isEmpty);
      expect(ApiClient.lastErrorType, isNot(equals(ApiErrorType.none)));
    });

    test('fetchAlarms returns empty list and sets error when server is unreachable', () async {
      await ApiClient.resetClient();
      final alarms = await ApiClient.fetchAlarms();
      expect(alarms, isEmpty);
      expect(ApiClient.lastErrorType, isNot(equals(ApiErrorType.none)));
    });

    test('login sets badRequest or connection error on failed authentication attempt', () async {
      await ApiClient.resetClient();
      final success = await ApiClient.login('invalid_user_xyz', 'wrong_pass');
      expect(success, isFalse);
      expect(ApiClient.lastErrorType, isNot(equals(ApiErrorType.none)));
      expect(ApiClient.lastErrorMessage.isNotEmpty, isTrue);
    });
  });
}
