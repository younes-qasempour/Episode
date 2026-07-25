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

      expect(decoded.id, startsWith('manual_'));
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
  });
}
