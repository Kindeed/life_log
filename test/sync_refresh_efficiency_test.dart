import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_log/core/state/coalesced_refresh.dart';
import 'package:life_log/features/evidence/application/load_evidence_entries.dart';
import 'package:life_log/features/evidence/application/watch_evidence_entries.dart';
import 'package:life_log/features/evidence/domain/entities/evidence_entry.dart';
import 'package:life_log/features/evidence/domain/repositories/evidence_repository_port.dart';
import 'package:life_log/features/evidence/presentation/evidence_cubit.dart';
import 'package:life_log/features/expense/application/load_expense_record_entries.dart';
import 'package:life_log/features/expense/application/watch_expense_record_entries.dart';
import 'package:life_log/features/expense/domain/entities/expense_record_entry.dart';
import 'package:life_log/features/expense/domain/repositories/expense_record_repository_port.dart';
import 'package:life_log/features/expense/presentation/expense_record_cubit.dart';
import 'package:life_log/features/photo/application/load_photo_entries.dart';
import 'package:life_log/features/photo/application/watch_photo_entries.dart';
import 'package:life_log/features/photo/domain/entities/photo_entry.dart';
import 'package:life_log/features/photo/domain/repositories/photo_repository_port.dart';
import 'package:life_log/features/photo/presentation/photo_cubit.dart';
import 'package:life_log/features/project/application/load_project_entries.dart';
import 'package:life_log/features/project/application/save_project_entry.dart';
import 'package:life_log/features/project/application/watch_project_entries.dart';
import 'package:life_log/features/project/domain/entities/project_entry.dart';
import 'package:life_log/features/project/domain/repositories/project_repository_port.dart';
import 'package:life_log/features/project/presentation/project_cubit.dart';
import 'package:life_log/features/subscription/application/load_subscription_entries.dart';
import 'package:life_log/features/subscription/application/watch_subscription_entries.dart';
import 'package:life_log/features/subscription/domain/entities/subscription_entry.dart';
import 'package:life_log/features/subscription/domain/repositories/subscription_repository_port.dart';
import 'package:life_log/features/subscription/presentation/subscription_cubit.dart';
import 'package:life_log/features/work_log/application/load_work_log_month.dart';
import 'package:life_log/features/work_log/application/load_work_log_today.dart';
import 'package:life_log/features/work_log/presentation/work_log_today_cubit.dart';
import 'package:life_log/features/subscription/application/load_subscription_today.dart';
import 'package:life_log/features/subscription/presentation/subscription_today_cubit.dart';
import 'package:life_log/features/work_log/application/watch_work_log_entries.dart';
import 'package:life_log/features/work_log/domain/entities/work_log_entry.dart';
import 'package:life_log/features/work_log/domain/repositories/work_log_repository_port.dart';
import 'package:life_log/features/work_log/presentation/work_log_cubit.dart';

