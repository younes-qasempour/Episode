import 'package:flutter_test/flutter_test.dart';
import 'package:otaku_log/models/media_item.dart';

void main() {
  group('MediaItem serialization', () {
    test('legacy JSON decodes without losing progress', () {
      final item = MediaItem.fromMap({
        'id': 'legacy-1',
        'title': 'Legacy Anime',
        'coverUrl': '',
        'currentProgress': 18,
        'totalCount': 24,
        'mediaType': 'anime',
        'status': 'Watching',
      });

      expect(item.currentProgress, 18);
      expect(item.totalCount, 24);
      expect(item.progressMode, ProgressMode.flat);
      expect(item.releaseStatus, ReleaseStatus.unknown);
      expect(item.seasons, isEmpty);
      expect(item.isFavorite, isFalse);
      expect(item.updatedAt, isNotNull);
    });

    test('isFavorite and updatedAt serialize and deserialize correctly', () {
      final now = DateTime.utc(2026, 7, 29, 12, 0, 0);
      final original = MediaItem(
        id: 'fav-1',
        title: 'Favorite Anime',
        coverUrl: '',
        currentProgress: 5,
        totalCount: 12,
        mediaType: 'anime',
        status: 'Watching',
        isFavorite: true,
        updatedAt: now,
      );

      final decoded = MediaItem.fromJson(original.toJson());

      expect(decoded.isFavorite, isTrue);
      expect(decoded.updatedAt, now);
    });

    test('unknown total serializes and deserializes as null', () {
      const original = MediaItem(
        id: 'unknown-total',
        title: 'Open Ended',
        coverUrl: '',
        currentProgress: 312,
        totalCount: null,
        mediaType: 'anime',
        status: 'Watching',
        releaseStatus: ReleaseStatus.ongoing,
      );

      final decoded = MediaItem.fromJson(original.toJson());

      expect(decoded.totalCount, isNull);
      expect(decoded.currentProgress, 312);
      expect(decoded.releaseStatus, ReleaseStatus.ongoing);
    });

    test('manual movie serializes without fake progress', () {
      final original = MediaItem(
        id: MediaItem.createManualId(
          timestamp: DateTime.fromMicrosecondsSinceEpoch(123),
        ),
        title: 'Personal Film',
        coverUrl: '',
        currentProgress: 0,
        totalCount: null,
        mediaType: 'movie',
        status: 'Completed',
        releaseStatus: ReleaseStatus.finished,
        isManual: true,
        rating: 8.5,
      );

      final decoded = MediaItem.fromJson(original.toJson());

      final uuidRegex = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      );
      expect(uuidRegex.hasMatch(decoded.id), isTrue);
      expect(decoded.type, MediaType.movie);
      expect(decoded.isManual, isTrue);
      expect(decoded.supportsProgress, isFalse);
      expect(decoded.totalCount, isNull);
    });

    test('seasonal media round-trips with aggregate progress', () {
      const original = MediaItem(
        id: 'seasonal-1',
        title: 'Seasonal Show',
        coverUrl: '',
        currentProgress: 99,
        totalCount: 100,
        mediaType: 'series',
        status: 'Watching',
        progressMode: ProgressMode.seasonal,
        seasons: [
          MediaSeason(
            id: 's1',
            seasonNumber: 1,
            currentProgress: 10,
            totalCount: 10,
            releaseStatus: ReleaseStatus.finished,
          ),
          MediaSeason(
            id: 's2',
            seasonNumber: 2,
            title: 'The Return',
            currentProgress: 4,
            totalCount: null,
            releaseStatus: ReleaseStatus.ongoing,
          ),
        ],
      );

      final decoded = MediaItem.fromJson(original.toJson());

      expect(decoded.progressMode, ProgressMode.seasonal);
      expect(decoded.seasons, hasLength(2));
      expect(decoded.currentProgress, 14);
      expect(decoded.totalCount, isNull);
      expect(decoded.flatCurrentProgress, 99);
      expect(decoded.seasons.last.displayName, 'The Return');
    });

    test('provider IDs and personal metadata round-trip additively', () {
      final original = MediaItem(
        id: 'metadata-1',
        title: 'Metadata',
        coverUrl: '',
        currentProgress: 4,
        totalCount: 12,
        mediaType: 'anime',
        status: 'Watching',
        externalIds: const {'mal': '1', 'anilist': '2'},
        notes: 'Personal note',
        tags: const ['favorite', '日本語'],
        startedAt: DateTime.utc(2026, 1, 2),
        updatedAt: DateTime.utc(2026, 2, 3, 4, 5),
        repeatCount: 3,
        isFavorite: true,
        customMetadata: const {'providerField': 42},
      );

      final decoded = MediaItem.fromJson(original.toJson());

      expect(decoded.externalIds, original.externalIds);
      expect(decoded.notes, original.notes);
      expect(decoded.tags, original.tags);
      expect(decoded.startedAt, original.startedAt);
      expect(decoded.updatedAt, original.updatedAt);
      expect(decoded.repeatCount, 3);
      expect(decoded.isFavorite, isTrue);
      expect(decoded.customMetadata['providerField'], 42);
    });
  });

  group('MediaItem progress rules', () {
    test('negative progress is normalized to zero', () {
      const item = MediaItem(
        id: 'negative',
        title: 'Negative',
        coverUrl: '',
        currentProgress: -10,
        totalCount: 12,
        mediaType: 'anime',
        status: 'Watching',
      );

      expect(item.currentProgress, 0);
    });

    test('flat progress may exceed a known total', () {
      const item = MediaItem(
        id: 'beyond',
        title: 'Beyond',
        coverUrl: '',
        currentProgress: 24,
        totalCount: 24,
        mediaType: 'anime',
        status: 'Watching',
        releaseStatus: ReleaseStatus.ongoing,
      );

      final incremented = item.incrementFlatProgress();

      expect(incremented.currentProgress, 25);
      expect(incremented.isBeyondKnownTotal, isTrue);
      expect(incremented.trackingStatus, TrackingStatus.watching);
    });

    test('seasonal aggregate and targeted increment are consistent', () {
      const item = MediaItem(
        id: 'targeted',
        title: 'Targeted',
        coverUrl: '',
        currentProgress: 0,
        totalCount: null,
        mediaType: 'anime',
        status: 'Watching',
        progressMode: ProgressMode.seasonal,
        seasons: [
          MediaSeason(
            id: 's1',
            seasonNumber: 1,
            currentProgress: 12,
            totalCount: 12,
            releaseStatus: ReleaseStatus.finished,
          ),
          MediaSeason(
            id: 's2',
            seasonNumber: 2,
            currentProgress: 3,
            totalCount: null,
            releaseStatus: ReleaseStatus.ongoing,
          ),
        ],
      );

      final incremented = item.incrementSeason('s2');

      expect(item.currentProgress, 15);
      expect(incremented.currentProgress, 16);
      expect(incremented.seasons.first.currentProgress, 12);
      expect(incremented.seasons.last.currentProgress, 4);
      expect(incremented.defaultIncrementSeason?.id, 's2');
    });

    test('flat and seasonal conversion preserves progress', () {
      const item = MediaItem(
        id: 'convert',
        title: 'Convert',
        coverUrl: '',
        currentProgress: 8,
        totalCount: 12,
        mediaType: 'series',
        status: 'Watching',
      );

      final seasonal = item.convertedTo(ProgressMode.seasonal);
      final flatAgain = seasonal.convertedTo(ProgressMode.flat);

      expect(seasonal.seasons.single.currentProgress, 8);
      expect(seasonal.seasons.single.totalCount, 12);
      expect(flatAgain.currentProgress, 8);
      expect(flatAgain.totalCount, 12);
      expect(flatAgain.seasons, isNotEmpty);
    });

    group('automatic completion progress and status sync', () {
      test('flat: setting status to Completed updates 1/25 to 25/25', () {
        const item = MediaItem(
          id: 'flat-complete-1',
          title: 'Flat Anime',
          coverUrl: '',
          currentProgress: 1,
          totalCount: 25,
          mediaType: 'anime',
          status: 'Watching',
        );

        final completed = item.applyCompletedStatus();

        expect(completed.currentProgress, 25);
        expect(completed.totalCount, 25);
        expect(completed.trackingStatus, TrackingStatus.completed);
        expect(completed.completedAt, isNotNull);
      });

      test(
          'flat: setting status to Completed with unknown total preserves progress',
          () {
        const item = MediaItem(
          id: 'flat-unknown',
          title: 'Unknown Total',
          coverUrl: '',
          currentProgress: 10,
          totalCount: null,
          mediaType: 'anime',
          status: 'Watching',
        );

        final completed = item.applyCompletedStatus();

        expect(completed.currentProgress, 10);
        expect(completed.totalCount, isNull);
        expect(completed.trackingStatus, TrackingStatus.completed);
      });

      test(
          'flat: reducing progress below total changes status from Completed to Watching/Reading',
          () {
        const completedAnime = MediaItem(
          id: 'flat-anime',
          title: 'Flat Anime',
          coverUrl: '',
          currentProgress: 25,
          totalCount: 25,
          mediaType: 'anime',
          status: 'Completed',
        );

        final reducedAnime = completedAnime
            .copyWith(currentProgress: 24)
            .syncStatusWithProgress();
        expect(reducedAnime.trackingStatus, TrackingStatus.watching);

        const completedManga = MediaItem(
          id: 'flat-manga',
          title: 'Flat Manga',
          coverUrl: '',
          currentProgress: 100,
          totalCount: 100,
          mediaType: 'manga',
          status: 'Completed',
        );

        final reducedManga = completedManga
            .copyWith(currentProgress: 99)
            .syncStatusWithProgress();
        expect(reducedManga.trackingStatus, TrackingStatus.reading);
      });

      test(
          'seasonal: setting overall status to Completed completes all seasons with known totals',
          () {
        const item = MediaItem(
          id: 'seasonal-all',
          title: 'Multi Season',
          coverUrl: '',
          currentProgress: 0,
          totalCount: null,
          mediaType: 'series',
          status: 'Watching',
          progressMode: ProgressMode.seasonal,
          seasons: [
            MediaSeason(
              id: 's1',
              seasonNumber: 1,
              currentProgress: 3,
              totalCount: 12,
            ),
            MediaSeason(
              id: 's2',
              seasonNumber: 2,
              currentProgress: 8,
              totalCount: 24,
            ),
            MediaSeason(
              id: 's3',
              seasonNumber: 3,
              currentProgress: 0,
              totalCount: 10,
            ),
          ],
        );

        final completed = item.applyCompletedStatus();

        expect(completed.trackingStatus, TrackingStatus.completed);
        expect(completed.seasons[0].currentProgress, 12);
        expect(completed.seasons[1].currentProgress, 24);
        expect(completed.seasons[2].currentProgress, 10);
        expect(completed.currentProgress, 46);
        expect(completed.totalCount, 46);
      });

      test(
          'seasonal: completing one season updates only that season and recalculates total',
          () {
        const item = MediaItem(
          id: 'seasonal-one',
          title: 'Multi Season',
          coverUrl: '',
          currentProgress: 0,
          totalCount: null,
          mediaType: 'series',
          status: 'Watching',
          progressMode: ProgressMode.seasonal,
          seasons: [
            MediaSeason(
              id: 's1',
              seasonNumber: 1,
              currentProgress: 4,
              totalCount: 12,
            ),
            MediaSeason(
              id: 's2',
              seasonNumber: 2,
              currentProgress: 2,
              totalCount: 24,
            ),
          ],
        );

        final updated = item.completeSeason('s1');

        expect(updated.seasons[0].currentProgress, 12);
        expect(updated.seasons[1].currentProgress, 2);
        expect(updated.currentProgress, 14);
        expect(updated.trackingStatus, TrackingStatus.watching);
      });

      test(
          'seasonal: completing final incomplete season automatically changes overall status to Completed',
          () {
        const item = MediaItem(
          id: 'seasonal-final',
          title: 'Final Season',
          coverUrl: '',
          currentProgress: 0,
          totalCount: null,
          mediaType: 'series',
          status: 'Watching',
          progressMode: ProgressMode.seasonal,
          seasons: [
            MediaSeason(
              id: 's1',
              seasonNumber: 1,
              currentProgress: 12,
              totalCount: 12,
            ),
            MediaSeason(
              id: 's2',
              seasonNumber: 2,
              currentProgress: 23,
              totalCount: 24,
            ),
          ],
        );

        final completed = item.completeSeason('s2');

        expect(completed.seasons[1].currentProgress, 24);
        expect(completed.isFullyCompleted, isTrue);
        expect(completed.trackingStatus, TrackingStatus.completed);
      });

      test('seasonal: a season with unknown total cannot be completed falsely',
          () {
        const item = MediaItem(
          id: 'seasonal-unknown',
          title: 'Unknown Season Total',
          coverUrl: '',
          currentProgress: 0,
          totalCount: null,
          mediaType: 'series',
          status: 'Watching',
          progressMode: ProgressMode.seasonal,
          seasons: [
            MediaSeason(
              id: 's1',
              seasonNumber: 1,
              currentProgress: 5,
              totalCount: null,
            ),
          ],
        );

        final attempted = item.completeSeason('s1');

        expect(attempted.seasons[0].currentProgress, 5);
        expect(attempted.seasons[0].isComplete, isFalse);
        expect(attempted.trackingStatus, TrackingStatus.watching);
      });

      test(
          'seasonal: reducing one completed season progress reverts status from Completed to Watching',
          () {
        const item = MediaItem(
          id: 'seasonal-revert',
          title: 'Completed Series',
          coverUrl: '',
          currentProgress: 0,
          totalCount: null,
          mediaType: 'series',
          status: 'Completed',
          progressMode: ProgressMode.seasonal,
          seasons: [
            MediaSeason(
              id: 's1',
              seasonNumber: 1,
              currentProgress: 12,
              totalCount: 12,
            ),
            MediaSeason(
              id: 's2',
              seasonNumber: 2,
              currentProgress: 24,
              totalCount: 24,
            ),
          ],
        );

        final updatedSeasons = item.seasons.map((s) {
          return s.id == 's1' ? s.copyWith(currentProgress: 11) : s;
        }).toList();

        final reduced =
            item.copyWith(seasons: updatedSeasons).syncStatusWithProgress();

        expect(reduced.trackingStatus, TrackingStatus.watching);
      });
    });
  });
}
