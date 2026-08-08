import 'package:flutter_test/flutter_test.dart';
import 'package:episode/models/activity_log_entry.dart';

void main() {
  group('ActivityLogEntry & StreakCalculator', () {
    test('serializes and deserializes ActivityLogEntry correctly', () {
      final now = DateTime.now().toUtc();
      final entry = ActivityLogEntry(
        id: '1',
        itemId: 'item-100',
        itemTitle: 'One Piece',
        mediaType: 'anime',
        progressDelta: 5,
        timestamp: now,
      );

      final json = entry.toJson();
      final restored = ActivityLogEntry.fromJson(json);

      expect(restored.id, '1');
      expect(restored.itemId, 'item-100');
      expect(restored.itemTitle, 'One Piece');
      expect(restored.progressDelta, 5);
    });

    test('calculates daily activity heatmap correctly', () {
      final today = DateTime(2026, 8, 8, 12, 0);
      final logs = [
        ActivityLogEntry(
          id: '1',
          itemId: 'm-1',
          itemTitle: 'Naruto',
          mediaType: 'anime',
          progressDelta: 3,
          timestamp: today,
        ),
        ActivityLogEntry(
          id: '2',
          itemId: 'm-1',
          itemTitle: 'Naruto',
          mediaType: 'anime',
          progressDelta: 2,
          timestamp: today,
        ),
      ];

      final daily = StreakCalculator.computeDailyActivity(logs);
      expect(daily['2026-08-08'], 5);
    });

    test('calculates active viewing streak correctly', () {
      final today = DateTime(2026, 8, 8);
      final yesterday = DateTime(2026, 8, 7);
      final twoDaysAgo = DateTime(2026, 8, 6);

      final logs = [
        ActivityLogEntry(
          id: '1',
          itemId: 'm-1',
          itemTitle: 'Bleach',
          mediaType: 'anime',
          progressDelta: 1,
          timestamp: today,
        ),
        ActivityLogEntry(
          id: '2',
          itemId: 'm-1',
          itemTitle: 'Bleach',
          mediaType: 'anime',
          progressDelta: 2,
          timestamp: yesterday,
        ),
        ActivityLogEntry(
          id: '3',
          itemId: 'm-1',
          itemTitle: 'Bleach',
          mediaType: 'anime',
          progressDelta: 1,
          timestamp: twoDaysAgo,
        ),
      ];

      final streak = StreakCalculator.calculateCurrentStreak(logs, now: today);
      expect(streak, 3);
    });
  });
}
