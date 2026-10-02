import 'package:life_log/core/sync/sync_run_context.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class SyncConflictRemoteGateway {
  Future<Map<String, dynamic>?> fetch({
    required SyncRunContext context,
    required String table,
    required String syncId,
  });
}

final class SupabaseSyncConflictRemoteGateway
    implements SyncConflictRemoteGateway {
  final SupabaseClient client;

  const SupabaseSyncConflictRemoteGateway(this.client);

  @override
  Future<Map<String, dynamic>?> fetch({
    required SyncRunContext context,
    required String table,
    required String syncId,
  }) async {
    context.checkCurrent();
    final row = await client
        .from(table)
        .select()
        .eq('user_id', context.ownerId)
        .eq('sync_id', syncId)
        .maybeSingle();
    context.checkCurrent();
    if (row != null) context.checkRemoteRow(row);
    return row;
  }
}
