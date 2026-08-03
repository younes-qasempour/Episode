import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:otaku_log/models/data_transfer.dart';
import 'package:otaku_log/models/media_item.dart';
import 'package:otaku_log/repositories/local_storage_repository.dart';
import 'package:otaku_log/services/csv_export_service.dart';
import 'package:otaku_log/services/import_planner.dart';
import 'package:otaku_log/services/mal_xml_service.dart';
import 'package:otaku_log/services/native_backup_service.dart';
import 'package:otaku_log/utils/clock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('1. UUID Generation and Migration', () {
    test('New manual media item receives UUID v4', () {
      final manualId = MediaItem.createManualId();
      expect(uuidRegex.hasMatch(manualId), isTrue);
    });

    test('New season receives UUID v4', () {
      final seasonId = MediaItem.createSeasonId('parent-id', 1);
      expect(uuidRegex.hasMatch(seasonId), isTrue);
    });

    test('Multiple generated IDs are unique', () {
      final ids = List.generate(100, (_) => MediaItem.createManualId()).toSet();
      expect(ids, hasLength(100));
    });

    test('Legacy non-UUID IDs are replaced and external IDs are preserved',
        () async {
      SharedPreferences.setMockInitialValues({
        'otaku_log_media_items': jsonEncode([
          {
            'id': 'jikan_anime_12345',
            'title': 'Legacy Jikan Anime',
            'coverUrl': '',
            'currentProgress': 5,
            'totalCount': 12,
            'mediaType': 'anime',
            'status': 'Watching',
          },
          {
            'id': 'tvmaze_series_6789',
            'title': 'Legacy TVMaze Series',
            'coverUrl': '',
            'currentProgress': 2,
            'totalCount': 10,
            'mediaType': 'series',
            'status': 'Watching',
          },
          {
            'id': '550e8400-e29b-41d4-a716-446655440099', // Already UUID
            'title': 'Existing UUID Anime',
            'coverUrl': '',
            'currentProgress': 1,
            'totalCount': 12,
            'mediaType': 'anime',
            'status': 'Watching',
          },
        ]),
      });

      const repo = LocalStorageRepository();
      final items = await repo.loadAllMediaItemsIncludingDeleted();

      expect(items, hasLength(3));

      final jikanItem =
          items.firstWhere((i) => i.title == 'Legacy Jikan Anime');
      expect(uuidRegex.hasMatch(jikanItem.id), isTrue);
      expect(jikanItem.externalIds['mal'], '12345');

      final tvmazeItem =
          items.firstWhere((i) => i.title == 'Legacy TVMaze Series');
      expect(uuidRegex.hasMatch(tvmazeItem.id), isTrue);
      expect(tvmazeItem.externalIds['tvmaze'], '6789');

      final existingUuidItem =
          items.firstWhere((i) => i.title == 'Existing UUID Anime');
      expect(existingUuidItem.id, '550e8400-e29b-41d4-a716-446655440099');
    });
  });

  group('2. Active Storage Envelope (Schema v2) and Migration Rollback', () {
    test('Bare legacy array migrates to schema version 2 envelope', () async {
      SharedPreferences.setMockInitialValues({
        'otaku_log_media_items': jsonEncode([
          {
            'id': 'legacy-item-1',
            'title': 'Bare Array Anime',
            'coverUrl': '',
            'currentProgress': 3,
            'totalCount': 12,
            'mediaType': 'anime',
            'status': 'Watching',
          },
        ]),
      });

      const repo = LocalStorageRepository();
      await repo.loadMediaItems();

      final prefs = await SharedPreferences.getInstance();
      final storedRaw = prefs.getString('otaku_log_media_items')!;

      expect(storedRaw.startsWith('{'), isTrue);
      final decodedMap = jsonDecode(storedRaw) as Map<String, dynamic>;
      expect(decodedMap['schemaVersion'], 2);
      expect(decodedMap['mediaItems'], isA<List>());
    });

    test(
        'Unsupported future schema version throws typed exception without overwriting',
        () async {
      final rawFuture = jsonEncode({
        'schemaVersion': 99,
        'migratedAt': '2030-01-01T00:00:00.000Z',
        'mediaItems': [],
      });

      SharedPreferences.setMockInitialValues({
        'otaku_log_media_items': rawFuture,
      });

      const repo = LocalStorageRepository();

      expect(
        () async => await repo.loadAllMediaItemsIncludingDeleted(),
        throwsA(isA<StorageUnsupportedSchemaException>()),
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('otaku_log_media_items'), rawFuture);
    });

    test('Corrupt storage restores raw value on migration failure', () async {
      final corruptRaw = jsonEncode([
        {
          'id': 'item-1',
          // Missing required title
          'coverUrl': '',
          'currentProgress': 1,
          'totalCount': 12,
          'mediaType': 'anime',
          'status': 'Watching',
        },
      ]);

      SharedPreferences.setMockInitialValues({
        'otaku_log_media_items': corruptRaw,
      });

      const repo = LocalStorageRepository();

      expect(
        () async => await repo.loadAllMediaItemsIncludingDeleted(),
        throwsA(isA<StorageCorruptionException>()),
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('otaku_log_media_items'), corruptRaw);
    });
  });

  group('3. Synchronization Metadata & Mutation Stamping', () {
    test('New item and season receive UTC timestamps and revision 1', () async {
      final clock = TestClock(DateTime.utc(2026, 8, 3, 12, 0, 0));
      final repo = LocalStorageRepository(clock: clock);

      final newItem = MediaItem(
        id: MediaItem.createManualId(),
        title: 'Stamped Anime',
        coverUrl: '',
        currentProgress: 0,
        totalCount: 12,
        mediaType: 'anime',
        status: 'Watching',
      );

      final active = await repo.saveMediaItem(newItem);
      final saved = active.firstWhere((i) => i.title == 'Stamped Anime');

      expect(saved.createdAt, DateTime.utc(2026, 8, 3, 12, 0, 0));
      expect(saved.updatedAt, DateTime.utc(2026, 8, 3, 12, 0, 0));
      expect(saved.deletedAt, isNull);
      expect(saved.localRevision, 1);
    });

    test('Progress increment updates updatedAt and increments localRevision',
        () async {
      final clock = TestClock(DateTime.utc(2026, 8, 3, 12, 0, 0));
      final repo = LocalStorageRepository(clock: clock);

      const item = MediaItem(
        id: '550e8400-e29b-41d4-a716-446655440001',
        title: 'Increment Target',
        coverUrl: '',
        currentProgress: 1,
        totalCount: 12,
        mediaType: 'anime',
        status: 'Watching',
      );

      await repo.saveMediaItem(item);

      clock.advance(const Duration(minutes: 5));
      final updatedList = await repo.incrementProgress(item.id);
      final updated = updatedList.firstWhere((i) => i.id == item.id);

      expect(updated.currentProgress, 2);
      expect(updated.updatedAt, DateTime.utc(2026, 8, 3, 12, 5, 0));
      expect(updated.localRevision, 2);
    });
  });

  group('4. Soft Deletion & Tombstones', () {
    test(
        'softDeleteMediaItem sets deletedAt and excludes item from active list',
        () async {
      final clock = TestClock(DateTime.utc(2026, 8, 3, 12, 0, 0));
      final repo = LocalStorageRepository(clock: clock);

      const item = MediaItem(
        id: '550e8400-e29b-41d4-a716-446655440001',
        title: 'To Be Soft Deleted',
        coverUrl: '',
        currentProgress: 0,
        totalCount: 12,
        mediaType: 'anime',
        status: 'Watching',
      );

      await repo.saveMediaItem(item);

      clock.advance(const Duration(hours: 1));
      final activeList = await repo.softDeleteMediaItem(item.id);

      expect(activeList.any((i) => i.id == item.id), isFalse);

      final allItems = await repo.loadAllMediaItemsIncludingDeleted();
      final tombstone = allItems.firstWhere((i) => i.id == item.id);

      expect(tombstone.deletedAt, DateTime.utc(2026, 8, 3, 13, 0, 0));
      expect(tombstone.localRevision, 2);
    });

    test(
        'restoreDeletedMediaItem clears deletedAt and brings item back to active list',
        () async {
      final clock = TestClock(DateTime.utc(2026, 8, 3, 12, 0, 0));
      final repo = LocalStorageRepository(clock: clock);

      const item = MediaItem(
        id: '550e8400-e29b-41d4-a716-446655440001',
        title: 'Restorable Anime',
        coverUrl: '',
        currentProgress: 0,
        totalCount: 12,
        mediaType: 'anime',
        status: 'Watching',
      );

      await repo.saveMediaItem(item);
      await repo.softDeleteMediaItem(item.id);

      clock.advance(const Duration(days: 1));
      final activeList = await repo.restoreDeletedMediaItem(item.id);
      final restored = activeList.firstWhere((i) => i.id == item.id);

      expect(restored.deletedAt, isNull);
      expect(restored.localRevision, 3);
    });

    test(
        'purgeDeletedMediaItemsBefore removes only tombstones older than cutoff',
        () async {
      final clock = TestClock(DateTime.utc(2026, 8, 1, 0, 0, 0));
      final repo = LocalStorageRepository(clock: clock);

      const oldItem = MediaItem(
        id: '550e8400-e29b-41d4-a716-446655440001',
        title: 'Old Deleted Item',
        coverUrl: '',
        currentProgress: 0,
        totalCount: 12,
        mediaType: 'anime',
        status: 'Watching',
      );

      const recentItem = MediaItem(
        id: '550e8400-e29b-41d4-a716-446655440002',
        title: 'Recent Deleted Item',
        coverUrl: '',
        currentProgress: 0,
        totalCount: 12,
        mediaType: 'anime',
        status: 'Watching',
      );

      await repo.saveMediaItem(oldItem);
      await repo.saveMediaItem(recentItem);

      // Soft delete oldItem at Aug 1
      await repo.softDeleteMediaItem(oldItem.id);

      // Advance clock to Aug 10, soft delete recentItem at Aug 10
      clock.setTime(DateTime.utc(2026, 8, 10, 0, 0, 0));
      await repo.softDeleteMediaItem(recentItem.id);

      // Cutoff set to Aug 5
      final cutoff = DateTime.utc(2026, 8, 5, 0, 0, 0);
      final purgedCount = await repo.purgeDeletedMediaItemsBefore(cutoff);

      expect(purgedCount, 1);

      final allItems = await repo.loadAllMediaItemsIncludingDeleted();
      expect(allItems.any((i) => i.id == oldItem.id), isFalse);
      expect(allItems.any((i) => i.id == recentItem.id), isTrue);
    });
  });

  group('5. Import / Export Compatibility', () {
    test('Native backup preserves tombstones', () async {
      const codec = NativeBackupCodec();
      final tombstone = MediaItem(
        id: '550e8400-e29b-41d4-a716-446655440001',
        title: 'Deleted Item in Backup',
        coverUrl: '',
        currentProgress: 1,
        totalCount: 12,
        mediaType: 'anime',
        status: 'Watching',
        deletedAt: DateTime.utc(2026, 8, 3, 10, 0, 0),
      );

      final artifact = codec.createArtifact([tombstone], platform: 'test');
      final source = ImportSource(
        fileName: artifact.fileName,
        bytes: artifact.bytes,
      );

      final decoded = codec.decode(source);
      expect(decoded.items, hasLength(1));
      expect(
          decoded.items.single.deletedAt, DateTime.utc(2026, 8, 3, 10, 0, 0));
    });

    test('CSV and MAL XML exports exclude tombstones', () async {
      const csvExporter = CsvExportProvider();
      const malExporter = MalXmlExportProvider();

      const activeItem = MediaItem(
        id: '550e8400-e29b-41d4-a716-446655440001',
        title: 'Active Anime',
        coverUrl: '',
        currentProgress: 1,
        totalCount: 12,
        mediaType: 'anime',
        status: 'Watching',
        externalIds: {'mal': '101'},
      );

      final deletedItem = MediaItem(
        id: '550e8400-e29b-41d4-a716-446655440002',
        title: 'Deleted Anime',
        coverUrl: '',
        currentProgress: 1,
        totalCount: 12,
        mediaType: 'anime',
        status: 'Watching',
        externalIds: const {'mal': '102'},
        deletedAt: DateTime.utc(2026, 8, 3, 10, 0, 0),
      );

      final csvArtifact = await csvExporter.export([activeItem, deletedItem]);
      expect(csvArtifact.exportedCount, 1);

      final malArtifact = await malExporter.export(
        [activeItem, deletedItem],
        mediaType: MediaType.anime,
      );
      expect(malArtifact.exportedCount, 1);
    });

    test('Importing an active record matching a local tombstone marks conflict',
        () {
      const planner = ImportPlanner();
      final tombstone = MediaItem(
        id: '550e8400-e29b-41d4-a716-446655440001',
        title: 'Tombstone Title',
        coverUrl: '',
        currentProgress: 1,
        totalCount: 12,
        mediaType: 'anime',
        status: 'Watching',
        deletedAt: DateTime.utc(2026, 8, 3, 10, 0, 0),
      );

      const inspection = ImportInspectionResult(
        providerId: 'test',
        providerName: 'Test Provider',
        sourceType: ImportSourceType.malAnime,
        fileName: 'test.xml',
        entries: [
          ImportedMediaEntry(
            mediaType: MediaType.anime,
            sourceProvider: 'mal',
            title: 'Tombstone Title',
            status: 'Watching',
            progress: 5,
          ),
        ],
      );

      final preview = planner.buildPreview(
        inspection,
        [tombstone],
        const ImportOptions(),
      );

      expect(preview.candidates.single.action, ImportAction.conflict);
      expect(
        preview.candidates.single.matchReason,
        contains('tombstone'),
      );
    });
  });
}