void main() {
  for (final factory in _factories.entries) {
    test(
      '${factory.key}: 100 changes keep immediate response and one trailing read',
      () async {
        final h = factory.value();
        addTearDown(() async {
          await h.cubit.close();
          await h.repository.changes.close();
        });
        h.start();
        expect(h.repository.reads, hasLength(1));
        h.complete(0, 1);
        await Future<void>.delayed(Duration.zero);
        final states = <String>[];
        final subscription = h.cubit.stream.listen(
          (_) => states.add(h.status()),
        );
        addTearDown(subscription.cancel);
        for (var i = 0; i < 100; i++) {
          h.repository.changes.add(null);
        }
        await Future<void>.delayed(Duration.zero);
        expect(h.repository.reads, hasLength(2));
        expect(h.status(), 'ready');
        h.complete(1, 2);
        await Future<void>.delayed(Duration.zero);
        expect(h.entries(), [h.entry(2)]);
        await Future<void>.delayed(const Duration(milliseconds: 150));
        expect(h.repository.reads, hasLength(3));
        h.complete(2, 3);
        await Future<void>.delayed(Duration.zero);
        expect(h.entries(), [h.entry(3)]);
        expect(h.repository.maximumActiveReads, 1);
        expect(states, isNot(contains('loading')));
      },
    );

    for (final oldFails in [false, true]) {
      test(
        '${factory.key}: older ${oldFails ? 'failure' : 'success'} cannot replace a new snapshot',
        () async {
          final h = factory.value();
          addTearDown(() async {
            await h.cubit.close();
            await h.repository.changes.close();
          });
          final oldRead = h.reload();
          final newRead = h.reload();
          h.complete(1, 2);
          await newRead;
          if (oldFails) {
            h.repository.reads[0].completeError(StateError('old read failed'));
          } else {
            h.complete(0, 1);
          }
          await oldRead;
          expect(h.entries(), [h.entry(2)]);
          expect(h.status(), 'ready');
        },
      );
    }

    test(
      '${factory.key}: disposal cancels trailing refresh and ignores late read',
      () async {
        final h = factory.value();
        h.start();
        h.complete(0, 1);
        await Future<void>.delayed(Duration.zero);
        h.repository.changes.add(null);
        h.repository.changes.add(null);
        await Future<void>.delayed(Duration.zero);
        await h.cubit.close();
        h.complete(1, 2);
        await Future<void>.delayed(const Duration(milliseconds: 150));
        expect(h.cubit.isClosed, isTrue);
        expect(h.repository.reads, hasLength(2));
        await h.repository.changes.close();
      },
    );
  }

  test(
    'continuous changes refresh each window instead of starving the reader',
    () {
      fakeAsync((time) {
        var reads = 0;
        final refresh = CoalescedRefresh(refresh: () async => reads++);
        refresh.schedule();
        time.flushMicrotasks();
        for (var i = 0; i < 12; i++) {
          refresh.schedule();
          time.elapse(const Duration(milliseconds: 30));
        }
        expect(reads, 4);
        refresh.dispose();
        expect(time.nonPeriodicTimerCount, 0);
      });
    },
  );

  test('refresh errors are reported and a later change still refreshes', () {
    fakeAsync((time) {
      var reads = 0;
      final errors = <Object>[];
      final refresh = CoalescedRefresh(
        refresh: () async {
          reads++;
          if (reads == 1) throw StateError('refresh failed');
        },
        onError: (error, _) => errors.add(error),
      );
      refresh.schedule();
      time.flushMicrotasks();
      refresh.schedule();
      time.elapse(const Duration(milliseconds: 120));
      expect(errors, hasLength(1));
      expect(reads, 2);
      refresh.dispose();
      expect(time.nonPeriodicTimerCount, 0);
    });
  });
}

final _day = DateTime(2026, 10, 7);

