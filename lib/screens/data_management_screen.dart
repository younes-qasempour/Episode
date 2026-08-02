import 'package:flutter/material.dart';

import '../models/data_transfer.dart';
import '../models/media_item.dart';
import '../repositories/local_storage_repository.dart';
import '../repositories/media_transfer_repository.dart';
import '../services/file_transfer_service.dart';
import '../theme/app_theme.dart';
import 'import_preview_screen.dart';
import 'transfer_history_screen.dart';

class DataManagementScreen extends StatefulWidget {
  final List<MediaItem> mediaItems;
  final LocalStorageRepository storageRepository;
  final ValueChanged<List<MediaItem>> onLibraryChanged;
  final MediaTransferRepository? transferRepository;
  final FileTransferService? fileTransferService;

  const DataManagementScreen({
    super.key,
    required this.mediaItems,
    required this.storageRepository,
    required this.onLibraryChanged,
    this.transferRepository,
    this.fileTransferService,
  });

  @override
  State<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  late final FileTransferService _files;
  late final MediaTransferRepository _transfers;
  late List<MediaItem> _items;
  bool _busy = false;
  TransferStage _stage = TransferStage.readingFile;

  @override
  void initState() {
    super.initState();
    _items = List<MediaItem>.from(widget.mediaItems);
    _files = widget.fileTransferService ?? FileTransferService();
    _transfers = widget.transferRepository ??
        MediaTransferRepository(
          storageRepository: widget.storageRepository,
          platform: _files.platformLabel,
        );
  }

  void _setStage(TransferStage stage) {
    if (!mounted) return;
    setState(() {
      _busy = true;
      _stage = stage;
    });
  }

  void _stopBusy() {
    if (!mounted) return;
    setState(() => _busy = false);
  }

  Future<void> _pickAndPreview({
    required bool restoreFlow,
    bool malOnly = false,
  }) async {
    try {
      _setStage(TransferStage.readingFile);
      final source = await _files.pickImportFile(
        allowedExtensions: restoreFlow
            ? const ['json']
            : malOnly
                ? const ['xml', 'gz']
                : const ['json', 'xml', 'gz'],
      );
      if (source == null) {
        _stopBusy();
        return;
      }
      final inspection = await _transfers.inspectSource(
        source,
        onStage: _setStage,
      );
      if (restoreFlow &&
          inspection.sourceType != ImportSourceType.nativeBackup) {
        throw const DataTransferException(
          'Restore accepts only a native OtakuLog JSON backup.',
          code: 'restore_format_required',
        );
      }
      if (malOnly && inspection.sourceType == ImportSourceType.nativeBackup) {
        throw const DataTransferException(
          'Choose a MyAnimeList anime or manga XML export.',
          code: 'mal_format_required',
        );
      }
      _stopBusy();
      if (!mounted) return;
      final preview = await Navigator.of(context).push<ImportPreview>(
        MaterialPageRoute(
          builder: (context) => ImportPreviewScreen(
            inspection: inspection,
            restoreFlow: restoreFlow,
            buildPreview: (options) => _transfers.buildPreview(
              inspection,
              _items,
              options,
            ),
          ),
        ),
      );
      if (preview == null || !mounted) return;
      final result = await _transfers.applyPreview(
        preview,
        onStage: _setStage,
      );
      _stopBusy();
      if (result.status != TransferResultStatus.failed) {
        _items = List<MediaItem>.from(result.library);
        widget.onLibraryChanged(_items);
      }
      if (mounted) {
        await _showImportResult(result);
      }
    } catch (error) {
      _stopBusy();
      if (mounted) {
        _showError(_messageFor(error));
      }
    }
  }

  Future<void> _createBackup() async {
    await _export(
      () => _transfers.createNativeBackup(_items),
      successLabel: 'Backup saved',
      providerId: 'otakulog-native',
      operationType: TransferOperationType.backup,
    );
  }

  Future<void> _exportCsv() async {
    await _export(
      () => _transfers.createCsvExport(_items),
      successLabel: 'CSV export saved',
      providerId: 'csv',
    );
  }

  Future<void> _exportMal(MediaType type) async {
    await _export(
      () => _transfers.createMalExport(_items, type),
      successLabel: '${type.label} XML export saved',
      providerId: 'myanimelist-xml',
    );
  }

  Future<void> _export(
    Future<ExportArtifact> Function() create, {
    required String successLabel,
    required String providerId,
    TransferOperationType operationType = TransferOperationType.export,
  }) async {
    try {
      _setStage(TransferStage.finalizing);
      final artifact = await create();
      final saved = await _files.saveArtifact(artifact);
      if (saved) {
        try {
          await _transfers.recordCompletedExport(
            providerId: providerId,
            artifact: artifact,
            operationType: operationType,
          );
        } catch (_) {
          // History is secondary to a completed platform save.
        }
      }
      _stopBusy();
      if (!mounted) return;
      final skipped = artifact.skippedCount == 0
          ? ''
          : ' ${artifact.skippedCount} unsupported entries were skipped.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(saved ? '$successLabel.$skipped' : 'Save cancelled.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      _stopBusy();
      if (mounted) _showError(_messageFor(error));
    }
  }

