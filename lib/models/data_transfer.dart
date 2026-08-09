import 'dart:typed_data';

import 'media_item.dart';

enum ImportSourceType { nativeBackup, malAnime, malManga }

extension ImportSourceTypeDetails on ImportSourceType {
  String get label {
    switch (this) {
      case ImportSourceType.nativeBackup:
        return 'Episode backup';
      case ImportSourceType.malAnime:
        return 'MyAnimeList anime';
      case ImportSourceType.malManga:
        return 'MyAnimeList manga';
    }
  }
}

enum ImportStrategy { merge, addOnly, replaceMatching, fullRestore }

extension ImportStrategyDetails on ImportStrategy {
  String get label {
    switch (this) {
      case ImportStrategy.merge:
        return 'Merge with library';
      case ImportStrategy.addOnly:
        return 'Add only new entries';
      case ImportStrategy.replaceMatching:
        return 'Replace matching entries';
      case ImportStrategy.fullRestore:
        return 'Full restore';
    }
  }
}

enum ConflictPolicy { mergeSafe, keepLocal, useImported, skipExisting }

extension ConflictPolicyDetails on ConflictPolicy {
  String get label {
    switch (this) {
      case ConflictPolicy.mergeSafe:
        return 'Merge safely';
      case ConflictPolicy.keepLocal:
        return 'Keep local data';
      case ConflictPolicy.useImported:
        return 'Use imported data';
      case ConflictPolicy.skipExisting:
        return 'Skip existing entries';
    }
  }
}

enum ImportAction { add, update, skip, conflict, invalid }

enum TransferOperationType { importFile, restore, backup, export }

enum TransferResultStatus { success, partialSuccess, failed }

enum TransferStage {
  readingFile,
  validating,
  parsing,
  matching,
  creatingBackup,
  importing,
  finalizing,
}

extension TransferStageDetails on TransferStage {
  String get label {
    switch (this) {
      case TransferStage.readingFile:
        return 'Reading file';
      case TransferStage.validating:
        return 'Validating format';
      case TransferStage.parsing:
        return 'Parsing entries';
      case TransferStage.matching:
        return 'Matching library entries';
      case TransferStage.creatingBackup:
        return 'Creating safety backup';
      case TransferStage.importing:
        return 'Applying changes';
      case TransferStage.finalizing:
        return 'Finalizing library';
    }
  }
}

class ImportSource {
  final String fileName;
  final Uint8List bytes;
  final String? mimeType;

  const ImportSource({
    required this.fileName,
    required this.bytes,
    this.mimeType,
  });

  String get extension {
    final index = fileName.lastIndexOf('.');
    return index < 0 ? '' : fileName.substring(index + 1).toLowerCase();
  }
}

class ImportOptions {
  final ImportStrategy strategy;
  final ConflictPolicy conflictPolicy;

  const ImportOptions({
    this.strategy = ImportStrategy.merge,
    this.conflictPolicy = ConflictPolicy.mergeSafe,
  });

  ImportOptions copyWith({
    ImportStrategy? strategy,
    ConflictPolicy? conflictPolicy,
  }) {
    return ImportOptions(
      strategy: strategy ?? this.strategy,
      conflictPolicy: conflictPolicy ?? this.conflictPolicy,
    );
  }
}

class ImportedMediaEntry {
  final MediaType mediaType;
  final String sourceProvider;
  final String? sourceId;
  final String? localId;
  final Map<String, String> externalIds;
  final String title;
  final String coverUrl;
  final String status;
  final ReleaseStatus releaseStatus;
  final int progress;
  final int? totalUnits;
  final double score;
  final String? synopsis;
  final String? notes;
  final List<String> tags;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? addedAt;
  final DateTime? updatedAt;
  final int repeatCount;
  final bool isFavorite;
  final ProgressMode progressMode;
  final List<MediaSeason> seasons;
  final bool isManual;
  final Map<String, dynamic> sourceMetadata;

  const ImportedMediaEntry({
    required this.mediaType,
    required this.sourceProvider,
    this.sourceId,
    this.localId,
    this.externalIds = const {},
    required this.title,
    this.coverUrl = '',
    required this.status,
    this.releaseStatus = ReleaseStatus.unknown,
    this.progress = 0,
    this.totalUnits,
    this.score = 0,
    this.synopsis,
    this.notes,
    this.tags = const [],
    this.startedAt,
    this.completedAt,
    this.addedAt,
    this.updatedAt,
    this.repeatCount = 0,
    this.isFavorite = false,
    this.progressMode = ProgressMode.flat,
    this.seasons = const [],
    this.isManual = false,
    this.sourceMetadata = const {},
  });

