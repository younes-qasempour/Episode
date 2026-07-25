import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:otaku_log/models/media_item.dart';
import 'package:otaku_log/repositories/local_storage_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocalStorageRepository Tests', () {
    test(
      'loadMediaItems initializes with default sample items when empty',
      () async {
        final repository = LocalStorageRepository();
        final items = await repository.loadMediaItems();

        expect(items.length, greaterThan(0));
        expect(items.any((i) => i.title == 'Jujutsu Kaisen Season 2'), isTrue);
      },
    );

    test('saveMediaItem adds new item at the beginning', () async {
      final repository = LocalStorageRepository();
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
        final repository = LocalStorageRepository();
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
      final repository = LocalStorageRepository();
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
      final repository = LocalStorageRepository();
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
      final repository = LocalStorageRepository();
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
      final repository = LocalStorageRepository();

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
        final repository = LocalStorageRepository();
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
        expect(saved.seasons, hasLength(1));
        expect(saved.seasons.single.id, 'season-b');
        expect(saved.seasons.single.currentProgress, 4);
        expect(saved.currentProgress, 4);
      },
    );

    test('seasonal increment only changes the selected season', () async {
      final repository = LocalStorageRepository();
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
  });
}
