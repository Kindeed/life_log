import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/common/services/cloud_config_service.dart';
import 'package:life_log/common/services/log_service.dart';

void main() {
  group('logging privacy and stack traces', () {
    test('cloud config exposes a masked Supabase URL for logs', () {
      final service = CloudConfigService().init();

      expect(service.maskedSupabaseUrl, isNot(equals(service.supabaseUrl)));
      expect(service.maskedSupabaseUrl, isNot(equals(service.supabaseAnonKey)));
    });

    test('mobile startup logs use masked Supabase URL', () {
      final source = File(
        'lib/app/lifelog_mobile_entry.dart',
      ).readAsStringSync();

      expect(source, contains('cloudConfig.maskedSupabaseUrl'));
      expect(
        source,
        isNot(contains("Supabase 初始化成功: \${cloudConfig.supabaseUrl}")),
      );
    });

    test(
      'debug logging defaults to build-mode policy instead of always on',
      () {
        final source = File(
          'lib/common/services/log_service.dart',
        ).readAsStringSync();

        expect(source, contains('bool enableDebug = !kReleaseMode;'));
        expect(source, isNot(contains('bool enableDebug = true;')));
      },
    );

    test(
      'log exports redact direct identifiers, paths, and storage locations',
      () {
        final service = LogService();
        const email = 'person@example.com';
        const userId = '123e4567-e89b-12d3-a456-426614174000';
        const supabaseUrl = 'https://project-ref.supabase.co/rest/v1/work_logs';
        const localPath = r'C:\Users\WZH\Documents\LifeLog\receipt.pdf';

        service.info(
          'Privacy',
          'email=$email userId=$userId url=$supabaseUrl path=$localPath '
              'storage=user/evidence/file.pdf',
        );

        final logs = service.exportLogs();

        expect(logs, isNot(contains(email)));
        expect(logs, isNot(contains(userId)));
        expect(logs, isNot(contains('project-ref.supabase.co')));
        expect(logs, isNot(contains(r'C:\Users\WZH')));
        expect(logs, isNot(contains('user/evidence/file.pdf')));
        expect(logs, contains('[email]'));
        expect(logs, contains('[id]'));
        expect(logs, contains('https://[supabase-url]'));
        expect(logs, contains('[local-path]'));
        expect(logs, contains('storage=[storage-path]'));
      },
    );

    test('auth failures include stack traces in logs', () {
      final source = File(
        'lib/common/services/auth_service.dart',
      ).readAsStringSync();

      expect(source, contains('catch (e, stackTrace)'));
      expect(
        source,
        contains(
          "LogService.to.error('Auth', 'Sign in failed: \$e', stackTrace)",
        ),
      );
      expect(
        source,
        contains(
          "LogService.to.error('Auth', 'Sign up failed: \$e', stackTrace)",
        ),
      );
      expect(
        source,
        contains(
          "LogService.to.error('Auth', 'Sign out failed: \$e', stackTrace)",
        ),
      );
    });

    test('sync and repository error catch paths keep stack traces', () {
      final paths = [
        'lib/common/services/sync_service.dart',
        'lib/features/work_log/data/work_log_repository.dart',
        'lib/features/subscription/data/subscription_repository.dart',
        'lib/features/project/data/project_repository.dart',
        'lib/features/evidence/data/evidence_repository.dart',
        'lib/features/expense/data/expense_record_repository.dart',
      ];

      for (final path in paths) {
        final source = File(path).readAsStringSync();
        expect(
          source,
          isNot(contains('catch (e)')),
          reason: '$path should log error stack traces instead of only \$e.',
        );
      }
    });

    test(
      'backup, restore, and data-management catch paths keep stack traces',
      () {
        final backupService = File(
          'lib/common/db/backup_service.dart',
        ).readAsStringSync();
        final dataManagement = File(
          'lib/features/profile/presentation/views/data_management_view.dart',
        ).readAsStringSync();

        expect(backupService, isNot(contains('catch (e)')));
        expect(backupService, contains('catch (e, stackTrace)'));
        expect(backupService, contains("LogService.to.error('Backup'"));
        expect(dataManagement, isNot(contains('catch (e)')));
        expect(dataManagement, contains('catch (e, stackTrace)'));
        expect(
          dataManagement,
          contains("LogService.to.error('DataManagement'"),
        );
      },
    );

    test(
      'diagnostics include log level summary and recent operation context',
      () {
        final service = LogService();

        service.info('Startup', '应用启动');
        service.warning('Sync', '云同步未配置');
        service.error('WorkLog', '保存失败', StackTrace.current);

        final diagnostics = service.exportDiagnostics();

        expect(diagnostics, contains('日志级别统计:'));
        expect(diagnostics, contains('DEBUG=0'));
        expect(diagnostics, contains('INFO=1'));
        expect(diagnostics, contains('WARN=1'));
        expect(diagnostics, contains('ERROR=1'));
        expect(diagnostics, contains('最近日志:'));
        expect(diagnostics, contains('[INFO] [Startup] 应用启动'));
        expect(diagnostics, contains('[WARN] [Sync] 云同步未配置'));
        expect(diagnostics, contains('[ERROR] [WorkLog] 保存失败'));
      },
    );
  });
}
