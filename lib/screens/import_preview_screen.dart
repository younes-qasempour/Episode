import 'package:flutter/material.dart';

import '../models/data_transfer.dart';
import '../models/media_item.dart';
import '../theme/app_theme.dart';

class ImportPreviewScreen extends StatefulWidget {
  final ImportInspectionResult inspection;
  final ImportPreview Function(ImportOptions options) buildPreview;
  final bool restoreFlow;

  const ImportPreviewScreen({
    super.key,
    required this.inspection,
    required this.buildPreview,
    this.restoreFlow = false,
  });

  @override
  State<ImportPreviewScreen> createState() => _ImportPreviewScreenState();
}

class _ImportPreviewScreenState extends State<ImportPreviewScreen> {
  late ImportOptions _options;
  late ImportPreview _preview;

  @override
  void initState() {
    super.initState();
    _options = ImportOptions(
      strategy: widget.restoreFlow
          ? ImportStrategy.fullRestore
          : ImportStrategy.merge,
    );
    _refreshPreview();
  }

  void _refreshPreview() {
    _preview = widget.buildPreview(_options);
  }

  void _setStrategy(ImportStrategy? strategy) {
    if (strategy == null) return;
    setState(() {
      _options = _options.copyWith(strategy: strategy);
      _refreshPreview();
    });
  }

  void _setConflictPolicy(ConflictPolicy? policy) {
    if (policy == null) return;
    setState(() {
      _options = _options.copyWith(conflictPolicy: policy);
      _refreshPreview();
    });
  }

  Future<void> _confirm() async {
    if (_options.strategy == ImportStrategy.fullRestore) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Replace the current library?'),
          content: const Text(
            'OtakuLog will create a safety backup first. The selected backup '
            'will then replace the active library.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Create backup & restore'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    Navigator.of(context).pop(_preview);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasConflicts = _preview.count(ImportAction.conflict) > 0;
    final canApply = _preview.candidates.isNotEmpty ||
        (_options.strategy == ImportStrategy.fullRestore &&
            widget.inspection.sourceType == ImportSourceType.nativeBackup);

    return Scaffold(
      appBar: AppBar(title: const Text('Review import')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  Text(
                    widget.inspection.providerName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.inspection.sourceType.label} · '
                    '${widget.inspection.fileName}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SummaryStrip(preview: _preview),
                  const SizedBox(height: 24),
                  Text(
                    'Import behavior',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ImportStrategy>(
                    key: const Key('import-strategy-field'),
                    initialValue: _options.strategy,
                    decoration: const InputDecoration(labelText: 'Strategy'),
                    items: _allowedStrategies()
                        .map(
                          (strategy) => DropdownMenuItem(
                            value: strategy,
                            child: Text(strategy.label),
                          ),
                        )
                        .toList(),
                    onChanged: _setStrategy,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ConflictPolicy>(
                    key: const Key('conflict-policy-field'),
                    initialValue: _options.conflictPolicy,
                    decoration: const InputDecoration(
                      labelText: 'Existing entry policy',
                    ),
                    items: ConflictPolicy.values
                        .map(
                          (policy) => DropdownMenuItem(
                            value: policy,
                            child: Text(policy.label),
                          ),
                        )
                        .toList(),
                    onChanged: _options.strategy == ImportStrategy.fullRestore
                        ? null
                        : _setConflictPolicy,
                  ),
                  const SizedBox(height: 12),
                  _SafetyNote(
                    destructive:
                        _options.strategy == ImportStrategy.fullRestore,
                    hasConflicts: hasConflicts,
                  ),
                  if (_preview.warnings.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Warnings',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._preview.warnings.take(6).map(
                          (warning) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  size: 18,
                                  color: theme.colorScheme.tertiary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    warning.entryTitle == null
                                        ? warning.message
                                        : '${warning.entryTitle}: ${warning.message}',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    if (_preview.warnings.length > 6)
                      Text(
                        '+ ${_preview.warnings.length - 6} more warnings in the result report',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Entry preview',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_preview.candidates.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'This file contains no media entries.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    ..._preview.candidates.take(100).map(
                          (candidate) => _CandidateRow(candidate: candidate),
                        ),
                  if (_preview.candidates.length > 100)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'Showing the first 100 of ${_preview.candidates.length} entries. '
                        'All entries will be processed.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('confirm-import-button'),
                  onPressed: canApply ? _confirm : null,
                  icon: Icon(
                    _options.strategy == ImportStrategy.fullRestore
                        ? Icons.restore_rounded
                        : Icons.download_done_rounded,
                  ),
                  label: Text(
                    _options.strategy == ImportStrategy.fullRestore
                        ? 'Create backup & restore'
                        : 'Create backup & import',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<ImportStrategy> _allowedStrategies() {
    if (widget.inspection.sourceType == ImportSourceType.nativeBackup) {
      return const [
        ImportStrategy.merge,
        ImportStrategy.addOnly,
        ImportStrategy.replaceMatching,
        ImportStrategy.fullRestore,
      ];
    }
    return const [
      ImportStrategy.merge,
      ImportStrategy.addOnly,
      ImportStrategy.replaceMatching,
    ];
  }
}

class _SummaryStrip extends StatelessWidget {
  final ImportPreview preview;

  const _SummaryStrip({required this.preview});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final existingCount =
        preview.candidates.where((candidate) => candidate.local != null).length;
    final metrics = [
      ('Entries', preview.candidates.length),
      if (preview.animeCount > 0) ('Anime', preview.animeCount),
      if (preview.mangaCount > 0) ('Manga', preview.mangaCount),
      if (preview.seriesCount > 0) ('Series', preview.seriesCount),
      if (preview.movieCount > 0) ('Movies', preview.movieCount),
      ('New', preview.count(ImportAction.add)),
      ('Existing', existingCount),
      ('Updates', preview.count(ImportAction.update)),
      ('Conflicts', preview.count(ImportAction.conflict)),
      ('Skipped', preview.count(ImportAction.skip)),
      ('Warnings', preview.warnings.length),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 14,
        children: metrics
            .map(
              (metric) => SizedBox(
                width: 76,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${metric.$2}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      metric.$1,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _SafetyNote extends StatelessWidget {
  final bool destructive;
  final bool hasConflicts;

  const _SafetyNote({required this.destructive, required this.hasConflicts});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        destructive ? theme.colorScheme.error : AppTheme.primaryIndigo;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            destructive ? Icons.shield_outlined : Icons.verified_user_outlined,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              destructive
                  ? 'Full restore replaces the active library after a verified '
                      'safety backup is retained locally.'
                  : hasConflicts
                      ? 'Uncertain matches are never merged automatically and '
                          'will be skipped.'
                      : 'Existing progress and notes are preserved by the safe '
                          'merge policy.',
            ),
          ),
        ],
      ),
    );
  }
}

class _CandidateRow extends StatelessWidget {
  final ImportCandidate candidate;

  const _CandidateRow({required this.candidate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, color) = switch (candidate.action) {
      ImportAction.add => ('Add', Colors.green),
      ImportAction.update => ('Update', theme.colorScheme.primary),
      ImportAction.skip => ('Skip', theme.colorScheme.onSurfaceVariant),
      ImportAction.conflict => ('Review', Colors.orange),
      ImportAction.invalid => ('Invalid', theme.colorScheme.error),
    };
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  candidate.imported.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${candidate.imported.mediaType.label} · '
                  '${candidate.imported.progress} / '
                  '${candidate.imported.totalUnits ?? '?'} · '
                  '${candidate.matchReason}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.chipRadius),
            ),
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
