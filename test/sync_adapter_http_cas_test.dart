import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/common/db/db_service.dart';
import 'package:life_log/core/sync/sync_adapter.dart';
import 'package:life_log/core/sync/sync_conflict.dart';
import 'package:life_log/core/sync/sync_run_context.dart';
import 'package:life_log/features/evidence/data/evidence_attachment_model.dart';
import 'package:life_log/features/evidence/data/evidence_model.dart';
import 'package:life_log/features/evidence/sync/evidence_sync_adapter.dart';
import 'package:life_log/features/expense/data/expense_record_model.dart';
import 'package:life_log/features/expense/sync/expense_record_sync_adapter.dart';
import 'package:life_log/features/project/data/project_model.dart';
import 'package:life_log/features/project/sync/project_sync_adapter.dart';
import 'package:life_log/features/subscription/data/subscription_model.dart';
import 'package:life_log/features/subscription/sync/subscription_sync_adapter.dart';
import 'package:life_log/features/work_log/data/work_log_model.dart';
import 'package:life_log/features/work_log/sync/work_log_sync_adapter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _owner = 'owner-a';
const _remoteId = 41;
const _syncId = 'sync-7';
final _date = DateTime.utc(2026, 10, 2);

typedef _SyncState = ({int version, bool dirty, bool pendingDelete});

void main() {
  _adapterTests<WorkLog>(
    entityName: 'work_log',
    tableName: 'work_logs',
    create: (deleted, version) => WorkLog()
      ..id = 7
      ..ownerUserId = _owner
      ..remoteId = _remoteId
      ..syncId = _syncId
      ..remoteVersion = version
      ..isDirty = true
      ..pendingDelete = deleted
      ..deletedAt = deleted ? _date : null
      ..date = _date
      ..type = LogType.work
      ..note = 'local work edit',
    adapter: (client, database) =>
        WorkLogSyncAdapter(client: client, dbService: database, userId: _owner),
    state: (entity) => (
      version: entity.remoteVersion,
      dirty: entity.isDirty,
      pendingDelete: entity.pendingDelete,
    ),
  );
  _adapterTests<Subscription>(
    entityName: 'subscription',
    tableName: 'subscriptions',
    create: (deleted, version) => Subscription()
      ..id = 7
      ..ownerUserId = _owner
      ..remoteId = _remoteId
      ..syncId = _syncId
      ..remoteVersion = version
      ..isDirty = true
      ..pendingDelete = deleted
      ..deletedAt = deleted ? _date : null
      ..name = 'local subscription edit'
      ..price = 12
      ..nextPaymentDate = _date,
    adapter: (client, database) => SubscriptionSyncAdapter(
      client: client,
      dbService: database,
      userId: _owner,
    ),
    state: (entity) => (
      version: entity.remoteVersion,
      dirty: entity.isDirty,
      pendingDelete: entity.pendingDelete,
    ),
  );
  _adapterTests<Project>(
    entityName: 'project',
    tableName: 'projects',
    create: (deleted, version) => Project()
      ..id = 7
      ..ownerUserId = _owner
      ..remoteId = _remoteId
      ..syncId = _syncId
      ..remoteVersion = version
      ..isDirty = true
      ..pendingDelete = deleted
      ..deletedAt = deleted ? _date : null
      ..name = 'local project edit'
      ..createdAt = _date
      ..updatedAt = _date,
    adapter: (client, database) =>
        ProjectSyncAdapter(client: client, dbService: database, userId: _owner),
    state: (entity) => (
      version: entity.remoteVersion,
      dirty: entity.isDirty,
      pendingDelete: entity.pendingDelete,
    ),
  );
  _adapterTests<ExpenseRecord>(
    entityName: 'expense_record',
    tableName: 'expense_records',
    create: (deleted, version) => ExpenseRecord()
      ..id = 7
      ..ownerUserId = _owner
      ..remoteId = _remoteId
      ..syncId = _syncId
      ..remoteVersion = version
      ..isDirty = true
      ..pendingDelete = deleted
      ..deletedAt = deleted ? _date : null
      ..expenseDate = _date
      ..amount = 12
      ..note = 'local expense edit',
    adapter: (client, database) => ExpenseRecordSyncAdapter(
      client: client,
      dbService: database,
      userId: _owner,
    ),
    state: (entity) => (
      version: entity.remoteVersion,
      dirty: entity.isDirty,
      pendingDelete: entity.pendingDelete,
    ),
  );
  _adapterTests<ExpenseEvidence>(
    entityName: 'evidence',
    tableName: 'expense_evidence',
    create: (deleted, version) => ExpenseEvidence()
      ..id = 7
      ..ownerUserId = _owner
      ..remoteId = _remoteId
      ..syncId = _syncId
      ..remoteVersion = version
      ..isDirty = true
      ..pendingDelete = deleted
      ..deletedAt = deleted ? _date : null
      ..projectName = 'local evidence edit'
      ..evidenceDate = _date,
    adapter: (client, database) => EvidenceSyncAdapter(
      client: client,
      dbService: database,
      userId: _owner,
      syncAttachmentsForEvidence: (_) async {
        database.attachmentSyncCalls++;
        return true;
      },
    ),
    state: (entity) => (
      version: entity.remoteVersion,
      dirty: entity.isDirty,
      pendingDelete: entity.pendingDelete,
    ),
  );
}

