import 'package:flutter/material.dart';

import 'store.dart';

class BackupsScreen extends StatefulWidget {
  final LinkStore store;
  const BackupsScreen({super.key, required this.store});

  @override
  State<BackupsScreen> createState() => _BackupsScreenState();
}

class _BackupsScreenState extends State<BackupsScreen> {
  late Future<List<BackupInfo>> _backups;

  LinkStore get store => widget.store;

  @override
  void initState() {
    super.initState();
    _backups = store.listBackups();
  }

  void _refresh() {
    setState(() => _backups = store.listBackups());
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(milliseconds: 2200)));
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final p = (int n) => n.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month - 1]} ${d.year}, ${p(d.hour)}:${p(d.minute)}';
  }

  void _confirmRestore(BackupInfo backup) {
    showDialog<void>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: const Text('Restore backup?'),
        content: const Text(
            'Your current links and categories will be replaced with the contents of this backup.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dlgCtx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dlgCtx);
              final err = await store.restoreBackup(backup.fileName);
              _snack(err ?? 'Backup restored');
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BackupInfo backup) {
    showDialog<void>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: const Text('Delete backup?'),
        content: Text('"${backup.fileName}" will be removed permanently.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dlgCtx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dlgCtx).colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(dlgCtx);
              store.deleteBackup(backup.fileName);
              _refresh();
              _snack('Backup deleted');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backups & restore')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final msg = await store.backupNow();
          _refresh();
          _snack(msg);
        },
        icon: const Icon(Icons.backup_outlined),
        label: const Text('Back up now'),
      ),
      body: FutureBuilder<List<BackupInfo>>(
        future: _backups,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final backups = snap.data ?? [];
          if (backups.isEmpty) {
            return Center(
              child: Text(
                'No backups yet.\nOne is created automatically each day you open the app.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).hintColor),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: backups.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final b = backups[i];
              return Material(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Theme.of(context).dividerTheme.color ?? Colors.transparent,
                    ),
                  ),
                  leading: const Icon(Icons.history),
                  title: Text(
                    _formatDate(b.modified),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    '${(b.sizeBytes / 1024).toStringAsFixed(1)} KB',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Restore',
                        icon: const Icon(Icons.restore),
                        onPressed: () => _confirmRestore(b),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        icon: Icon(
                          Icons.delete_outline,
                          size: 19,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        onPressed: () => _confirmDelete(b),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
