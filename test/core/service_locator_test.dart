import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/core/errors/app_failure_mapper.dart';

void main() {
  group('configureCoreDependencies', () {
    test('registers core services on the provided locator', () async {
      final locator = GetIt.asNewInstance();

      final configured = await configureCoreDependencies(locator: locator);

      expect(configured, same(locator));
      expect(locator.isRegistered<AppFailureMapper>(), isTrue);
      expect(
        locator<AppFailureMapper>().fromObject(StateError('bad state')).code,
        'app/unexpected',
      );
    });

    test('is idempotent for repeated phase wiring', () async {
      final locator = GetIt.asNewInstance();

      await configureCoreDependencies(locator: locator);
      await configureCoreDependencies(locator: locator);

      expect(locator.isRegistered<AppFailureMapper>(), isTrue);
    });

    test('cloud runtime services are bridged to GetIt sync gateways', () {
      final appEntry = File(
        'lib/app/lifelog_mobile_entry.dart',
      ).readAsStringSync();
      final syncGatewaySources = [
        'lib/features/work_log/data/work_log_sync_gateway.dart',
        'lib/features/subscription/data/subscription_sync_gateway.dart',
        'lib/features/project/data/project_sync_gateway.dart',
        'lib/features/expense/data/expense_record_sync_gateway.dart',
        'lib/features/evidence/data/evidence_sync_gateway.dart',
      ].map((path) => File(path).readAsStringSync()).toList();
      final profileDi = File(
        'lib/features/profile/profile_feature_di.dart',
      ).readAsStringSync();
      final profileAdapter = File(
        'lib/features/profile/data/legacy_profile_account_adapter.dart',
      ).readAsStringSync();
      final evidenceFileActions = File(
        'lib/features/evidence/presentation/evidence_detail_file_actions.dart',
      ).readAsStringSync();

      expect(appEntry, contains('registerSingleton<AuthService>'));
      expect(appEntry, contains('registerSingleton<SyncService>'));

      for (final source in syncGatewaySources) {
        expect(source, isNot(contains("package:get/get.dart")));
        expect(source, isNot(contains('Get.isRegistered<SyncService>')));
        expect(source, isNot(contains('SyncService.to')));
        expect(source, contains('serviceLocator.isRegistered<SyncService>'));
        expect(source, contains('serviceLocator<SyncService>()'));
      }
      for (final source in [profileDi, profileAdapter, evidenceFileActions]) {
        expect(source, isNot(contains('Get.isRegistered<SyncService>')));
        expect(source, isNot(contains('SyncService.to')));
      }
    });

    test('database runtime service is bridged to GetIt data sources', () {
      final appEntry = File(
        'lib/app/lifelog_mobile_entry.dart',
      ).readAsStringSync();
      final dataSourceSources = [
        'lib/features/work_log/data/work_log_local_data_source.dart',
        'lib/features/subscription/data/subscription_local_data_source.dart',
        'lib/features/project/data/project_local_data_source.dart',
        'lib/features/expense/data/expense_record_local_data_source.dart',
        'lib/features/photo/data/photo_local_data_source.dart',
        'lib/features/evidence/data/evidence_local_data_source.dart',
      ].map((path) => File(path).readAsStringSync()).toList();
      final backupService = File(
        'lib/common/db/backup_service.dart',
      ).readAsStringSync();

      expect(appEntry, contains('registerSingleton<DbService>'));
      for (final source in dataSourceSources) {
        expect(source, isNot(contains('DbService.to')));
        expect(source, contains('serviceLocator<DbService>()'));
      }
      expect(backupService, isNot(contains('DbService.to')));
      expect(backupService, contains('serviceLocator<DbService>()'));
    });

    test('core runtime services are no longer owned by GetX', () {
      final appEntry = File(
        'lib/app/lifelog_mobile_entry.dart',
      ).readAsStringSync();
      final authService = File(
        'lib/common/services/auth_service.dart',
      ).readAsStringSync();
      final syncService = File(
        'lib/common/services/sync_service.dart',
      ).readAsStringSync();
      final dbService = File(
        'lib/common/db/db_service.dart',
      ).readAsStringSync();
      final profileAdapter = File(
        'lib/features/profile/data/legacy_profile_account_adapter.dart',
      ).readAsStringSync();
      final combinedCore = '$authService\n$syncService\n$dbService';

      expect(appEntry, isNot(contains("package:get/get.dart")));
      expect(appEntry, isNot(contains('Get.put(')));
      expect(combinedCore, isNot(contains("package:get/get.dart")));
      expect(combinedCore, isNot(contains('extends GetxService')));
      expect(combinedCore, isNot(contains('static AuthService get to')));
      expect(combinedCore, isNot(contains('static SyncService get to')));
      expect(combinedCore, isNot(contains('static DbService get to')));
      expect(combinedCore, isNot(contains('AuthService.to')));
      expect(combinedCore, isNot(contains('DbService.to')));
      expect(combinedCore, isNot(contains('Get.isRegistered')));
      expect(syncService, isNot(contains('ever(')));
      expect(profileAdapter, isNot(contains("package:get/get.dart")));
      expect(profileAdapter, isNot(contains('Worker')));
      expect(profileAdapter, contains('currentUser.addListener'));
      expect(authService, contains('ValueNotifier<User?> currentUser'));
      expect(syncService, contains('authService.currentUser.addListener'));
      expect(dbService, contains('serviceLocator<AuthService>()'));
    });

    test('production sources no longer depend on GetX APIs', () {
      final dartSources = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));

      for (final file in dartSources) {
        final source = file.readAsStringSync();
        expect(
          source,
          isNot(contains("package:get/get.dart")),
          reason: file.path,
        );
        expect(source, isNot(contains('Get.')), reason: file.path);
        expect(source, isNot(contains('GetxService')), reason: file.path);
        expect(source, isNot(contains('GetxController')), reason: file.path);
        expect(source, isNot(contains('Obx(')), reason: file.path);
        expect(source, isNot(matches(RegExp(r'\.obs\b'))), reason: file.path);
      }

      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, isNot(matches(RegExp(r'^  get:\s', multiLine: true))));
    });

    test(
      'production source names no longer advertise retired GetX ownership',
      () {
        final dartSources = Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'));

        for (final file in dartSources) {
          final source = file.readAsStringSync();
          expect(source, isNot(contains('Getx')), reason: file.path);
          expect(source, isNot(contains('LegacyGet')), reason: file.path);
        }
      },
    );
  });
}