void _adapterTests<T>({
  required String entityName,
  required String tableName,
  required T Function(bool deleted, int version) create,
  required SyncAdapter<T> Function(
    SupabaseClient client,
    _RecordingDbService database,
  )
  adapter,
  required _SyncState Function(T entity) state,
}) {
  group('$entityName HTTP version compare-and-set', () {
    for (final deleted in [false, true]) {
      test(
        'version-zero ${deleted ? 'delete' : 'update'} rejects a newer remote row',
        () async {
          final remote = await _RemoteFixture.start(tableName, version: 2);
          addTearDown(remote.dispose);
          final database = _RecordingDbService();
          final entity = create(deleted, 0);
          final result = await adapter(
            remote.client,
            database,
          ).pushLocalChange(entity);

          expect(remote.requests.map((request) => request.method), [
            'PATCH',
            'GET',
          ]);
          final patch = remote.requests.first;
          expect(patch.uri.path, '/rest/v1/$tableName');
          expect(patch.uri.queryParameters['user_id'], 'eq.$_owner');
          expect(patch.uri.queryParameters['id'], 'eq.$_remoteId');
          expect(patch.uri.queryParameters['version'], 'eq.0');
          if (deleted) {
            expect(patch.body['deleted_at'], isNotNull);
          } else {
            expect(patch.body['user_id'], _owner);
            expect(patch.body['sync_id'], _syncId);
            expect(patch.body['deleted_at'], isNull);
          }
          final refresh = remote.requests.last;
          expect(refresh.uri.queryParameters['user_id'], 'eq.$_owner');
          expect(refresh.uri.queryParameters['id'], 'eq.$_remoteId');

          expect(result.success, isFalse);
          expect(result.purgeLocalDeleted, isFalse);
          expect(result.conflict?.entityName, entityName);
          expect(result.conflict?.ownerUserId, _owner);
          expect(result.conflict?.entitySyncId, _syncId);
          expect(result.conflict?.localVersion, 0);
          expect(result.conflict?.remoteVersion, 2);
          expect(
            result.conflict?.conflictType,
            deleted
                ? SyncConflictType.deleteConflict
                : SyncConflictType.updateConflict,
          );
          expect(database.acknowledgements, isEmpty);
          expect(database.refreshedRows, hasLength(1));
          expect(database.refreshedRows.single['version'], 2);
          expect(database.attachmentSyncCalls, 0);
          expect(database.attachmentDeleteCalls, 0);
          expect(state(entity), (
            version: 0,
            dirty: true,
            pendingDelete: deleted,
          ));
          expect(remote.version, 2);
          expect(remote.lastMutation, isNull);
        },
      );
    }

    test(
      'a matching version-one update acknowledges the selected row',
      () async {
        final remote = await _RemoteFixture.start(tableName, version: 1);
        addTearDown(remote.dispose);
        final database = _RecordingDbService();
        final entity = create(false, 1);
        final result = await adapter(
          remote.client,
          database,
        ).pushLocalChange(entity);

        expect(remote.requests, hasLength(1));
        final patch = remote.requests.single;
        expect(patch.method, 'PATCH');
        expect(patch.uri.queryParameters['user_id'], 'eq.$_owner');
        expect(patch.uri.queryParameters['id'], 'eq.$_remoteId');
        expect(patch.uri.queryParameters['version'], 'eq.1');
        expect(result.success, isTrue);
        expect(result.conflict, isNull);
        expect(database.acknowledgements, [entityName]);
        expect(database.refreshedRows, isEmpty);
        expect(state(entity), (version: 2, dirty: false, pendingDelete: false));
        expect(remote.version, 2);
      },
    );
  });
}

final class _RecordedRequest {
  final String method;
  final Uri uri;
  final Map<String, dynamic> body;

  const _RecordedRequest(this.method, this.uri, this.body);
}

/// Exercises the real PostgREST request serialization and zero-row maybeSingle
/// response, without a cloud account, platform plugins or a native database.
final class _RemoteFixture {
  final HttpServer server;
  final String tableName;
  final SupabaseClient client;
  final requests = <_RecordedRequest>[];
  int version;
  Map<String, dynamic>? lastMutation;

