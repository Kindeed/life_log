import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:life_log/common/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'login listeners observe the new epoch before starting cloud work',
    () async {
      final folder = await Directory.systemTemp.createTemp('auth_epoch_');
      const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pathChannel, (_) async => folder.path);
      final storage = GetStorage(
        'epoch_${DateTime.now().microsecondsSinceEpoch}',
        folder.path,
      );
      await storage.initStorage;
      final client = SupabaseClient('https://example.supabase.co', 'test-key');
      final auth = AuthService(client: client, storage: storage);
      final observed = <(String?, int)>[];
      auth.currentUser.addListener(() {
        observed.add((auth.userId, auth.sessionEpoch));
      });
      try {
        auth.debugSetCurrentUser(_user('owner-a'));
        auth.debugSetCurrentUser(null);
        auth.debugSetCurrentUser(_user('owner-a'));
        auth.debugSetCurrentUser(_user('owner-b'));
        expect(observed, [
          ('owner-a', 1),
          (null, 2),
          ('owner-a', 3),
          ('owner-b', 4),
        ]);
        final epoch = auth.sessionEpoch;
        auth.debugSetCurrentUser(_user('owner-b'));
        expect(auth.sessionEpoch, epoch);
      } finally {
        auth.dispose();
        await storage.erase();
        await client.dispose();
        await folder.delete(recursive: true);
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(pathChannel, null);
      }
    },
  );
}

User _user(String id) => User(
  id: id,
  appMetadata: const {},
  userMetadata: null,
  aud: 'authenticated',
  createdAt: '2026-10-01T00:00:00Z',
);
