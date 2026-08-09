import 'dart:convert';

/// Represents a single activity log entry recorded when progress is updated.
class ActivityLogEntry {
  final String id;
  final String itemId;
  final String itemTitle;
  final String mediaType;
  final int progressDelta;
  final DateTime timestamp;

  const ActivityLogEntry({
    required this.id,
    required this.itemId,
    required this.itemTitle,
    required this.mediaType,
    required this.progressDelta,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'itemTitle': itemTitle,
      'mediaType': mediaType,
      'progressDelta': progressDelta,
      'timestamp': timestamp.toUtc().toIso8601String(),
    };
  }

  factory ActivityLogEntry.fromJson(Map<String, dynamic> json) {
    return ActivityLogEntry(
      id: json['id']?.toString() ?? '',
      itemId: json['itemId']?.toString() ?? '',
      itemTitle: json['itemTitle']?.toString() ?? 'Media Item',
      mediaType: json['mediaType']?.toString() ?? 'anime',
      progressDelta:
          json['progressDelta'] is int ? json['progressDelta'] as int : 1,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString())?.toUtc() ??
              DateTime.now().toUtc()
          : DateTime.now().toUtc(),
    );
  }

  String encode() => jsonEncode(toJson());

  factory ActivityLogEntry.decode(String raw) {
    return ActivityLogEntry.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}

/// Computes daily contribution heatmap map (Date String -> Activity Count) and current streak.
class StreakCalculator {
  static Map<String, int> computeDailyActivity(List<ActivityLogEntry> logs) {
    final Map<String, int> dailyCounts = {};
    for (final log in logs) {
      final key = _dateKey(log.timestamp.toLocal());
      dailyCounts[key] = (dailyCounts[key] ?? 0) + log.progressDelta;
    }
    return dailyCounts;
  }

  static int calculateCurrentStreak(List<ActivityLogEntry> logs,
      {DateTime? now}) {
    if (logs.isEmpty) return 0;
    final today = now ?? DateTime.now();
    final daily = computeDailyActivity(logs);

    int streak = 0;
    DateTime checkDate = today;

    // Check today first; if no activity today, check yesterday
    final todayKey = _dateKey(today);
    final yesterdayKey = _dateKey(today.subtract(const Duration(days: 1)));

    if (!daily.containsKey(todayKey) && !daily.containsKey(yesterdayKey)) {
      return 0;
    }

    if (!daily.containsKey(todayKey)) {
      checkDate = today.subtract(const Duration(days: 1));
    }

    while (true) {
      final key = _dateKey(checkDate);
      if (daily.containsKey(key) && daily[key]! > 0) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  static String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