  _RemoteFixture(this.server, this.tableName, this.version)
    : client = SupabaseClient(
        'http://127.0.0.1:${server.port}',
        'local-test-key',
      );

  static Future<_RemoteFixture> start(
    String tableName, {
    required int version,
  }) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final fixture = _RemoteFixture(server, tableName, version);
    server.listen(fixture._handle);
    return fixture;
  }

  Map<String, dynamic> get _row => {
    'id': _remoteId,
    'user_id': _owner,
    'sync_id': _syncId,
    'version': version,
    'updated_at': _date.toIso8601String(),
  };

  Future<void> _handle(HttpRequest request) async {
    final bodyText = await utf8.decoder.bind(request).join();
    final body = bodyText.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(bodyText) as Map);
    requests.add(_RecordedRequest(request.method, request.uri, body));
    request.response.headers.contentType = ContentType.json;
    if (request.uri.path != '/rest/v1/$tableName') {
      request.response.statusCode = HttpStatus.notFound;
      request.response.write('[]');
    } else if (request.method == 'GET') {
      request.response.write(jsonEncode([_row]));
    } else if (request.method == 'PATCH') {
      // A missing version predicate emulates an unconditional update, so the
      // regression fails behaviorally as well as on the captured URL filters.
      final expectedVersion = request.uri.queryParameters['version'];
      if (expectedVersion != null && expectedVersion != 'eq.$version') {
        // PATCH maybeSingle requests an object: PostgREST reports an empty
        // selection as 406/PGRST116, which the real client converts to null.
        request.response.statusCode = HttpStatus.notAcceptable;
        request.response.write(
          jsonEncode({
            'code': 'PGRST116',
            'message': 'JSON object requested, multiple (or no) rows returned',
            'details':
                'Results contain 0 rows, application/vnd.pgrst.object+json requires 1 row',
            'hint': null,
          }),
        );
      } else {
        lastMutation = body;
        version++;
        request.response.write(jsonEncode(_row));
      }
    } else {
      request.response.statusCode = HttpStatus.methodNotAllowed;
      request.response.write('[]');
    }
    await request.response.close();
  }

  Future<void> dispose() async {
    await client.dispose();
    await server.close(force: true);
  }
}

final class _RecordingDbService extends DbService {
  final acknowledgements = <String>[];
  final refreshedRows = <Map<String, dynamic>>[];
  int attachmentSyncCalls = 0;
  int attachmentDeleteCalls = 0;

  @override
  Future<void> updateWorkLogRemoteId(
    WorkLog ack, {
    SyncRunContext? context,
    WorkLog? sentSnapshot,
  }) async => acknowledgements.add('work_log');

  @override
  Future<void> updateSubscriptionRemoteId(
    Subscription ack, {
    SyncRunContext? context,
    Subscription? sentSnapshot,
  }) async => acknowledgements.add('subscription');

  @override
  Future<void> updateProjectRemoteId(
    Project ack, {
    SyncRunContext? context,
    Project? sentSnapshot,
  }) async => acknowledgements.add('project');

  @override
  Future<void> updateExpenseRecordRemoteId(
    ExpenseRecord ack, {
    SyncRunContext? context,
    ExpenseRecord? sentSnapshot,
  }) async => acknowledgements.add('expense_record');

  @override
  Future<void> updateEvidenceRemoteId(
    ExpenseEvidence ack, {
    SyncRunContext? context,
    ExpenseEvidence? sentSnapshot,
  }) async => acknowledgements.add('evidence');

  @override
  Future<void> syncRemoteLogToLocal(
    Map<String, dynamic> data, {
    SyncRunContext? context,
  }) async => refreshedRows.add(Map.of(data));

  @override
  Future<void> syncRemoteSubscriptionToLocal(
    Map<String, dynamic> data, {
    SyncRunContext? context,
  }) async => refreshedRows.add(Map.of(data));

  @override
  Future<void> syncRemoteProjectToLocal(
    Map<String, dynamic> data, {
    SyncRunContext? context,
  }) async => refreshedRows.add(Map.of(data));

  @override
  Future<void> syncRemoteExpenseRecordToLocal(
    Map<String, dynamic> data, {
    SyncRunContext? context,
  }) async => refreshedRows.add(Map.of(data));

  @override
  Future<void> syncRemoteEvidenceToLocal(
    Map<String, dynamic> data, {
    SyncRunContext? context,
  }) async => refreshedRows.add(Map.of(data));

  @override
  Future<EvidenceAttachment?> ensureEvidenceAttachmentForEvidence(
    ExpenseEvidence evidence, {
    SyncRunContext? context,
  }) async => null;

  @override
  Future<void> queueEvidenceAttachmentDeleteForEvidence(
    ExpenseEvidence evidence, {
    SyncRunContext? context,
  }) async => attachmentDeleteCalls++;
}
