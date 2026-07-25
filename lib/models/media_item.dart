import 'dart:convert';

enum MediaType { anime, manga, series, movie }

extension MediaTypeDetails on MediaType {
  String get label {
    switch (this) {
      case MediaType.anime:
        return 'Anime';
      case MediaType.manga:
        return 'Manga';
      case MediaType.series:
        return 'Series';
      case MediaType.movie:
        return 'Movie';
    }
  }

  String get storageValue => name;

  bool get supportsProgress => this != MediaType.movie;

  bool get supportsSeasons =>
      this == MediaType.anime || this == MediaType.series;
}

MediaType mediaTypeFromStorage(Object? value) {
  switch (value?.toString().trim().toLowerCase()) {
    case 'manga':
      return MediaType.manga;
    case 'series':
    case 'tv':
    case 'tv series':
      return MediaType.series;
    case 'movie':
    case 'film':
      return MediaType.movie;
    case 'anime':
    default:
      return MediaType.anime;
  }
}

enum TrackingStatus {
  planToWatch,
  watching,
  reading,
  onHold,
  completed,
  dropped,
  unknown,
}

extension TrackingStatusDetails on TrackingStatus {
  String get label {
    switch (this) {
      case TrackingStatus.planToWatch:
        return 'Plan to Watch';
      case TrackingStatus.watching:
        return 'Watching';
      case TrackingStatus.reading:
        return 'Reading';
      case TrackingStatus.onHold:
        return 'On Hold';
      case TrackingStatus.completed:
        return 'Completed';
      case TrackingStatus.dropped:
        return 'Dropped';
      case TrackingStatus.unknown:
        return 'Unknown';
    }
  }
}

TrackingStatus trackingStatusFromStorage(Object? value) {
  switch (value?.toString().trim().toLowerCase()) {
    case 'plan to watch':
    case 'plan to read':
    case 'planned':
      return TrackingStatus.planToWatch;
    case 'watching':
      return TrackingStatus.watching;
    case 'reading':
      return TrackingStatus.reading;
    case 'on hold':
    case 'paused':
      return TrackingStatus.onHold;
    case 'completed':
    case 'watched':
    case 'finished':
      return TrackingStatus.completed;
    case 'dropped':
      return TrackingStatus.dropped;
    default:
      return TrackingStatus.unknown;
  }
}

enum ReleaseStatus { ongoing, finished, upcoming, hiatus, cancelled, unknown }

extension ReleaseStatusDetails on ReleaseStatus {
  String get label {
    switch (this) {
      case ReleaseStatus.ongoing:
        return 'Ongoing';
      case ReleaseStatus.finished:
        return 'Finished';
      case ReleaseStatus.upcoming:
        return 'Upcoming';
      case ReleaseStatus.hiatus:
        return 'Hiatus';
      case ReleaseStatus.cancelled:
        return 'Cancelled';
      case ReleaseStatus.unknown:
        return 'Unknown';
    }
  }

  String get storageValue => name;
}

ReleaseStatus releaseStatusFromStorage(Object? value) {
  final normalized = value?.toString().trim().toLowerCase() ?? '';
  switch (normalized) {
    case 'ongoing':
    case 'currently airing':
    case 'airing':
    case 'publishing':
    case 'running':
    case 'returning series':
      return ReleaseStatus.ongoing;
    case 'finished':
    case 'finished airing':
    case 'finished publishing':
    case 'ended':
      return ReleaseStatus.finished;
    case 'upcoming':
    case 'not yet aired':
    case 'not yet published':
    case 'in development':
      return ReleaseStatus.upcoming;
    case 'hiatus':
    case 'on hiatus':
      return ReleaseStatus.hiatus;
    case 'cancelled':
    case 'canceled':
    case 'discontinued':
      return ReleaseStatus.cancelled;
    default:
      return ReleaseStatus.unknown;
  }
}

enum ProgressMode { flat, seasonal }

extension ProgressModeDetails on ProgressMode {
  String get label => this == ProgressMode.flat ? 'Flat progress' : 'By season';

  String get storageValue => name;
}

ProgressMode progressModeFromStorage(Object? value) {
  return value?.toString().trim().toLowerCase() == 'seasonal'
      ? ProgressMode.seasonal
      : ProgressMode.flat;
}

