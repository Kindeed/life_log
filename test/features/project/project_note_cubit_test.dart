import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:life_log/features/project/application/delete_project_note_entry.dart';
import 'package:life_log/features/project/application/load_project_note_entries.dart';
import 'package:life_log/features/project/application/save_project_note_entry.dart';
import 'package:life_log/features/project/application/watch_project_note_entries.dart';
import 'package:life_log/features/project/domain/entities/project_note_entry.dart';
import 'package:life_log/features/project/domain/entities/project_record_scope.dart';
import 'package:life_log/features/project/domain/repositories/project_note_repository_port.dart';
import 'package:life_log/features/project/presentation/project_note_cubit.dart';
import 'package:life_log/features/project/project_feature_di.dart';

void main() {
  const a = ProjectRecordScope(name: '设备项目', id: 1, syncId: 'project-a');
  const b = ProjectRecordScope(name: '设备项目', id: 2, syncId: 'project-b');

  test(
    'optional loaders leave an empty state and start is idempotent',
    () async {
      final cubit = ProjectNoteCubit(scope: a);
      cubit.start();
      cubit.start();
      await cubit.loadEntries();
      expect(cubit.state.entries, isEmpty);
      expect(cubit.state.loading, isFalse);
      expect(cubit.state.failure, isNull);
      await cubit.close();
      cubit.start();
    },
  );

  test(
    'scope switches clear previous notes and reject a delayed namesake read',
    () async {
      final repository = _Repository();
      final pendingA = Completer<List<ProjectNoteEntry>>();
      final pendingB = Completer<List<ProjectNoteEntry>>();
      repository.pending[a.id!] = pendingA;
      repository.pending[b.id!] = pendingB;
      final cubit = ProjectNoteCubit(
        scope: a,
        loadEntries: LoadProjectNoteEntries(repository),
      );
      final oldRead = cubit.loadEntries();
      cubit.setProject(b);
      expect(cubit.scope, b);
      expect(cubit.state.entries, isEmpty);
      expect(cubit.state.loading, isTrue);
      pendingB.complete([_note(b, 'B记录')]);
      await _settle();
      expect(cubit.state.entries.single.content, 'B记录');
      pendingA.complete([_note(a, 'A迟到记录')]);
      await oldRead;
      expect(cubit.state.entries.single.content, 'B记录');
      await cubit.close();
      await repository.close();
    },
  );

  test(
    'background refresh preserves entries and does not emit a spinner',
    () async {
      final repository = _Repository()..entries = [_note(a, '已加载记录')];
      final cubit = ProjectNoteCubit(
        scope: a,
        loadEntries: LoadProjectNoteEntries(repository),
      );
      await cubit.loadEntries();
      final pending = Completer<List<ProjectNoteEntry>>();
      repository.pending[a.id!] = pending;
      final refresh = cubit.loadEntries(background: true);
      expect(cubit.state.entries.single.content, '已加载记录');
      expect(cubit.state.loading, isFalse);
      pending.complete([_note(a, '刷新后的记录')]);
      await refresh;
      expect(cubit.state.entries.single.content, '刷新后的记录');
      await cubit.close();
      await repository.close();
    },
  );

  test('watch updates only this project and closes the subscription', () async {
    final repository = _Repository()..entries = [_note(a, '第一条')];
    final cubit = ProjectNoteCubit(
      scope: a,
      loadEntries: LoadProjectNoteEntries(repository),
      watchEntries: WatchProjectNoteEntries(repository),
    );
    cubit.start();
    cubit.start();
    await _settle();
    expect(repository.reads, 1);
    repository.entries = [_note(a, '第二条'), _note(b, '另一项目')];
    repository.changes.add(null);
    await _settle();
    expect(cubit.state.entries.single.content, '第二条');
    final reads = repository.reads;
    await cubit.close();
    repository.changes.add(null);
    await _settle();
    expect(repository.reads, reads);
    await repository.close();
  });

  test('read errors keep existing notes with a retryable failure', () async {
    final repository = _Repository()..entries = [_note(a, '已加载记录')];
    final cubit = ProjectNoteCubit(
      scope: a,
      loadEntries: LoadProjectNoteEntries(repository),
    );
    await cubit.loadEntries();
    repository.failure = StateError('database unavailable');
    await cubit.loadEntries(background: true);
    expect(cubit.state.failure?.code, 'project/load-notes');
    expect(cubit.state.entries.single.content, '已加载记录');
    repository.failure = null;
    await cubit.loadEntries();
    expect(cubit.state.failure, isNull);
    await cubit.close();
    await repository.close();
  });

  test(
    'closing while a note read is pending prevents late state emissions',
    () async {
      final repository = _Repository();
      final pending = Completer<List<ProjectNoteEntry>>();
      repository.pending[a.id!] = pending;
      final cubit = ProjectNoteCubit(
        scope: a,
        loadEntries: LoadProjectNoteEntries(repository),
      );
      final read = cubit.loadEntries();
      await cubit.close();
      pending.complete([_note(a, '迟到记录')]);
      await read;
      expect(cubit.state.entries, isEmpty);
      await repository.close();
    },
  );

  test(
    'account scope events clear cached notes before the replacement read finishes',
    () async {
      final scopeChanges = StreamController<void>.broadcast(sync: true);
      final repository = _Repository()..entries = [_note(a, 'A缓存记录')];
      final cubit = ProjectNoteCubit(
        scope: a,
        loadEntries: LoadProjectNoteEntries(repository),
        watchEntries: WatchProjectNoteEntries(
          repository,
          watchScope: () => scopeChanges.stream,
        ),
      );
      cubit.start();
      await _settle();
      expect(cubit.state.entries.single.content, 'A缓存记录');
      final replacement = Completer<List<ProjectNoteEntry>>();
      repository.pending[a.id!] = replacement;
      scopeChanges.add(null);
      expect(cubit.state.entries, isEmpty);
      expect(cubit.state.loading, isTrue);
      replacement.complete([_note(a, 'B当前记录')]);
      await _settle();
      expect(cubit.state.entries.single.content, 'B当前记录');
      await cubit.close();
      await scopeChanges.close();
      await repository.close();
    },
  );

  test(
    'a blocked old-project refresh cannot prevent a new-project watch update',
    () async {
      final repository = _Repository()..entries = [_note(a, 'A首条')];
      final cubit = ProjectNoteCubit(
        scope: a,
        loadEntries: LoadProjectNoteEntries(repository),
        watchEntries: WatchProjectNoteEntries(repository),
      );
      cubit.start();
      await _settle();
      final blockedA = Completer<List<ProjectNoteEntry>>();
      repository.pending[a.id!] = blockedA;
      repository.changes.add(null);
      await _settle();
      repository.entries = [_note(b, 'B首条')];
      cubit.setProject(b);
      await _settle();
      expect(cubit.state.entries.single.content, 'B首条');
      repository.entries = [_note(b, 'B后续更新')];
      repository.changes.add(null);
      await _settle();
      expect(cubit.state.entries.single.content, 'B后续更新');
      blockedA.complete([_note(a, 'A迟到旧背景')]);
      await _settle();
      expect(cubit.state.entries.single.content, 'B后续更新');
      await cubit.close();
      await repository.close();
    },
  );

  test(
    'context failures clear notes while ordinary read failures retain them',
    () async {
      final repository = _Repository()..entries = [_note(a, 'A缓存记录')];
      final cubit = ProjectNoteCubit(
        scope: a,
        loadEntries: LoadProjectNoteEntries(repository),
      );
      await cubit.loadEntries();
      repository.failure = ProjectNoteContextChanged();
      await cubit.loadEntries(background: true);
      expect(cubit.state.entries, isEmpty);
      expect(cubit.state.failure!.code, 'project/notes-context-changed');
      await cubit.close();
      await repository.close();
    },
  );

  test(
    'save and delete return domain failures without losing the caller draft',
    () async {
      final repository = _Repository()..failure = StateError('项目已不存在');
      final draft = _note(a, '需要保留草稿');
      final save = await SaveProjectNoteEntry(repository)(draft);
      expect(save.failureOrNull?.code, 'project/save-note');
      expect(save.failureOrNull?.message, '项目已不存在');
      expect(draft.content, '需要保留草稿');
      final delete = await DeleteProjectNoteEntry(repository)(draft.id);
      expect(delete.failureOrNull?.code, 'project/delete-note');
      repository.failure = null;
      expect((await SaveProjectNoteEntry(repository)(draft)).isSuccess, isTrue);
      expect(
        (await DeleteProjectNoteEntry(repository)(draft.id)).isSuccess,
        isTrue,
      );
      await repository.close();
    },
  );

  test(
    'DI supplies note commands using the injected local repository',
    () async {
      final locator = GetIt.asNewInstance();
      final repository = _Repository()..entries = [_note(a, '依赖注入记录')];
      configureProjectFeatureDependencies(
        locator: locator,
        noteRepository: repository,
      );
      final loaded = await locator<LoadProjectNoteEntries>()(a);
      expect(loaded.valueOrNull!.single.content, '依赖注入记录');
      expect(
        locator<WatchProjectNoteEntries>(),
        isA<WatchProjectNoteEntries>(),
      );
      expect(locator<SaveProjectNoteEntry>(), isA<SaveProjectNoteEntry>());
      expect(locator<DeleteProjectNoteEntry>(), isA<DeleteProjectNoteEntry>());
      await locator.reset();
      await repository.close();
    },
  );
}

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 5));

