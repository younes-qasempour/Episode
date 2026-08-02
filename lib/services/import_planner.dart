import '../models/data_transfer.dart';
import '../models/media_item.dart';

class ImportPlanner {
  const ImportPlanner();

  ImportPreview buildPreview(
    ImportInspectionResult inspection,
    List<MediaItem> localItems,
    ImportOptions options,
  ) {
    final externalIndex = <String, List<MediaItem>>{};
    final titleIndex = <String, List<MediaItem>>{};
    final fuzzyIndex = <MediaType, Map<String, List<_FuzzyTitleCandidate>>>{};
    for (final item in localItems) {
      for (final entry in _externalIds(item).entries) {
        externalIndex
            .putIfAbsent('${entry.key}:${entry.value}', () => [])
            .add(item);
      }
      final normalizedTitle = normalizeTitle(item.title);
      titleIndex
          .putIfAbsent('${item.type.name}:$normalizedTitle', () => [])
          .add(item);
      fuzzyIndex
          .putIfAbsent(item.type, () => {})
          .putIfAbsent(_fuzzyPrefix(normalizedTitle), () => [])
          .add(_FuzzyTitleCandidate(item, normalizedTitle));
    }

    final warnings = List<ImportWarning>.from(inspection.warnings);
    final candidates = <ImportCandidate>[];
    for (final imported in inspection.entries) {
      final externalMatches = <MediaItem>{};
      for (final entry in imported.externalIds.entries) {
        externalMatches.addAll(
          externalIndex['${entry.key}:${entry.value}'] ?? const [],
        );
      }
      if (externalMatches.length == 1) {
        candidates.add(
          _candidate(
            imported,
            externalMatches.single,
            'Exact external provider ID',
            true,
            options,
          ),
        );
        continue;
      }
      if (externalMatches.length > 1) {
        candidates.add(
          ImportCandidate(
            imported: imported,
            local: null,
            action: ImportAction.conflict,
            matchReason: 'Multiple local entries use the same provider ID',
            isConfidentMatch: false,
          ),
        );
        continue;
      }

      final titleMatches = titleIndex[_titleKey(
            imported.mediaType,
            imported.title,
          )] ??
          const [];
      if (titleMatches.length == 1) {
        final local = titleMatches.single;
        if (local.progressMode == ProgressMode.seasonal &&
            imported.progress > local.currentProgress) {
          warnings.add(
            ImportWarning(
              'seasonal_progress_preserved',
              'Flat imported progress will not replace local per-season '
                  'progress during safe merge.',
              entryTitle: imported.title,
            ),
          );
        }
        candidates.add(
          _candidate(
            imported,
            local,
            'Exact normalized title and media type',
            true,
            options,
          ),
        );
        continue;
      }
      if (titleMatches.length > 1) {
        candidates.add(
          ImportCandidate(
            imported: imported,
            local: null,
            action: ImportAction.conflict,
            matchReason:
                'Multiple local entries have the same normalized title',
            isConfidentMatch: false,
          ),
        );
        continue;
      }

      final uncertain = _uncertainMatch(
        imported,
        fuzzyIndex[imported.mediaType] ?? const {},
      );
      if (uncertain != null) {
        candidates.add(
          ImportCandidate(
            imported: imported,
            local: uncertain.item,
            action: ImportAction.conflict,
            matchReason: uncertain.comparisonLimited
                ? 'Too many similar-title candidates to compare safely'
                : 'Similar title requires confirmation',
            isConfidentMatch: false,
          ),
        );
        continue;
      }

      candidates.add(
        ImportCandidate(
          imported: imported,
          local: null,
          action: options.strategy == ImportStrategy.replaceMatching
              ? ImportAction.skip
              : ImportAction.add,
          matchReason: 'No existing match',
          isConfidentMatch: true,
        ),
      );
    }

    return ImportPreview(
      inspection: inspection,
      options: options,
      candidates: candidates,
      warnings: warnings,
    );
  }

