import 'package:flutter/material.dart';

/// UI draft protection; unrelated to persisted cloud-sync dirty metadata.
class AppUnsavedChangesGuard extends StatefulWidget {
  final bool hasChanges;
  final bool busy;
  final Widget child;
  const AppUnsavedChangesGuard({
    super.key,
    required this.hasChanges,
    this.busy = false,
    required this.child,
  });
  @override
  State<AppUnsavedChangesGuard> createState() => _AppUnsavedChangesGuardState();
}

class _AppUnsavedChangesGuardState extends State<AppUnsavedChangesGuard> {
  bool _asking = false;
  bool _allowExit = false;

  Future<void> _requestExit() async {
    if (_asking || widget.busy) return;
    _asking = true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('放弃未保存的修改？'),
        content: const Text('返回后，本次输入的内容不会保存。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('继续编辑'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('放弃修改'),
          ),
        ],
      ),
    );
    _asking = false;
    if (!mounted || discard != true) return;
    setState(() => _allowExit = true);
    // Rebuild PopScope before asking the navigator to leave the guarded route.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: _allowExit || (!widget.busy && !widget.hasChanges),
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _requestExit();
    },
    child: widget.child,
  );
}
