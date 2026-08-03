import 'dart:convert';
import 'dart:typed_data';

import '../models/data_transfer.dart';
import '../models/media_item.dart';
import '../services/csv_export_service.dart';
import '../services/import_planner.dart';
import '../services/mal_xml_service.dart';
import '../services/native_backup_service.dart';
import 'local_storage_repository.dart';

typedef TransferStageCallback = void Function(TransferStage stage);

class MediaTransferRepository {
  final LocalStorageRepository storageRepository;
  final ImportPlanner planner;
  final NativeBackupCodec backupCodec;
  final List<ImportProvider> importProviders;
  final CsvExportProvider csvExporter;
  final MalXmlExportProvider malExporter;
  final String platform;

  MediaTransferRepository({
    required this.storageRepository,
    required this.platform,
    this.planner = const ImportPlanner(),
    this.backupCodec = const NativeBackupCodec(),
    List<ImportProvider>? importProviders,
    this.csvExporter = const CsvExportProvider(),
    this.malExporter = const MalXmlExportProvider(),
  }) : importProviders = importProviders ??
            const [NativeBackupImportProvider(), MalXmlImportProvider()];

  Future<ImportInspectionResult> inspectSource(
    ImportSource source, {
    TransferStageCallback? onStage,
  }) async {
    onStage?.call(TransferStage.validating);
    ImportProvider? provider;
    for (final candidate in importProviders) {
      if (candidate.canHandle(source)) {
        provider = candidate;
        break;
      }
    }
    if (provider == null) {
      throw const DataTransferException(
        'The selected file is not a supported OtakuLog JSON or MAL XML export.',
        code: 'unsupported_file',
      );
    }
    onStage?.call(TransferStage.parsing);
    return provider.inspect(source);
  }

  ImportPreview buildPreview(
    ImportInspectionResult inspection,
    List<MediaItem> localItems,
    ImportOptions options, {
    TransferStageCallback? onStage,
  }) {
    onStage?.call(TransferStage.matching);
    return planner.buildPreview(inspection, localItems, options);
  }

  Future<ImportResult> applyPreview(
    ImportPreview preview, {
    TransferStageCallback? onStage,
  }) async {
    final stopwatch = Stopwatch()..start();
    final current = await storageRepository.loadAllMediaItemsIncludingDeleted();
    AutomaticBackupRecord? safetyBackup;
    try {
      onStage?.call(TransferStage.creatingBackup);
      safetyBackup = await _createAutomaticBackup(current);

      onStage?.call(TransferStage.importing);
      final plan = planner.apply(current, preview);
      final stored = await storageRepository.replaceAllMediaItemsAtomically(
        plan.library,
      );
      onStage?.call(TransferStage.finalizing);
      stopwatch.stop();
      final resultStatus = plan.failed > 0 ||
              (plan.conflicts > 0 &&
                  preview.options.strategy != ImportStrategy.fullRestore)
          ? TransferResultStatus.partialSuccess
          : TransferResultStatus.success;
      final result = ImportResult(
        status: resultStatus,
        providerId: preview.inspection.providerId,
        fileName: preview.inspection.fileName,
        duration: stopwatch.elapsed,
        processed: preview.candidates.length,
        added: plan.added,
        updated: plan.updated,
        skipped: plan.skipped,
        failed: plan.failed,
        conflicts: plan.conflicts,
        safetyBackupId: safetyBackup.id,
        warnings: preview.warnings,
        library: stored,
      );
      try {
        await _recordImport(result, preview.options.strategy);
      } catch (_) {
        // History is secondary to an already validated library transaction.
      }
      return result;
    } catch (error) {
      stopwatch.stop();
      final result = ImportResult(
        status: TransferResultStatus.failed,
        providerId: preview.inspection.providerId,
        fileName: preview.inspection.fileName,
        duration: stopwatch.elapsed,
        processed: preview.candidates.length,
        added: 0,
        updated: 0,
        skipped: 0,
        failed: preview.candidates.length,
        conflicts: preview.count(ImportAction.conflict),
        safetyBackupId: safetyBackup?.id,
        warnings: preview.warnings,
        library: current,
        errorSummary: _redactedError(error),
      );
      try {
        await _recordImport(result, preview.options.strategy);
      } catch (_) {
        // The original failure remains the actionable result.
      }
      return result;
    }
  }

  Future<ExportArtifact> createNativeBackup(List<MediaItem> items) async {
    return backupCodec.createArtifact(items, platform: platform);
  }