class MediaSeason {
  final String id;
  final int seasonNumber;
  final String? title;
  final int currentProgress;
  final int? totalCount;
  final ReleaseStatus releaseStatus;

  const MediaSeason({
    required this.id,
    required int seasonNumber,
    this.title,
    required int currentProgress,
    required int? totalCount,
    this.releaseStatus = ReleaseStatus.unknown,
  }) : seasonNumber = seasonNumber < 1 ? 1 : seasonNumber,
       currentProgress = currentProgress < 0 ? 0 : currentProgress,
       totalCount = totalCount != null && totalCount >= 0 ? totalCount : null;

  String get displayName {
    final customTitle = title?.trim();
    return customTitle == null || customTitle.isEmpty
        ? 'Season $seasonNumber'
        : customTitle;
  }

  bool get hasKnownTotal => totalCount != null;

  bool get isBeyondKnownTotal =>
      totalCount != null && currentProgress > totalCount!;

  double get progressPercentage {
    final total = totalCount;
    if (total == null || total <= 0) {
      return 0;
    }
    return (currentProgress / total).clamp(0.0, 1.0);
  }

  String get progressSummary => '$currentProgress / ${totalCount ?? '?'}';

  MediaSeason copyWith({
    String? id,
    int? seasonNumber,
    String? title,
    bool clearTitle = false,
    int? currentProgress,
    int? totalCount,
    bool clearTotalCount = false,
    ReleaseStatus? releaseStatus,
  }) {
    return MediaSeason(
      id: id ?? this.id,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      title: clearTitle ? null : (title ?? this.title),
      currentProgress: currentProgress ?? this.currentProgress,
      totalCount: clearTotalCount ? null : (totalCount ?? this.totalCount),
      releaseStatus: releaseStatus ?? this.releaseStatus,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'seasonNumber': seasonNumber,
      'title': title,
      'currentProgress': currentProgress,
      'totalCount': totalCount,
      'releaseStatus': releaseStatus.storageValue,
    };
  }

  factory MediaSeason.fromMap(Map<String, dynamic> map) {
    return MediaSeason(
      id: map['id']?.toString() ?? '',
      seasonNumber: _nonNegativeInt(map['seasonNumber'], fallback: 1),
      title: map['title']?.toString(),
      currentProgress: _nonNegativeInt(map['currentProgress']),
      totalCount: _nonNegativeNullableInt(map['totalCount']),
      releaseStatus: releaseStatusFromStorage(map['releaseStatus']),
    );
  }
}

class MediaItem {
  static int _manualIdSequence = 0;

  final String id;
  final String title;
  final String coverUrl;
  final int _flatCurrentProgress;
  final int? _flatTotalCount;
  final String mediaType;
  final String status;
  final ReleaseStatus releaseStatus;
  final ProgressMode progressMode;
  final List<MediaSeason> seasons;
  final bool isManual;
  final String? synopsis;
  final double rating;

  const MediaItem({
    required this.id,
    required this.title,
    required this.coverUrl,
    required int currentProgress,
    required int? totalCount,
    required this.mediaType,
    required this.status,
    this.releaseStatus = ReleaseStatus.unknown,
    this.progressMode = ProgressMode.flat,
    this.seasons = const [],
    this.isManual = false,
    this.synopsis,
    this.rating = 0.0,
  }) : _flatCurrentProgress = currentProgress < 0 ? 0 : currentProgress,
       _flatTotalCount = totalCount != null && totalCount >= 0
           ? totalCount
           : null;

  MediaType get type => mediaTypeFromStorage(mediaType);

  TrackingStatus get trackingStatus => trackingStatusFromStorage(status);

  bool get supportsProgress => type.supportsProgress;

  bool get supportsSeasons => type.supportsSeasons;

  int get flatCurrentProgress => _flatCurrentProgress;

  int? get flatTotalCount => _flatTotalCount;

  int get currentProgress {
    if (progressMode == ProgressMode.seasonal) {
      return seasons.fold(0, (sum, season) => sum + season.currentProgress);
    }
    return _flatCurrentProgress;
  }

  int? get totalCount {
    if (progressMode == ProgressMode.seasonal) {
      if (seasons.isEmpty || seasons.any((season) => !season.hasKnownTotal)) {
        return null;
      }
      return seasons.fold<int>(0, (sum, season) => sum + season.totalCount!);
    }
    return _flatTotalCount;
  }

