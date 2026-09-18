import 'package:eyes_mobile/app/config/app_environment.dart';
import 'package:eyes_mobile/core/logging/secure_logger.dart';
import 'package:eyes_mobile/core/persistence/secure_remote_session_store.dart';
import 'package:eyes_mobile/core/session/remote_session_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_account.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues(<String, String>{}));

  test(
    'stores, restores and clears a complete remote session securely',
    () async {
      final logger = SecureLogger(AppEnvironment.dev())..initialize();
      const storage = FlutterSecureStorage();
      final store = SecureRemoteSessionStore(storage, logger);
      final changes = <RemoteSessionChange>[];
      final subscription = store.changes.listen(changes.add);

      await store.save(testRemoteSession);
      final restored = await store.read();
      await store.clear(reason: RemoteSessionChangeReason.expired);

      expect(restored?.accessToken, 'test-access-token');
      expect(restored?.user.email, 'pessoa@example.com');
      expect(await store.read(), isNull);
      expect(
        changes.map((change) => change.reason),
        <RemoteSessionChangeReason>[
          RemoteSessionChangeReason.signedIn,
          RemoteSessionChangeReason.expired,
        ],
      );

      await subscription.cancel();
      await store.dispose();
      await logger.dispose();
    },
  );
}