  ImportApplicationPlan apply(
    List<MediaItem> localItems,
    ImportPreview preview,
  ) {
    if (preview.options.strategy == ImportStrategy.fullRestore) {
      final restored = preview.candidates
          .where((candidate) => candidate.action != ImportAction.invalid)
          .map((candidate) => candidate.imported.toMediaItem())
          .toList(growable: false);
      return ImportApplicationPlan(
        library: restored,
        added: preview.count(ImportAction.add),
        updated: preview.count(ImportAction.update),
        skipped: preview.count(ImportAction.skip),
        failed: preview.count(ImportAction.invalid),
        conflicts: preview.count(ImportAction.conflict),
      );
    }

    final result = List<MediaItem>.from(localItems);
    final additions = <MediaItem>[];
    var added = 0;
    var updated = 0;
    var skipped = 0;
    var failed = 0;
    var conflicts = 0;

    for (final candidate in preview.candidates) {
      switch (candidate.action) {
        case ImportAction.add:
          additions.add(candidate.imported.toMediaItem());
          added++;
        case ImportAction.update:
          final local = candidate.local;
          if (local == null) {
            failed++;
            continue;
          }
          final index = result.indexWhere((item) => item.id == local.id);
          if (index < 0) {
            failed++;
            continue;
          }
          result[index] = resolveConflict(
            local,
            candidate.imported,
            preview.options.conflictPolicy,
          );
          updated++;
        case ImportAction.skip:
          skipped++;
        case ImportAction.conflict:
          conflicts++;
          skipped++;
        case ImportAction.invalid:
          failed++;
      }
    }
    result.insertAll(0, additions);
    return ImportApplicationPlan(
      library: result,
      added: added,
      updated: updated,
      skipped: skipped,
      failed: failed,
      conflicts: conflicts,
    );
  }

  MediaItem resolveConflict(
    MediaItem local,
    ImportedMediaEntry imported,
    ConflictPolicy policy,
  ) {
    if (policy == ConflictPolicy.keepLocal ||
        policy == ConflictPolicy.skipExisting) {
      return local;
    }
    final incoming = imported.toMediaItem(id: local.id);
    final combinedExternalIds = Map<String, String>.from(imported.externalIds)
      ..addAll(local.externalIds);
    if (policy == ConflictPolicy.useImported) {
      return incoming.copyWith(
        coverUrl:
            incoming.coverUrl.isEmpty ? local.coverUrl : incoming.coverUrl,
        synopsis:
            _notEmpty(incoming.synopsis) ? incoming.synopsis : local.synopsis,
        notes: _notEmpty(incoming.notes) ? incoming.notes : local.notes,
        externalIds: combinedExternalIds,
        customMetadata: {
          ...local.customMetadata,
          ...incoming.customMetadata,
        },
      );
    }

    final useImportedProgress = local.progressMode == ProgressMode.flat &&
        incoming.currentProgress > local.currentProgress;
    final tags =
        <String>{...local.tags, ...incoming.tags}.toList(growable: false);
    return local.copyWith(
      currentProgress: useImportedProgress
          ? incoming.currentProgress
          : local.flatCurrentProgress,
      totalCount: local.flatTotalCount ?? incoming.flatTotalCount,
      clearTotalCount:
          local.flatTotalCount == null && incoming.flatTotalCount == null,
      status: _mergedStatus(local, incoming, useImportedProgress),
      releaseStatus: local.releaseStatus == ReleaseStatus.unknown
          ? incoming.releaseStatus
          : local.releaseStatus,
      coverUrl:
          local.coverUrl.trim().isEmpty ? incoming.coverUrl : local.coverUrl,
      synopsis: _notEmpty(local.synopsis) ? local.synopsis : incoming.synopsis,
      rating: local.rating > 0 ? local.rating : incoming.rating,
      externalIds: combinedExternalIds,
      notes: _notEmpty(local.notes) ? local.notes : incoming.notes,
      tags: tags,
      startedAt: _earliest(local.startedAt, incoming.startedAt),
      completedAt: _latest(local.completedAt, incoming.completedAt),
      addedAt: _earliest(local.addedAt, incoming.addedAt),
      updatedAt: _latest(local.updatedAt, incoming.updatedAt),
      repeatCount: local.repeatCount >= incoming.repeatCount
          ? local.repeatCount
          : incoming.repeatCount,
      isFavorite: local.isFavorite || incoming.isFavorite,
      customMetadata: {
        ...incoming.customMetadata,
        ...local.customMetadata,
      },
    );
  }

  ImportCandidate _candidate(
    ImportedMediaEntry imported,
    MediaItem local,
    String reason,
    bool confident,
    ImportOptions options,
  ) {
    final action = switch (options.strategy) {
      ImportStrategy.addOnly => ImportAction.skip,
      ImportStrategy.merge ||
      ImportStrategy.replaceMatching ||
      ImportStrategy.fullRestore =>
        options.conflictPolicy == ConflictPolicy.keepLocal ||
                options.conflictPolicy == ConflictPolicy.skipExisting
            ? ImportAction.skip
            : ImportAction.update,
    };
    return ImportCandidate(
      imported: imported,
      local: local,
      action: action,
      matchReason: reason,
      isConfidentMatch: confident,
    );
  }