  Future<void> _saveSafetyBackup(String id) async {
    try {
      final artifact = await _transfers.automaticBackupArtifact(id);
      final saved = await _files.saveArtifact(artifact);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(saved ? 'Safety backup saved.' : 'Save cancelled.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (error) {
      if (mounted) _showError(_messageFor(error));
    }
  }

  Future<void> _showImportResult(ImportResult result) async {
    final theme = Theme.of(context);
    final success = result.status != TransferResultStatus.failed;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          success ? Icons.check_circle_outline_rounded : Icons.error_outline,
          color: success ? Colors.green : theme.colorScheme.error,
          size: 36,
        ),
        title: Text(
          switch (result.status) {
            TransferResultStatus.success => 'Transfer complete',
            TransferResultStatus.partialSuccess =>
              'Transfer completed with warnings',
            TransferResultStatus.failed => 'Transfer failed safely',
          },
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (result.errorSummary != null) ...[
                Text(result.errorSummary!),
                const SizedBox(height: 12),
              ],
              _ResultRow(label: 'Processed', value: result.processed),
              _ResultRow(label: 'Added', value: result.added),
              _ResultRow(label: 'Updated', value: result.updated),
              _ResultRow(label: 'Skipped', value: result.skipped),
              _ResultRow(label: 'Conflicts', value: result.conflicts),
              _ResultRow(label: 'Failed', value: result.failed),
              if (result.warnings.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Warnings',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                ...result.warnings.take(6).map(
                      (warning) => Text('• ${warning.message}'),
                    ),
              ],
            ],
          ),
        ),
        actions: [
          if (result.safetyBackupId != null)
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _saveSafetyBackup(result.safetyBackupId!);
              },
              child: const Text('Save safety backup'),
            ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.error_outline_rounded,
          color: Theme.of(context).colorScheme.error,
        ),
        title: const Text('Unable to continue'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _messageFor(Object error) {
    if (error is DataTransferException) return error.message;
    if (error is StorageCorruptionException) return error.message;
    if (error is StorageWriteException) return error.message;
    return 'The operation could not be completed. No library changes were made.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: const Text('Data, Backup & Transfer')),
        body: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(AppTheme.cardRadius),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_items.length} media items stored locally',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Files stay on this device. Every import and '
                                  'restore creates a verified safety backup first.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const _SectionHeading(
                      title: 'Import & restore',
                      subtitle: 'Inspect changes before anything is written.',
                    ),
                    _ActionGroup(
                      children: [
                        _ActionTile(
                          key: const Key('import-mal-action'),
                          icon: Icons.playlist_add_rounded,
                          title: 'Import from MyAnimeList',
                          subtitle:
                              'Anime or manga XML, including gzip exports',
                          onTap: () => _pickAndPreview(
                            restoreFlow: false,
                            malOnly: true,
                          ),
                        ),
                        _ActionTile(
                          key: const Key('import-file-action'),
                          icon: Icons.file_open_outlined,
                          title: 'Import compatible file',
                          subtitle: 'OtakuLog JSON or MyAnimeList XML',
                          onTap: () => _pickAndPreview(restoreFlow: false),
                        ),
                        _ActionTile(
                          key: const Key('restore-backup-action'),
                          icon: Icons.restore_rounded,
                          title: 'Restore an OtakuLog backup',
                          subtitle: 'Validate, preview, snapshot, then replace',
                          onTap: () => _pickAndPreview(restoreFlow: true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const _SectionHeading(
                      title: 'Export',
                      subtitle: 'Save a complete backup or a portable list.',
                    ),
                    _ActionGroup(
                      children: [
                        _ActionTile(
                          key: const Key('create-backup-action'),
                          icon: Icons.backup_outlined,
                          title: 'Create full backup',
                          subtitle:
                              'Versioned JSON with SHA-256 integrity check',
                          onTap: _createBackup,
                        ),
                        _ActionTile(
                          key: const Key('export-csv-action'),
                          icon: Icons.table_view_outlined,
                          title: 'Export readable CSV',
                          subtitle: 'All media and metadata in UTF-8',
                          onTap: _exportCsv,
                        ),
                        _ActionTile(
                          icon: Icons.animation_outlined,
                          title: 'Export MAL anime XML',
                          subtitle: 'Entries with a known MyAnimeList ID',
                          onTap: () => _exportMal(MediaType.anime),
                        ),
                        _ActionTile(
                          icon: Icons.menu_book_outlined,
                          title: 'Export MAL manga XML',
                          subtitle: 'Entries with a known MyAnimeList ID',
                          onTap: () => _exportMal(MediaType.manga),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const _SectionHeading(
                      title: 'Recovery & audit',
                      subtitle: 'Review results and retained local snapshots.',
                    ),
                    _ActionGroup(
                      children: [
                        _ActionTile(
                          key: const Key('transfer-history-action'),
                          icon: Icons.history_rounded,
                          title: 'View transfer history',
                          subtitle: 'Latest reports and five safety backups',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => TransferHistoryScreen(
                                repository: _transfers,
                                onSaveBackup: _saveSafetyBackup,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'MyAnimeList account connection is not enabled. It '
                      'requires a registered OAuth client, redirect URI, and '
                      'secure token storage; local file import remains available.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_busy)
              ColoredBox(
                color: theme.colorScheme.scrim.withValues(alpha: 0.38),
                child: Center(
                  child: Container(
                    width: 260,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: Text(
                            _stage.label,
                            key: ValueKey(_stage),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeading({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
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

class _ActionGroup extends StatelessWidget {
  final List<Widget> children;

  const _ActionGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index < children.length - 1)
              const Divider(height: 1, indent: 64),
          ],
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      minVerticalPadding: 14,
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final int value;

  const _ResultRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text('$value', style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
