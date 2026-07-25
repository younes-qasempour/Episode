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
    test('loadMediaItems initializes with default sample items when empty', () async {
      final repository = LocalStorageRepository();
      final items = await repository.loadMediaItems();

      expect(items.length, greaterThan(0));
      expect(items.any((i) => i.title == 'Jujutsu Kaisen Season 2'), isTrue);
    });

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

    test('incrementProgress increments episode count and updates status when completed', () async {
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
      expect(updatedItem.status, equals('Completed'));
    });

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

      final updated = initialItem.copyWith(
        rating: 9.0,
        status: 'Completed',
      );

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
  });
}
