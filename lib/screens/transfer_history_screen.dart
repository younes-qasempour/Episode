import 'package:flutter/material.dart';

import '../models/data_transfer.dart';
import '../repositories/media_transfer_repository.dart';

class TransferHistoryScreen extends StatefulWidget {
  final MediaTransferRepository repository;
  final Future<void> Function(String backupId) onSaveBackup;

  const TransferHistoryScreen({
    super.key,
    required this.repository,
    required this.onSaveBackup,
  });

  @override
  State<TransferHistoryScreen> createState() => _TransferHistoryScreenState();
}

class _TransferHistoryScreenState extends State<TransferHistoryScreen> {
  late Future<_HistoryData> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = _load();
  }

  Future<_HistoryData> _load() async {
    final results = await Future.wait([
      widget.repository.loadHistory(),
      widget.repository.loadAutomaticBackups(),
    ]);
    return _HistoryData(
      history: results[0] as List<TransferHistoryEntry>,
      backups: results[1] as List<AutomaticBackupRecord>,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transfer history')),
      body: FutureBuilder<_HistoryData>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'History could not be loaded',
              message: 'Try opening this screen again.',
              onRetry: () {
                setState(() => _loadFuture = _load());
              },
            );
          }
          final data = snapshot.requireData;
          if (data.history.isEmpty && data.backups.isEmpty) {
            return const _EmptyState(
              icon: Icons.history_rounded,
              title: 'No transfer history yet',
              message: 'Completed imports, restores, backups, and exports '
                  'will appear here.',
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              if (data.backups.isNotEmpty) ...[
                const _SectionTitle(
                  title: 'Automatic safety backups',
                  subtitle: 'The five newest snapshots are retained locally.',
                ),
                ...data.backups.map(
                  (backup) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.shield_outlined),
                    title: Text('${backup.itemCount} media items'),
                    subtitle: Text(_dateTime(backup.createdAt)),
                    trailing: IconButton(
                      tooltip: 'Save safety backup',
                      onPressed: () => widget.onSaveBackup(backup.id),
                      icon: const Icon(Icons.download_rounded),
                    ),
                  ),
                ),
                const Divider(height: 32),
              ],
              const _SectionTitle(
                title: 'Operations',
                subtitle: 'Only summaries are stored; imported file contents '
                    'and private notes are not copied into history.',
              ),
              ...data.history.map(
                (entry) => _HistoryTile(
                  entry: entry,
                  onTap: () => _showDetails(context, entry),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDetails(BuildContext context, TransferHistoryEntry entry) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_operationLabel(entry.operationType)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(entry.fileName ?? entry.providerId),
              const SizedBox(height: 12),
              Text('Processed: ${entry.processed}'),
              Text('Added: ${entry.added}'),
              Text('Updated: ${entry.updated}'),
              Text('Skipped: ${entry.skipped}'),
              Text('Failed: ${entry.failed}'),
              Text('Conflicts: ${entry.conflicts}'),
              if (entry.errorSummary != null) ...[
                const SizedBox(height: 12),
                Text(
                  entry.errorSummary!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              if (entry.warnings.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...entry.warnings.take(10).map(
                      (warning) => Text('• ${warning.message}'),
                    ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final TransferHistoryEntry entry;
  final VoidCallback onTap;

  const _HistoryTile({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (entry.status) {
      TransferResultStatus.success => Colors.green,
      TransferResultStatus.partialSuccess => Colors.orange,
      TransferResultStatus.failed => theme.colorScheme.error,
    };
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        foregroundColor: color,
        child: Icon(_operationIcon(entry.operationType), size: 20),
      ),
      title: Text(_operationLabel(entry.operationType)),
      subtitle: Text(
        '${_dateTime(entry.occurredAt)} · ${entry.processed} processed',
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}

class _HistoryData {
  final List<TransferHistoryEntry> history;
  final List<AutomaticBackupRecord> backups;

  const _HistoryData({required this.history, required this.backups});
}

String _operationLabel(TransferOperationType type) {
  return switch (type) {
    TransferOperationType.importFile => 'File import',
    TransferOperationType.restore => 'Backup restore',
    TransferOperationType.backup => 'Full backup',
    TransferOperationType.export => 'Data export',
  };
}

IconData _operationIcon(TransferOperationType type) {
  return switch (type) {
    TransferOperationType.importFile => Icons.file_download_outlined,
    TransferOperationType.restore => Icons.restore_rounded,
    TransferOperationType.backup => Icons.backup_outlined,
    TransferOperationType.export => Icons.file_upload_outlined,
  };
}

String _dateTime(DateTime value) {
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}';
}