ProjectNoteEntry _note(ProjectRecordScope scope, String content) =>
    ProjectNoteEntry(
      id: scope.id! * 10,
      projectId: scope.id,
      projectSyncId: scope.syncId,
      projectName: scope.name,
      content: content,
      date: DateTime(2026, 10, 11),
      createdAt: DateTime(2026, 10, 11),
      updatedAt: DateTime(2026, 10, 11),
    );

final class _Repository implements ProjectNoteRepositoryPort {
  final changes = StreamController<void>.broadcast();
  final pending = <int, Completer<List<ProjectNoteEntry>>>{};
  List<ProjectNoteEntry> entries = [];
  Object? failure;
  int reads = 0;

  @override
  Future<List<ProjectNoteEntry>> getEntries(ProjectRecordScope scope) async {
    reads++;
    if (failure != null) throw failure!;
    final read = pending[scope.id];
    if (read != null) return read.future;
    return entries.where((entry) => entry.projectId == scope.id).toList();
  }

  @override
  Stream<void> watchEntries() => changes.stream;

  @override
  Object? captureContext() => null;

  @override
  Future<ProjectNoteEntry> saveEntry(
    ProjectNoteEntry entry, {
    Object? expectedContext,
  }) async {
    if (failure != null) throw failure!;
    entries.add(entry);
    return entry;
  }

  @override
  Future<void> deleteEntry(int id, {Object? expectedContext}) async {
    if (failure != null) throw failure!;
    entries.removeWhere((entry) => entry.id == id);
  }

  Future<void> close() => changes.close();
}