  factory ImportedMediaEntry.fromMediaItem(MediaItem item) {
    return ImportedMediaEntry(
      mediaType: item.type,
      sourceProvider: 'otakulog',
      sourceId: item.id,
      localId: item.id,
      externalIds: item.externalIds,
      title: item.title,
      coverUrl: item.coverUrl,
      status: item.status,
      releaseStatus: item.releaseStatus,
      progress: item.flatCurrentProgress,
      totalUnits: item.flatTotalCount,
      score: item.rating,
      synopsis: item.synopsis,
      notes: item.notes,
      tags: item.tags,
      startedAt: item.startedAt,
      completedAt: item.completedAt,
      addedAt: item.addedAt,
      updatedAt: item.updatedAt,
      repeatCount: item.repeatCount,
      isFavorite: item.isFavorite,
      progressMode: item.progressMode,
      seasons: item.seasons,
      isManual: item.isManual,
      sourceMetadata: item.customMetadata,
    );
  }

  MediaItem toMediaItem({String? id}) {
    return MediaItem(
      id: id ?? localId ?? _providerLocalId(),
      title: title,
      coverUrl: coverUrl,
      currentProgress: progress,
      totalCount: totalUnits,
      mediaType: mediaType.storageValue,
      status: status,
      releaseStatus: releaseStatus,
      progressMode: progressMode,
      seasons: seasons,
      isManual: isManual,
      synopsis: synopsis,
      rating: score.clamp(0, 10).toDouble(),
      externalIds: externalIds,
      notes: notes,
      tags: tags,
      startedAt: startedAt,
      completedAt: completedAt,
      addedAt: addedAt,
      updatedAt: updatedAt,
      repeatCount: repeatCount,
      isFavorite: isFavorite,
      customMetadata: sourceMetadata,
    );
  }

  String _providerLocalId() {
    final malId = externalIds['mal'];
    if (malId != null && malId.isNotEmpty) {
      return 'jikan_${mediaType.storageValue}_$malId';
    }
    final safeProvider = sourceProvider.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final safeSource = (sourceId ?? title)
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return 'import_${safeProvider}_${safeSource.isEmpty ? 'item' : safeSource}';
  }
}

class ImportWarning {
  final String code;
  final String message;
  final String? entryTitle;

  const ImportWarning(this.code, this.message, {this.entryTitle});

  Map<String, dynamic> toMap() => {
        'code': code,
        'message': message,
        'entryTitle': entryTitle,
      };

  factory ImportWarning.fromMap(Map<String, dynamic> map) {
    return ImportWarning(
      map['code']?.toString() ?? 'unknown',
      map['message']?.toString() ?? 'Unknown warning',
      entryTitle: map['entryTitle']?.toString(),
    );
  }
}

class ImportInspectionResult {
  final String providerId;
  final String providerName;
  final ImportSourceType sourceType;
  final String fileName;
  final List<ImportedMediaEntry> entries;
  final List<ImportWarning> warnings;

  const ImportInspectionResult({
    required this.providerId,
    required this.providerName,
    required this.sourceType,
    required this.fileName,
    required this.entries,
    this.warnings = const [],
  });
}

class ImportCandidate {
  final ImportedMediaEntry imported;
  final MediaItem? local;
  final ImportAction action;
  final String matchReason;
  final bool isConfidentMatch;

  const ImportCandidate({
    required this.imported,
    required this.local,
    required this.action,
    required this.matchReason,
    required this.isConfidentMatch,
  });
}

class ImportPreview {
  final ImportInspectionResult inspection;
  final ImportOptions options;
  final List<ImportCandidate> candidates;
  final List<ImportWarning> warnings;

  const ImportPreview({
    required this.inspection,
    required this.options,
    required this.candidates,
    required this.warnings,
  });

  int count(ImportAction action) =>
      candidates.where((candidate) => candidate.action == action).length;

  int get animeCount => candidates
      .where((candidate) => candidate.imported.mediaType == MediaType.anime)
      .length;

  int get mangaCount => candidates
      .where((candidate) => candidate.imported.mediaType == MediaType.manga)
      .length;

  int get seriesCount => candidates
      .where((candidate) => candidate.imported.mediaType == MediaType.series)
      .length;

  int get movieCount => candidates
      .where((candidate) => candidate.imported.mediaType == MediaType.movie)
      .length;
}

class ImportResult {
  final TransferResultStatus status;
  final String providerId;
  final String fileName;
  final Duration duration;
  final int processed;
  final int added;
  final int updated;
  final int skipped;
  final int failed;
  final int conflicts;
  final String? safetyBackupId;
  final List<ImportWarning> warnings;
  final List<MediaItem> library;
  final String? errorSummary;

  const ImportResult({
    required this.status,
    required this.providerId,
    required this.fileName,
    required this.duration,
    required this.processed,
    required this.added,
    required this.updated,
    required this.skipped,
    required this.failed,
    required this.conflicts,
    this.safetyBackupId,
    this.warnings = const [],
    this.library = const [],
    this.errorSummary,
  });
}