  bool get hasKnownTotal => totalCount != null;

  bool get isBeyondKnownTotal =>
      totalCount != null && currentProgress > totalCount!;

  double get progressPercentage {
    final total = totalCount;
    if (total == null || total <= 0) {
      return 0;
    }
    return (currentProgress / total).clamp(0.0, 1.0);
  }

  String get progressSummary => '$currentProgress / ${totalCount ?? '?'}';

  String get unitLabel {
    switch (type) {
      case MediaType.anime:
      case MediaType.series:
        return 'Ep';
      case MediaType.manga:
        return 'Ch';
      case MediaType.movie:
        return '';
    }
  }

  MediaSeason? get latestSeason {
    MediaSeason? result;
    for (final season in seasons) {
      if (result == null || season.seasonNumber > result.seasonNumber) {
        result = season;
      }
    }
    return result;
  }

  MediaSeason? get defaultIncrementSeason {
    MediaSeason? result;
    for (final season in seasons) {
      if (season.releaseStatus != ReleaseStatus.ongoing) {
        continue;
      }
      if (result == null || season.seasonNumber > result.seasonNumber) {
        result = season;
      }
    }
    return result;
  }

  MediaSeason? get cardSeason => defaultIncrementSeason ?? latestSeason;

  static String createManualId({DateTime? timestamp}) {
    final micros = (timestamp ?? DateTime.now()).microsecondsSinceEpoch
        .toRadixString(36);
    final sequence = (_manualIdSequence++).toRadixString(36);
    return 'manual_${micros}_$sequence';
  }

  static String createSeasonId(String mediaId, int seasonNumber) {
    final micros = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    return '$mediaId-season-$seasonNumber-$micros';
  }

  MediaItem copyWith({
    String? id,
    String? title,
    String? coverUrl,
    int? currentProgress,
    int? totalCount,
    bool clearTotalCount = false,
    String? mediaType,
    String? status,
    ReleaseStatus? releaseStatus,
    ProgressMode? progressMode,
    List<MediaSeason>? seasons,
    bool? isManual,
    String? synopsis,
    bool clearSynopsis = false,
    double? rating,
  }) {
    final nextMode = progressMode ?? this.progressMode;
    final changingToFlat =
        this.progressMode == ProgressMode.seasonal &&
        nextMode == ProgressMode.flat;
    final nextFlatProgress =
        currentProgress ??
        (changingToFlat ? this.currentProgress : _flatCurrentProgress);
    final int? nextFlatTotal;
    if (clearTotalCount) {
      nextFlatTotal = null;
    } else if (totalCount != null) {
      nextFlatTotal = totalCount;
    } else if (changingToFlat) {
      nextFlatTotal = this.totalCount;
    } else {
      nextFlatTotal = _flatTotalCount;
    }

    return MediaItem(
      id: id ?? this.id,
      title: title ?? this.title,
      coverUrl: coverUrl ?? this.coverUrl,
      currentProgress: nextFlatProgress,
      totalCount: nextFlatTotal,
      mediaType: mediaType ?? this.mediaType,
      status: status ?? this.status,
      releaseStatus: releaseStatus ?? this.releaseStatus,
      progressMode: nextMode,
      seasons: seasons ?? this.seasons,
      isManual: isManual ?? this.isManual,
      synopsis: clearSynopsis ? null : (synopsis ?? this.synopsis),
      rating: rating ?? this.rating,
    );
  }

  MediaItem incrementFlatProgress() {
    if (!supportsProgress || progressMode != ProgressMode.flat) {
      return this;
    }
    return copyWith(currentProgress: _flatCurrentProgress + 1);
  }

  MediaItem incrementSeason(String seasonId) {
    if (progressMode != ProgressMode.seasonal) {
      return this;
    }
    var found = false;
    final updatedSeasons = seasons.map((season) {
      if (season.id != seasonId) {
        return season;
      }
      found = true;
      return season.copyWith(currentProgress: season.currentProgress + 1);
    }).toList();
    return found ? copyWith(seasons: updatedSeasons) : this;
  }