final _factories = <String, _Harness Function()>{
  'work': () {
    final repository = _WorkReads();
    final cubit = WorkLogCubit(
      loadMonth: LoadWorkLogMonth(repository),
      watchEntries: WatchWorkLogEntries(repository),
      initialNow: () => _day,
    );
    return _Harness(
      cubit,
      repository,
      cubit.start,
      cubit.loadFocusedMonth,
      () =>
          cubit.state.entriesByDay.values.expand((entries) => entries).toList(),
      () => cubit.state.status.name,
      (id) => WorkLogEntry(
        id: id,
        date: _day,
        type: WorkLogEntryType.work,
        note: 'snapshot $id',
      ),
    );
  },
  'work today': () {
    final repository = _WorkReads();
    final cubit = WorkLogTodayCubit(
      loadToday: LoadWorkLogToday(repository),
      watchEntries: WatchWorkLogEntries(repository),
      todayProvider: () => _day,
    );
    return _Harness(
      cubit,
      repository,
      cubit.start,
      cubit.loadToday,
      () => cubit.state.snapshot.recentEntries,
      () => cubit.state.status.name,
      (id) => WorkLogEntry(
        id: id,
        date: _day,
        type: WorkLogEntryType.work,
        note: 'snapshot $id',
      ),
    );
  },
  'subscription today': () {
    final repository = _SubscriptionReads();
    final cubit = SubscriptionTodayCubit(
      loadToday: LoadSubscriptionToday(repository),
      watchEntries: WatchSubscriptionEntries(repository),
      todayProvider: () => _day,
    );
    return _Harness(
      cubit,
      repository,
      cubit.start,
      cubit.loadToday,
      () => cubit.state.snapshot.dueSoonEntries,
      () => cubit.state.status.name,
      (id) => SubscriptionEntry(
        id: id,
        name: 'snapshot $id',
        price: id.toDouble(),
        cycle: SubscriptionBillingCycle.monthly,
        nextPaymentDate: _day,
      ),
    );
  },
  'project': () {
    final repository = _ProjectReads();
    final cubit = ProjectCubit(
      loadEntries: LoadProjectEntries(repository),
      watchEntries: WatchProjectEntries(repository),
      saveEntry: SaveProjectEntry(repository),
    );
    return _Harness(
      cubit,
      repository,
      cubit.start,
      cubit.loadEntries,
      () => cubit.state.entries,
      () => cubit.state.status.name,
      (id) => ProjectEntry(
        id: id,
        name: 'snapshot $id',
        status: ProjectEntryStatus.active,
      ),
    );
  },
  'photo': () {
    final repository = _PhotoReads();
    final cubit = PhotoCubit(
      loadEntries: LoadPhotoEntries(repository),
      watchEntries: WatchPhotoEntries(repository),
    );
    return _Harness(
      cubit,
      repository,
      cubit.start,
      cubit.loadEntries,
      () => cubit.state.entries,
      () => cubit.state.status.name,
      (id) => PhotoEntry(
        id: id,
        ownerUserId: 'owner',
        createdAt: _day,
        fileName: '$id.jpg',
        filePath: '/local/$id.jpg',
        description: 'snapshot $id',
        deviceName: 'device',
        projectName: 'project',
        projectId: 1,
        dateIndexed: _day,
      ),
    );
  },
  'evidence': () {
    final repository = _EvidenceReads();
    final cubit = EvidenceCubit(
      loadEntries: LoadEvidenceEntries(repository),
      watchEntries: WatchEvidenceEntries(repository),
    );
    return _Harness(
      cubit,
      repository,
      cubit.start,
      cubit.loadEntries,
      () => cubit.state.entries,
      () => cubit.state.status.name,
      (id) => EvidenceEntry(
        id: id,
        projectName: 'project',
        evidenceDate: _day,
        amount: id.toDouble(),
      ),
    );
  },
  'expense': () {
    final repository = _ExpenseReads();
    final cubit = ExpenseRecordCubit(
      loadEntries: LoadExpenseRecordEntries(repository),
      watchEntries: WatchExpenseRecordEntries(repository),
      initialNow: () => _day,
    );
    return _Harness(
      cubit,
      repository,
      cubit.start,
      cubit.loadEntries,
      () => cubit.state.entries,
      () => cubit.state.status.name,
      (id) => ExpenseRecordEntry(
        id: id,
        expenseDate: _day,
        amount: id.toDouble(),
        projectName: 'project',
      ),
    );
  },
  'subscription': () {
    final repository = _SubscriptionReads();
    final cubit = SubscriptionCubit(
      loadEntries: LoadSubscriptionEntries(repository),
      watchEntries: WatchSubscriptionEntries(repository),
      initialNow: () => _day,
    );
    return _Harness(
      cubit,
      repository,
      cubit.start,
      cubit.loadEntries,
      () => cubit.state.entries,
      () => cubit.state.status.name,
      (id) => SubscriptionEntry(
        id: id,
        name: 'snapshot $id',
        price: id.toDouble(),
        cycle: SubscriptionBillingCycle.monthly,
        nextPaymentDate: _day,
      ),
    );
  },
};

final class _Harness {
  final Cubit<dynamic> cubit;
  final _ReadProbe<dynamic> repository;
  final void Function() start;
  final Future<void> Function() reload;
  final List<Object> Function() entries;
  final String Function() status;
  final Object Function(int) entry;
  _Harness(
    this.cubit,
    this.repository,
    this.start,
    this.reload,
    this.entries,
    this.status,
    this.entry,
  );

  void complete(int index, int id) => repository.complete(index, entry(id));
}

class _ReadProbe<T> {
  final changes = StreamController<void>.broadcast();
  final reads = <Completer<List<T>>>[];
  int _activeReads = 0;
  int maximumActiveReads = 0;

  Future<List<T>> getAllEntries() {
    final read = Completer<List<T>>();
    reads.add(read);
    _activeReads++;
    if (_activeReads > maximumActiveReads) maximumActiveReads = _activeReads;
    return read.future.whenComplete(() => _activeReads--);
  }

  Stream<void> watchEntries() => changes.stream;
  void complete(int index, Object entry) => reads[index].complete([entry as T]);
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

final class _WorkReads extends _ReadProbe<WorkLogEntry>
    implements WorkLogRepositoryPort {
  @override
  Future<List<WorkLogEntry>> getEntriesByMonth(DateTime month) =>
      getAllEntries();
}

final class _ProjectReads extends _ReadProbe<ProjectEntry>
    implements ProjectRepositoryPort {}

final class _PhotoReads extends _ReadProbe<PhotoEntry>
    implements PhotoRepositoryPort {}

final class _EvidenceReads extends _ReadProbe<EvidenceEntry>
    implements EvidenceRepositoryPort {}

final class _ExpenseReads extends _ReadProbe<ExpenseRecordEntry>
    implements ExpenseRecordRepositoryPort {}

final class _SubscriptionReads extends _ReadProbe<SubscriptionEntry>
    implements SubscriptionRepositoryPort {}