  Map<String, String> _externalIds(MediaItem item) {
    final result = Map<String, String>.from(item.externalIds);
    final jikan = RegExp(r'^jikan_(anime|manga)_(\d+)$').firstMatch(item.id);
    if (jikan != null) {
      result.putIfAbsent('mal', () => jikan.group(2)!);
      result.putIfAbsent('jikan', () => jikan.group(2)!);
    }
    final tvmaze = RegExp(r'^tvmaze_series_(\d+)$').firstMatch(item.id);
    if (tvmaze != null) {
      result.putIfAbsent('tvmaze', () => tvmaze.group(1)!);
    }
    return result;
  }

  String _titleKey(MediaType type, String title) =>
      '${type.name}:${normalizeTitle(title)}';

  _UncertainMatch? _uncertainMatch(
    ImportedMediaEntry imported,
    Map<String, List<_FuzzyTitleCandidate>> index,
  ) {
    final target = normalizeTitle(imported.title);
    if (target.length < 6) {
      return null;
    }
    final candidates = index[_fuzzyPrefix(target)] ?? const [];
    if (candidates.length > 250) {
      return const _UncertainMatch(comparisonLimited: true);
    }
    MediaItem? best;
    var bestScore = 0.0;
    for (final candidate in candidates) {
      final other = candidate.normalizedTitle;
      final longest =
          target.length > other.length ? target.length : other.length;
      if (longest == 0 || (target.length - other.length).abs() > longest / 3) {
        continue;
      }
      final score = 1 - (_levenshtein(target, other) / longest);
      if (score > bestScore) {
        bestScore = score;
        best = candidate.item;
      }
    }
    return bestScore >= 0.88 ? _UncertainMatch(item: best) : null;
  }

  String _mergedStatus(
    MediaItem local,
    MediaItem incoming,
    bool useImportedProgress,
  ) {
    if (local.trackingStatus == TrackingStatus.unknown) {
      return incoming.status;
    }
    if (local.trackingStatus == TrackingStatus.completed) {
      return local.status;
    }
    return useImportedProgress ? incoming.status : local.status;
  }

  bool _notEmpty(String? value) => value != null && value.trim().isNotEmpty;

  DateTime? _earliest(DateTime? first, DateTime? second) {
    if (first == null) return second;
    if (second == null) return first;
    return first.isBefore(second) ? first : second;
  }

  DateTime? _latest(DateTime? first, DateTime? second) {
    if (first == null) return second;
    if (second == null) return first;
    return first.isAfter(second) ? first : second;
  }
}

class _FuzzyTitleCandidate {
  final MediaItem item;
  final String normalizedTitle;

  const _FuzzyTitleCandidate(this.item, this.normalizedTitle);
}

class _UncertainMatch {
  final MediaItem? item;
  final bool comparisonLimited;

  const _UncertainMatch({this.item, this.comparisonLimited = false});
}

class ImportApplicationPlan {
  final List<MediaItem> library;
  final int added;
  final int updated;
  final int skipped;
  final int failed;
  final int conflicts;

  const ImportApplicationPlan({
    required this.library,
    required this.added,
    required this.updated,
    required this.skipped,
    required this.failed,
    required this.conflicts,
  });
}

String normalizeTitle(String input) {
  return input
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _fuzzyPrefix(String normalizedTitle) {
  return String.fromCharCodes(normalizedTitle.runes.take(4));
}

int _levenshtein(String first, String second) {
  if (first == second) return 0;
  if (first.isEmpty) return second.length;
  if (second.isEmpty) return first.length;
  var previous = List<int>.generate(second.length + 1, (index) => index);
  for (var i = 0; i < first.length; i++) {
    final current = List<int>.filled(second.length + 1, 0);
    current[0] = i + 1;
    for (var j = 0; j < second.length; j++) {
      final substitution =
          previous[j] + (first.codeUnitAt(i) == second.codeUnitAt(j) ? 0 : 1);
      final insertion = current[j] + 1;
      final deletion = previous[j + 1] + 1;
      current[j + 1] = substitution < insertion
          ? (substitution < deletion ? substitution : deletion)
          : (insertion < deletion ? insertion : deletion);
    }
    previous = current;
  }
  return previous.last;
}