  MediaItem upsertSeason(MediaSeason season) {
    if (!supportsSeasons) {
      throw StateError('$mediaType does not support season tracking.');
    }
    final hasDuplicateNumber = seasons.any(
      (existing) =>
          existing.id != season.id &&
          existing.seasonNumber == season.seasonNumber,
    );
    if (hasDuplicateNumber) {
      throw ArgumentError.value(
        season.seasonNumber,
        'seasonNumber',
        'Season numbers must be unique within a media item.',
      );
    }

    final updated = List<MediaSeason>.from(seasons);
    final index = updated.indexWhere((existing) => existing.id == season.id);
    if (index >= 0) {
      updated[index] = season;
    } else {
      updated.add(season);
    }
    updated.sort((a, b) => a.seasonNumber.compareTo(b.seasonNumber));
    return copyWith(seasons: updated);
  }

  MediaItem removeSeason(String seasonId) {
    return copyWith(
      seasons: seasons.where((season) => season.id != seasonId).toList(),
    );
  }

  MediaItem convertedTo(ProgressMode mode) {
    if (!supportsSeasons || progressMode == mode) {
      return this;
    }
    if (mode == ProgressMode.seasonal) {
      final convertedSeasons = seasons.isNotEmpty
          ? seasons
          : [
              MediaSeason(
                id: createSeasonId(id, 1),
                seasonNumber: 1,
                currentProgress: _flatCurrentProgress,
                totalCount: _flatTotalCount,
                releaseStatus: releaseStatus,
              ),
            ];
      return copyWith(
        progressMode: ProgressMode.seasonal,
        seasons: convertedSeasons,
      );
    }

    final aggregateTotal = totalCount;
    return copyWith(
      progressMode: ProgressMode.flat,
      currentProgress: currentProgress,
      totalCount: aggregateTotal,
      clearTotalCount: aggregateTotal == null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'coverUrl': coverUrl,
      // Active values remain in legacy keys for backward-compatible readers.
      'currentProgress': currentProgress,
      'totalCount': totalCount,
      // Flat snapshots make progress-mode conversion reversible. They are only
      // authoritative while progressMode is flat.
      'flatCurrentProgress': _flatCurrentProgress,
      'flatTotalCount': _flatTotalCount,
      'mediaType': type.storageValue,
      'status': status,
      'releaseStatus': releaseStatus.storageValue,
      'progressMode': progressMode.storageValue,
      'seasons': seasons.map((season) => season.toMap()).toList(),
      'isManual': isManual,
      'synopsis': synopsis,
      'rating': rating,
    };
  }

  factory MediaItem.fromMap(Map<String, dynamic> map) {
    final rawSeasons = map['seasons'];
    final seasons = rawSeasons is List
        ? rawSeasons
              .whereType<Map>()
              .map(
                (season) =>
                    MediaSeason.fromMap(Map<String, dynamic>.from(season)),
              )
              .toList()
        : <MediaSeason>[];
    final mode = progressModeFromStorage(map['progressMode']);
    final currentProgress = _nonNegativeInt(
      map.containsKey('flatCurrentProgress')
          ? map['flatCurrentProgress']
          : map['currentProgress'],
    );
    final hasFlatSnapshot = map.containsKey('flatTotalCount');
    final totalCount = hasFlatSnapshot
        ? _nonNegativeNullableInt(map['flatTotalCount'])
        : _positiveNullableInt(map['totalCount']);

    return MediaItem(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      coverUrl: map['coverUrl']?.toString() ?? '',
      currentProgress: currentProgress,
      totalCount: totalCount,
      mediaType: mediaTypeFromStorage(map['mediaType']).storageValue,
      status: map['status']?.toString() ?? 'Watching',
      releaseStatus: releaseStatusFromStorage(map['releaseStatus']),
      progressMode: mode,
      seasons: seasons,
      isManual: map['isManual'] == true,
      synopsis: map['synopsis']?.toString(),
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory MediaItem.fromJson(String source) {
    return MediaItem.fromMap(
      Map<String, dynamic>.from(jsonDecode(source) as Map),
    );
  }
}

int _nonNegativeInt(Object? value, {int fallback = 0}) {
  if (value is num) {
    final converted = value.toInt();
    return converted < 0 ? 0 : converted;
  }
  return fallback;
}

int? _nonNegativeNullableInt(Object? value) {
  if (value is! num) {
    return null;
  }
  final converted = value.toInt();
  return converted >= 0 ? converted : null;
}

int? _positiveNullableInt(Object? value) {
  if (value is! num) {
    return null;
  }
  final converted = value.toInt();
  return converted > 0 ? converted : null;
}
