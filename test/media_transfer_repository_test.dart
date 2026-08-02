import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:otaku_log/models/data_transfer.dart';
import 'package:otaku_log/models/media_item.dart';
import 'package:otaku_log/repositories/local_storage_repository.dart';
import 'package:otaku_log/repositories/media_transfer_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const local = MediaItem(
    id: 'jikan_anime_1',
    title: 'Local Item',
    coverUrl: '',
    currentProgress: 5,
    totalCount: 12,
    mediaType: 'anime',
    status: 'Watching',
    externalIds: {'mal': '1'},
    notes: 'local note',
  );
  const incoming = ImportedMediaEntry(
    mediaType: MediaType.anime,
    sourceProvider: 'myanimelist',
    sourceId: '1',
    externalIds: {'mal': '1'},
    title: 'Provider Title',
    status: 'Watching',
    progress: 8,
    totalUnits: 12,
    notes: 'imported note',
  );

  ImportInspectionResult inspection({
    List<ImportedMediaEntry> entries = const [incoming],
    ImportSourceType sourceType = ImportSourceType.malAnime,
  }) {
    return ImportInspectionResult(
      providerId: 'fixture',
      providerName: 'Fixture provider',
      sourceType: sourceType,
      fileName: 'fixture.xml',
      entries: entries,
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'otaku_log_media_items': jsonEncode([local.toMap()]),
    });
  });

  test('successful import creates safety backup, merges, and records history',
      () async {
    const storage = LocalStorageRepository();
    final repository = MediaTransferRepository(
      storageRepository: storage,
      platform: 'test',
    );
    final preview = repository.buildPreview(
      inspection(),
      [local],
      const ImportOptions(),
    );

    final result = await repository.applyPreview(preview);

    expect(result.status, TransferResultStatus.success);
    expect(result.updated, 1);
    expect(result.library.single.currentProgress, 8);
    expect(result.library.single.notes, 'local note');
    final backups = await storage.loadAutomaticBackups();
    expect(backups, hasLength(1));
    expect(backups.single.itemCount, 1);
    final history = await storage.loadTransferHistory();
    expect(history, hasLength(1));
    expect(history.single.backupReference, backups.single.id);
  });

  test('critical write failure rolls library back and reports failed result',
      () async {
    final storage = LocalStorageRepository(
      transactionValidator: (_) async {
        throw StateError('Injected validation failure');
      },
    );
    final repository = MediaTransferRepository(
      storageRepository: storage,
      platform: 'test',
    );
    final preview = repository.buildPreview(
      inspection(),
      [local],
      const ImportOptions(),
    );

    final result = await repository.applyPreview(preview);
    final reloaded = await storage.loadMediaItems();

    expect(result.status, TransferResultStatus.failed);
    expect(result.errorSummary, contains('restored'));
    expect(reloaded.single.currentProgress, 5);
    expect(await storage.loadAutomaticBackups(), hasLength(1));
  });

  test('full restore can intentionally restore an empty library', () async {
    const storage = LocalStorageRepository();
    final repository = MediaTransferRepository(
      storageRepository: storage,
      platform: 'test',
    );
    final emptyInspection = inspection(
      entries: const [],
      sourceType: ImportSourceType.nativeBackup,
    );
    final preview = repository.buildPreview(
      emptyInspection,
      [local],
      const ImportOptions(strategy: ImportStrategy.fullRestore),
    );

    final result = await repository.applyPreview(preview);

    expect(result.status, TransferResultStatus.success);
    expect(result.library, isEmpty);
    expect(await storage.loadMediaItems(), isEmpty);
  });

  test('automatic safety backup retention keeps only five newest records',
      () async {
    const storage = LocalStorageRepository();
    for (var index = 0; index < 7; index++) {
      await storage.saveAutomaticBackup(
        AutomaticBackupRecord(
          id: 'backup-$index',
          fileName: 'backup-$index.json',
          createdAt: DateTime.utc(2026, 8, 1, 0, index),
          backupJson: '{}',
          itemCount: index,
        ),
      );
    }

    final backups = await storage.loadAutomaticBackups();

    expect(backups, hasLength(LocalStorageRepository.automaticBackupRetention));
    expect(backups.first.id, 'backup-6');
    expect(backups.last.id, 'backup-2');
  });

  test('valid stored empty list is not replaced with sample content', () async {
    SharedPreferences.setMockInitialValues({'otaku_log_media_items': '[]'});

    final items = await const LocalStorageRepository().loadMediaItems();

    expect(items, isEmpty);
  });

  test('corrupt storage is reported without overwriting its raw value',
      () async {
    SharedPreferences.setMockInitialValues({
      'otaku_log_media_items': '{not valid json',
    });
    const storage = LocalStorageRepository();

    expect(
        storage.loadMediaItems(), throwsA(isA<StorageCorruptionException>()));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('otaku_log_media_items'), '{not valid json');
  });

  test('export history is recorded only after a completed platform save',
      () async {
    const storage = LocalStorageRepository();
    final repository = MediaTransferRepository(
      storageRepository: storage,
      platform: 'test',
    );

    final artifact = await repository.createNativeBackup([local]);
    expect(await storage.loadTransferHistory(), isEmpty);

    await repository.recordCompletedExport(
      providerId: 'otakulog-native',
      artifact: artifact,
      operationType: TransferOperationType.backup,
    );

    final history = await storage.loadTransferHistory();
    expect(history, hasLength(1));
    expect(history.single.operationType, TransferOperationType.backup);
    expect(history.single.processed, 1);
  });
}