  Future<ExportArtifact> createCsvExport(
    List<MediaItem> items, {
    MediaType? mediaType,
  }) async {
    return csvExporter.export(items, mediaType: mediaType);
  }

  Future<ExportArtifact> createMalExport(
    List<MediaItem> items,
    MediaType mediaType,
  ) async {
    return malExporter.export(items, mediaType: mediaType);
  }

  Future<void> recordCompletedExport({
    required String providerId,
    required ExportArtifact artifact,
    TransferOperationType operationType = TransferOperationType.export,
  }) {
    return _recordExport(
      providerId: providerId,
      artifact: artifact,
      operationType: operationType,
    );
  }

  Future<List<TransferHistoryEntry>> loadHistory() =>
      storageRepository.loadTransferHistory();

  Future<List<AutomaticBackupRecord>> loadAutomaticBackups() =>
      storageRepository.loadAutomaticBackups();

  Future<ExportArtifact> automaticBackupArtifact(String id) async {
    final backups = await storageRepository.loadAutomaticBackups();
    AutomaticBackupRecord? record;
    for (final candidate in backups) {
      if (candidate.id == id) {
        record = candidate;
        break;
      }
    }
    if (record == null) {
      throw const DataTransferException(
        'The referenced safety backup is no longer retained.',
        code: 'backup_not_found',
      );
    }
    return ExportArtifact(
      fileName: record.fileName,
      mimeType: 'application/json',
      bytes: Uint8List.fromList(utf8.encode(record.backupJson)),
      exportedCount: record.itemCount,
    );
  }

  Future<AutomaticBackupRecord> _createAutomaticBackup(
    List<MediaItem> items,
  ) async {
    final now = DateTime.now().toUtc();
    final artifact = backupCodec.createArtifact(
      items,
      platform: platform,
      now: now,
    );
    final record = AutomaticBackupRecord(
      id: 'safety_${now.microsecondsSinceEpoch}',
      fileName: artifact.fileName.replaceFirst(
        'otakulog-backup-',
        'otakulog-safety-backup-',
      ),
      createdAt: now,
      backupJson: utf8.decode(artifact.bytes),
      itemCount: items.length,
    );
    await storageRepository.saveAutomaticBackup(record);
    return record;
  }

  Future<void> _recordImport(
    ImportResult result,
    ImportStrategy strategy,
  ) {
    final now = DateTime.now().toUtc();
    return storageRepository.addTransferHistory(
      TransferHistoryEntry(
        id: 'history_${now.microsecondsSinceEpoch}',
        operationType: strategy == ImportStrategy.fullRestore
            ? TransferOperationType.restore
            : TransferOperationType.importFile,
        providerId: result.providerId,
        fileName: result.fileName,
        occurredAt: now,
        durationMilliseconds: result.duration.inMilliseconds,
        processed: result.processed,
        added: result.added,
        updated: result.updated,
        skipped: result.skipped,
        failed: result.failed,
        conflicts: result.conflicts,
        status: result.status,
        backupReference: result.safetyBackupId,
        errorSummary: result.errorSummary,
        warnings: result.warnings,
      ),
    );
  }

  Future<void> _recordExport({
    required String providerId,
    required ExportArtifact artifact,
    TransferOperationType operationType = TransferOperationType.export,
  }) {
    final now = DateTime.now().toUtc();
    return storageRepository.addTransferHistory(
      TransferHistoryEntry(
        id: 'history_${now.microsecondsSinceEpoch}',
        operationType: operationType,
        providerId: providerId,
        fileName: artifact.fileName,
        occurredAt: now,
        durationMilliseconds: 0,
        processed: artifact.exportedCount + artifact.skippedCount,
        added: 0,
        updated: 0,
        skipped: artifact.skippedCount,
        failed: 0,
        conflicts: 0,
        status: artifact.skippedCount > 0
            ? TransferResultStatus.partialSuccess
            : TransferResultStatus.success,
        warnings: artifact.warnings
            .map((warning) => ImportWarning('export_warning', warning))
            .toList(growable: false),
      ),
    );
  }

  String _redactedError(Object error) {
    if (error is DataTransferException) {
      return error.message;
    }
    if (error is StorageCorruptionException) {
      return error.message;
    }
    if (error is StorageWriteException) {
      return error.message;
    }
    return 'The operation failed and the previous library was restored.';
  }
}
