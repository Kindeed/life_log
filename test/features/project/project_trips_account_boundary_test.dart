import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/features/project/domain/entities/project_record_scope.dart';
import 'package:life_log/features/project/presentation/project_trips_cubit.dart';
import 'package:life_log/features/work_log/application/load_project_work_log_trips.dart';
import 'package:life_log/features/work_log/application/watch_work_log_entries.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_edit_draft.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';
import 'package:life_log/features/work_log/domain/repositories/work_log_repository_port.dart';

const _scope = ProjectRecordScope(
  name: '共享项目',
  id: 7,
  syncId: 'shared-project',
);

void main() {
  test(
    'switching account clears the same project before B finishes reading',
    () async {
      final repository = _Repository()
        ..owner = 'A'
        ..entries['A'] = [_trip(1, 'A记录')];
      final cubit = _cubit(repository)..start();
      await _settle();
      expect(cubit.state.entries.single.note, 'A记录');

      final bRead = Completer<List<WorkLogEntry>>();
      repository.nextRead = bRead;
      repository.changeOwner('B');
      expect(cubit.state.entries, isEmpty);
      expect(cubit.state.loading, isTrue);
      bRead.complete([_trip(2, 'B记录')]);
      await _settle();
      expect(cubit.state.entries.single.note, 'B记录');
      expect(cubit.state.failure, isNull);
      await cubit.close();
      await repository.close();
    },
  );

  test(
    'signing out clears private trips and reloads unowned local trips',
    () async {
      final repository = _Repository()
        ..owner = 'A'
        ..entries['A'] = [_trip(1, 'A记录')]
        ..entries[null] = [_trip(3, '本地记录')];
      final cubit = _cubit(repository)..start();
      await _settle();
      repository.changeOwner(null);
      expect(cubit.state.entries, isEmpty);
      await _settle();
      expect(cubit.state.entries.single.note, '本地记录');
      expect(cubit.state.loading, isFalse);
      await cubit.close();
      await repository.close();
    },
  );

  test(
    'a delayed old-account success cannot restore A after B loaded',
    () async {
      final oldRead = Completer<List<WorkLogEntry>>();
      final repository = _Repository()
        ..owner = 'A'
        ..nextRead = oldRead
        ..entries['B'] = [_trip(2, 'B记录')];
      final cubit = _cubit(repository)..start();
      repository.changeOwner('B');
      await _settle();
      expect(cubit.state.entries.single.note, 'B记录');
      oldRead.complete([_trip(1, 'A迟到记录')]);
      await _settle();
      expect(cubit.state.entries.single.note, 'B记录');
      expect(cubit.state.failure, isNull);
      await cubit.close();
      await repository.close();
    },
  );

  test('a delayed old-account failure cannot replace B state', () async {
    final oldRead = Completer<List<WorkLogEntry>>();
    final repository = _Repository()
      ..owner = 'A'
      ..nextRead = oldRead
      ..entries['B'] = [_trip(2, 'B记录')];
    final cubit = _cubit(repository)..start();
    repository.changeOwner('B');
    await _settle();
    oldRead.completeError(StateError('A账号查询失败'));
    await _settle();
    expect(cubit.state.entries.single.note, 'B记录');
    expect(cubit.state.failure, isNull);
    expect(cubit.state.loading, isFalse);
    await cubit.close();
    await repository.close();
  });

  test(
    'B table changes refresh while an old A watcher read remains blocked',
    () async {
      final repository = _Repository()
        ..owner = 'A'
        ..entries['A'] = [_trip(1, 'A记录')]
        ..entries['B'] = [_trip(2, 'B记录')];
      final cubit = _cubit(repository)..start();
      await _settle();
      final oldWatchRead = Completer<List<WorkLogEntry>>();
      repository.nextRead = oldWatchRead;
      repository.changes.add(null);
      expect(repository.readOwners, ['A', 'A']);
      repository.changes.add(null);
      repository.changeOwner('B');
      await _settle();
      expect(cubit.state.entries.single.note, 'B记录');

      repository.entries['B'] = [_trip(4, 'B新记录')];
      repository.changes.add(null);
      await _settle();
      expect(oldWatchRead.isCompleted, isFalse);
      expect(cubit.state.entries.single.note, 'B新记录');
      expect(repository.readOwners, ['A', 'A', 'B', 'B']);
      oldWatchRead.complete([_trip(5, 'A过期watch结果')]);
      await _settle();
      expect(cubit.state.entries.single.note, 'B新记录');
      await cubit.close();
      await repository.close();
    },
  );

  test(
    'close cancels both watches and ignores pending scope results',
    () async {
      final repository = _Repository()
        ..owner = 'A'
        ..entries['A'] = [_trip(1, 'A记录')];
      final cubit = _cubit(repository)..start();
      cubit.start();
      await _settle();
      expect(repository.readOwners, ['A']);
      expect(repository.scopeChanges.hasListener, isTrue);
      expect(repository.changes.hasListener, isTrue);
      final pending = Completer<List<WorkLogEntry>>();
      repository.nextRead = pending;
      repository.changeOwner('B');
      expect(cubit.state.entries, isEmpty);
      await cubit.close();
      expect(repository.scopeChanges.hasListener, isFalse);
      expect(repository.changes.hasListener, isFalse);
      final reads = repository.readOwners.length;
      repository.changeOwner('C');
      repository.changes.add(null);
      cubit.start();
      await cubit.loadEntries();
      pending.complete([_trip(3, 'B关闭后结果')]);
      await _settle();
      expect(repository.readOwners.length, reads);
      expect(cubit.state.entries, isEmpty);
      await repository.close();
    },
  );
}

ProjectTripsCubit _cubit(_Repository repository) => ProjectTripsCubit(
  scope: _scope,
  loadTrips: LoadProjectWorkLogTrips(repository),
  watchEntries: WatchWorkLogEntries(repository),
  watchScope: () => repository.scopeChanges.stream,
);

Future<void> _settle() => Future<void>.delayed(Duration.zero);

WorkLogEntry _trip(int id, String note) => WorkLogEntry(
  id: id,
  date: DateTime(2026, 10, 11),
  type: WorkLogEntryType.businessTrip,
  projectId: 7,
  projectSyncId: 'shared-project',
  projectName: '共享项目',
  note: note,
);

final class _Repository implements WorkLogRepositoryPort {
  final scopeChanges = StreamController<void>.broadcast(sync: true);
  final changes = StreamController<void>.broadcast(sync: true);
  final entries = <String?, List<WorkLogEntry>>{};
  final readOwners = <String?>[];
  String? owner;
  Completer<List<WorkLogEntry>>? nextRead;

  void changeOwner(String? value) {
    owner = value;
    scopeChanges.add(null);
  }

  Future<void> close() async {
    await scopeChanges.close();
    await changes.close();
  }

  @override
  Future<List<WorkLogEntry>> getAllEntries() async {
    readOwners.add(owner);
    final pending = nextRead;
    nextRead = null;
    return pending != null ? pending.future : entries[owner] ?? const [];
  }

  @override
  Stream<void> watchEntries() => changes.stream;

  @override
  Future<void> deleteEntry(int id) async {}

  @override
  Future<WorkLogEditDraft?> getEditDraft(int id) async => null;

  @override
  Future<List<WorkLogEntry>> getEntriesByMonth(DateTime month) async =>
      const [];

  @override
  Future<void> normalizeDuplicateDays() async {}

  @override
  Future<void> saveEntry(WorkLogEntry entry, {required bool markDirty}) async {}
}