class ExportArtifact {
  final String fileName;
  final String mimeType;
  final Uint8List bytes;
  final int exportedCount;
  final int skippedCount;
  final List<String> warnings;

  const ExportArtifact({
    required this.fileName,
    required this.mimeType,
    required this.bytes,
    required this.exportedCount,
    this.skippedCount = 0,
    this.warnings = const [],
  });
}

class AutomaticBackupRecord {
  final String id;
  final String fileName;
  final DateTime createdAt;
  final String backupJson;
  final int itemCount;

  const AutomaticBackupRecord({
    required this.id,
    required this.fileName,
    required this.createdAt,
    required this.backupJson,
    required this.itemCount,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'fileName': fileName,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'backupJson': backupJson,
        'itemCount': itemCount,
      };

  factory AutomaticBackupRecord.fromMap(Map<String, dynamic> map) {
    return AutomaticBackupRecord(
      id: map['id']?.toString() ?? '',
      fileName: map['fileName']?.toString() ?? 'otakulog-backup.json',
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      backupJson: map['backupJson']?.toString() ?? '',
      itemCount: (map['itemCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class TransferHistoryEntry {
  final String id;
  final TransferOperationType operationType;
  final String providerId;
  final String? fileName;
  final DateTime occurredAt;
  final int durationMilliseconds;
  final int processed;
  final int added;
  final int updated;
  final int skipped;
  final int failed;
  final int conflicts;
  final TransferResultStatus status;
  final String? backupReference;
  final String? errorSummary;
  final List<ImportWarning> warnings;

  const TransferHistoryEntry({
    required this.id,
    required this.operationType,
    required this.providerId,
    this.fileName,
    required this.occurredAt,
    required this.durationMilliseconds,
    required this.processed,
    required this.added,
    required this.updated,
    required this.skipped,
    required this.failed,
    required this.conflicts,
    required this.status,
    this.backupReference,
    this.errorSummary,
    this.warnings = const [],
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'operationType': operationType.name,
        'providerId': providerId,
        'fileName': fileName,
        'occurredAt': occurredAt.toUtc().toIso8601String(),
        'durationMilliseconds': durationMilliseconds,
        'processed': processed,
        'added': added,
        'updated': updated,
        'skipped': skipped,
        'failed': failed,
        'conflicts': conflicts,
        'status': status.name,
        'backupReference': backupReference,
        'errorSummary': errorSummary,
        'warnings': warnings.map((warning) => warning.toMap()).toList(),
      };

  factory TransferHistoryEntry.fromMap(Map<String, dynamic> map) {
    T enumValue<T extends Enum>(List<T> values, Object? raw, T fallback) {
      final name = raw?.toString();
      return values.where((value) => value.name == name).firstOrNull ??
          fallback;
    }

    final rawWarnings = map['warnings'];
    return TransferHistoryEntry(
      id: map['id']?.toString() ?? '',
      operationType: enumValue(
        TransferOperationType.values,
        map['operationType'],
        TransferOperationType.importFile,
      ),
      providerId: map['providerId']?.toString() ?? 'unknown',
      fileName: map['fileName']?.toString(),
      occurredAt: DateTime.tryParse(map['occurredAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      durationMilliseconds: (map['durationMilliseconds'] as num?)?.toInt() ?? 0,
      processed: (map['processed'] as num?)?.toInt() ?? 0,
      added: (map['added'] as num?)?.toInt() ?? 0,
      updated: (map['updated'] as num?)?.toInt() ?? 0,
      skipped: (map['skipped'] as num?)?.toInt() ?? 0,
      failed: (map['failed'] as num?)?.toInt() ?? 0,
      conflicts: (map['conflicts'] as num?)?.toInt() ?? 0,
      status: enumValue(
        TransferResultStatus.values,
        map['status'],
        TransferResultStatus.failed,
      ),
      backupReference: map['backupReference']?.toString(),
      errorSummary: map['errorSummary']?.toString(),
      warnings: rawWarnings is List
          ? rawWarnings
              .whereType<Map>()
              .map(
                (warning) => ImportWarning.fromMap(
                  Map<String, dynamic>.from(warning),
                ),
              )
              .toList(growable: false)
          : const [],
    );
  }
}

abstract interface class ImportProvider {
  String get id;
  String get displayName;
  List<String> get supportedExtensions;
  bool canHandle(ImportSource source);
  Future<ImportInspectionResult> inspect(ImportSource source);
}

abstract interface class ExportProvider {
  String get id;
  String get displayName;
  Future<ExportArtifact> export(List<MediaItem> items, {MediaType? mediaType});
}

class DataTransferException implements Exception {
  final String message;
  final String code;

  const DataTransferException(this.message, {this.code = 'transfer_error'});

  @override
  String toString() => message;
}
