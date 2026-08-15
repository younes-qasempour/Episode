import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:episode/models/data_transfer.dart';
import 'package:episode/models/media_item.dart';
import 'package:episode/repositories/local_storage_repository.dart';
import 'package:episode/services/native_backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocalStorageRepository Tests', () {
    test(
      'loadMediaItems returns empty list when no items exist in storage',
      () async {
        const repository = LocalStorageRepository();
        final items = await repository.loadMediaItems();

        expect(items, isEmpty);
      },
    );

    test('saveMediaItem adds new item at the beginning', () async {
      const repository = LocalStorageRepository();
      await repository.loadMediaItems();

      const newItem = MediaItem(
        id: 'test_123',
        title: 'New Test Anime',
        coverUrl: 'https://example.com/cover.jpg',
        currentProgress: 0,
        totalCount: 12,
        mediaType: 'anime',
        status: 'Watching',
      );

      final updatedList = await repository.saveMediaItem(newItem);

      expect(updatedList.first.id, equals('test_123'));
      expect(updatedList.first.title, equals('New Test Anime'));
    });

    test(
      'incrementProgress is not capped and keeps tracking status explicit',
      () async {
        const repository = LocalStorageRepository();
        const initialItem = MediaItem(
          id: 'test_inc',
          title: 'Short Anime',
          coverUrl: 'https://example.com/cover.jpg',
          currentProgress: 1,
          totalCount: 2,
          mediaType: 'anime',
          status: 'Watching',
        );

        await repository.saveMediaItem(initialItem);

        final result1 = await repository.incrementProgress('test_inc');
        final updatedItem = result1.firstWhere((i) => i.id == 'test_inc');

        expect(updatedItem.currentProgress, equals(2));
        expect(updatedItem.status, equals('Watching'));

        final result2 = await repository.incrementProgress('test_inc');
        final beyondTotal = result2.firstWhere((i) => i.id == 'test_inc');

        expect(beyondTotal.currentProgress, equals(3));
        expect(beyondTotal.status, equals('Watching'));
      },
    );

    test('updateMediaItem modifies fields in local storage', () async {
      const repository = LocalStorageRepository();
      const initialItem = MediaItem(
        id: 'test_upd',
        title: 'Original Title',
        coverUrl: 'https://example.com/cover.jpg',
        currentProgress: 5,
        totalCount: 10,
        mediaType: 'manga',
        status: 'Reading',
        rating: 7.5,
      );

      await repository.saveMediaItem(initialItem);

      final updated = initialItem.copyWith(rating: 9.0, status: 'Completed');

      final result = await repository.updateMediaItem(updated);
      final itemInDb = result.firstWhere((i) => i.id == 'test_upd');

      expect(itemInDb.rating, equals(9.0));
      expect(itemInDb.status, equals('Completed'));
    });

    test('deleteMediaItem removes item from storage', () async {
      const repository = LocalStorageRepository();
      const initialItem = MediaItem(
        id: 'test_del',
        title: 'To Delete',
        coverUrl: 'https://example.com/cover.jpg',
        currentProgress: 0,
        totalCount: 10,
        mediaType: 'series',
        status: 'Plan to Watch',
      );

      await repository.saveMediaItem(initialItem);
      final listAfterDel = await repository.deleteMediaItem('test_del');

      expect(listAfterDel.any((i) => i.id == 'test_del'), isFalse);
    });

    test('unknown-total manual media increments and survives reload', () async {
      const repository = LocalStorageRepository();
      final manualItem = MediaItem(
        id: MediaItem.createManualId(),
        title: 'Manual Ongoing Anime',
        coverUrl: '',
        currentProgress: 900,
        totalCount: null,
        mediaType: 'anime',
        status: 'Watching',
        releaseStatus: ReleaseStatus.ongoing,
        isManual: true,
      );

      await repository.saveMediaItem(manualItem);
      await repository.incrementProgress(manualItem.id);
      await repository.incrementProgress(manualItem.id);
      final reloaded = await repository.loadMediaItems();
      final saved = reloaded.firstWhere((item) => item.id == manualItem.id);

      expect(saved.currentProgress, 902);
      expect(saved.totalCount, isNull);
      expect(saved.isManual, isTrue);
    });

    test('legacy stored records remain readable', () async {
      SharedPreferences.setMockInitialValues({
        'otaku_log_media_items': jsonEncode([
          {
            'id': 'legacy-stored',
            'title': 'Stored Legacy',
            'coverUrl': '',
            'currentProgress': 7,
            'totalCount': 10,
            'mediaType': 'manga',
            'status': 'Reading',
          },
        ]),
      });
      const repository = LocalStorageRepository();

      final items = await repository.loadMediaItems();

      expect(items, hasLength(1));
      expect(items.single.currentProgress, 7);
      expect(items.single.totalCount, 10);
      expect(items.single.releaseStatus, ReleaseStatus.unknown);
      expect(items.single.seasons, isEmpty);
    });

    test(
      'updated and deleted season data persists without corrupting item',
      () async {
        const repository = LocalStorageRepository();
        const initial = MediaItem(
          id: 'season-persist',
          title: 'Season Persistence',
          coverUrl: '',
          currentProgress: 0,
          totalCount: null,
          mediaType: 'series',
          status: 'Watching',
          progressMode: ProgressMode.seasonal,
          seasons: [
            MediaSeason(
              id: 'season-a',
              seasonNumber: 1,
              currentProgress: 5,
              totalCount: 10,
            ),
            MediaSeason(
              id: 'season-b',
              seasonNumber: 2,
              currentProgress: 1,
              totalCount: null,
              releaseStatus: ReleaseStatus.ongoing,
            ),
          ],
        );
        await repository.saveMediaItem(initial);

        final edited = initial.upsertSeason(
          initial.seasons.last.copyWith(currentProgress: 4),
        );
        await repository.updateMediaItem(edited);
        final withoutFirst = edited.removeSeason('season-a');
        await repository.updateMediaItem(withoutFirst);

        final reloaded = await repository.loadMediaItems();
        final saved = reloaded.firstWhere(
          (item) => item.id == 'season-persist',
        );
        expect(saved.activeSeasons, hasLength(1));
        expect(saved.activeSeasons.single.id, 'season-b');
        expect(saved.activeSeasons.single.currentProgress, 4);
        expect(saved.currentProgress, 4);
      },
    );

    test('seasonal increment only changes the selected season', () async {
      const repository = LocalStorageRepository();
      const initial = MediaItem(
        id: 'season-increment',
        title: 'Season Increment',
        coverUrl: '',
        currentProgress: 0,
        totalCount: null,
        mediaType: 'anime',
        status: 'Watching',
        progressMode: ProgressMode.seasonal,
        seasons: [
          MediaSeason(
            id: 'finished-season',
            seasonNumber: 1,
            currentProgress: 12,
            totalCount: 12,
            releaseStatus: ReleaseStatus.finished,
          ),
          MediaSeason(
            id: 'ongoing-season',
            seasonNumber: 2,
            currentProgress: 3,
            totalCount: null,
            releaseStatus: ReleaseStatus.ongoing,
          ),
        ],
      );
      await repository.saveMediaItem(initial);

      final items = await repository.incrementProgress('season-increment');
      final updated = items.firstWhere((item) => item.id == 'season-increment');

      expect(updated.seasons.first.currentProgress, 12);
      expect(updated.seasons.last.currentProgress, 4);
    });

    test('toggleFavorite toggles favorite status and sets updatedAt', () async {
      const repository = LocalStorageRepository();
      const initialItem = MediaItem(
        id: 'test_fav',
        title: 'Favorite Test',
        coverUrl: '',
        currentProgress: 0,
        totalCount: 12,
        mediaType: 'anime',
        status: 'Watching',
        isFavorite: false,
      );
      await repository.saveMediaItem(initialItem);

      final result1 = await repository.toggleFavorite('test_fav');
      final favItem = result1.firstWhere((i) => i.id == 'test_fav');
      expect(favItem.isFavorite, isTrue);
      expect(favItem.updatedAt, isNotNull);

      final result2 = await repository.toggleFavorite('test_fav');
      final unfavItem = result2.firstWhere((i) => i.id == 'test_fav');
      expect(unfavItem.isFavorite, isFalse);
    });

    test('automatic safety backup is a restorable Episode backup', () async {
      const repository = LocalStorageRepository(backupPlatform: 'test');
      const item = MediaItem(
        id: 'safety-backup-item',
        title: 'Safety Backup Item',
        coverUrl: '',
        currentProgress: 3,
        totalCount: 12,
        mediaType: 'anime',
        status: 'Watching',
      );
      await repository.saveMediaItem(item);

      final record = await repository.createAutomaticBackup('sync safety');
      final decoded = const NativeBackupCodec().decode(
        ImportSource(
          fileName: record.fileName,
          bytes: utf8.encode(record.backupJson),
        ),
      );

      expect(record.fileName, startsWith('episode-safety-backup-'));
      expect(decoded.items.single.id, item.id);
    });
  });
}
