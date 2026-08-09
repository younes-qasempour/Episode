import 'media_item.dart';

/// Stat distribution segment container.
class StatSegment<T> {
  final T key;
  final String label;
  final int count;
  final double percentage;

  const StatSegment({
    required this.key,
    required this.label,
    required this.count,
    required this.percentage,
  });
}

/// Calculated statistics and analytics over a collection of [MediaItem]s.
class LibraryStats {
  final int totalItems;
  final int totalEpisodesWatched;
  final int totalChaptersRead;
  final int totalMoviesWatched;
  final double estimatedWatchTimeHours;
  final double estimatedReadTimeHours;
  final double meanScore;
  final int ratedItemCount;
  final List<StatSegment<MediaType>> mediaTypeSegments;
  final List<StatSegment<TrackingStatus>> statusSegments;
  final List<String> topGenres;

  const LibraryStats({
    required this.totalItems,
    required this.totalEpisodesWatched,
    required this.totalChaptersRead,
    required this.totalMoviesWatched,
    required this.estimatedWatchTimeHours,
    required this.estimatedReadTimeHours,
    required this.meanScore,
    required this.ratedItemCount,
    required this.mediaTypeSegments,
    required this.statusSegments,
    required this.topGenres,
  });

  /// Calculates [LibraryStats] from a list of [MediaItem]s.
  factory LibraryStats.fromItems(List<MediaItem> items) {
    if (items.isEmpty) {
      return const LibraryStats(
        totalItems: 0,
        totalEpisodesWatched: 0,
        totalChaptersRead: 0,
        totalMoviesWatched: 0,
        estimatedWatchTimeHours: 0,
        estimatedReadTimeHours: 0,
        meanScore: 0.0,
        ratedItemCount: 0,
        mediaTypeSegments: [],
        statusSegments: [],
        topGenres: [],
      );
    }

    int episodes = 0;
    int chapters = 0;
    int moviesWatched = 0;
    double scoreSum = 0;
    int ratedCount = 0;

    final Map<MediaType, int> typeCounts = {
      for (final t in MediaType.values) t: 0,
    };
    final Map<TrackingStatus, int> statusCounts = {
      for (final st in TrackingStatus.values)
        if (st != TrackingStatus.unknown) st: 0,
    };
    final Map<String, int> tagFrequency = {};

    for (final item in items) {
      final mediaTypeEnum = item.type;
      final statusEnum = item.trackingStatus;

      // Type breakdown
      typeCounts[mediaTypeEnum] = (typeCounts[mediaTypeEnum] ?? 0) + 1;

      // Status breakdown
      if (statusEnum != TrackingStatus.unknown) {
        statusCounts[statusEnum] = (statusCounts[statusEnum] ?? 0) + 1;
      }

      // Milestones & progress
      if (mediaTypeEnum == MediaType.manga) {
        chapters += item.currentProgress;
      } else if (mediaTypeEnum == MediaType.movie) {
        if (statusEnum == TrackingStatus.completed) {
          moviesWatched += 1;
        }
      } else {
        // Anime or Series
        episodes += item.currentProgress;
      }

      // Ratings
      if (item.rating > 0) {
        scoreSum += item.rating;
        ratedCount += 1;
      }

      // Tags / Genres
      for (final tag in item.tags) {
        final trimmed = tag.trim();
        if (trimmed.isNotEmpty) {
          tagFrequency[trimmed] = (tagFrequency[trimmed] ?? 0) + 1;
        }
      }
    }

    final double avgScore = ratedCount > 0 ? scoreSum / ratedCount : 0.0;

    // Standard assumptions: 24 min per episode, 120 min per movie, 5 min per manga chapter
    final double watchHours = (episodes * 24 + moviesWatched * 120) / 60.0;
    final double readHours = (chapters * 5) / 60.0;

    final int totalCount = items.length;

    final List<StatSegment<MediaType>> mediaTypeSegs = MediaType.values
        .map((t) {
          final c = typeCounts[t] ?? 0;
          return StatSegment<MediaType>(
            key: t,
            label: t.label,
            count: c,
            percentage: totalCount > 0 ? (c / totalCount) * 100 : 0.0,
          );
        })
        .where((s) => s.count > 0)
        .toList();

    final List<StatSegment<TrackingStatus>> statusSegs = TrackingStatus.values
        .where((st) => st != TrackingStatus.unknown)
        .map((st) {
          final c = statusCounts[st] ?? 0;
          return StatSegment<TrackingStatus>(
            key: st,
            label: st.label,
            count: c,
            percentage: totalCount > 0 ? (c / totalCount) * 100 : 0.0,
          );
        })
        .where((s) => s.count > 0)
        .toList();

    // Sort tags by frequency
    final sortedTags = tagFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top3Tags = sortedTags.take(3).map((e) => e.key).toList();

    return LibraryStats(
      totalItems: totalCount,
      totalEpisodesWatched: episodes,
      totalChaptersRead: chapters,
      totalMoviesWatched: moviesWatched,
      estimatedWatchTimeHours: watchHours,
      estimatedReadTimeHours: readHours,
      meanScore: double.parse(avgScore.toStringAsFixed(1)),
      ratedItemCount: ratedCount,
      mediaTypeSegments: mediaTypeSegs,
      statusSegments: statusSegs,
      topGenres: top3Tags,
    );
  }
}
