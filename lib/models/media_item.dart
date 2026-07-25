import 'dart:convert';

class MediaItem {
  final String id;
  final String title;
  final String coverUrl;
  final int currentProgress;
  final int totalCount;
  final String mediaType; // 'anime', 'manga', 'series'
  final String status;    // 'Watching', 'Reading', 'Plan to Watch', 'Completed', 'On Hold'
  final String? synopsis;
  final double rating;    // 0.0 to 10.0 scale

  const MediaItem({
    required this.id,
    required this.title,
    required this.coverUrl,
    required this.currentProgress,
    required this.totalCount,
    required this.mediaType,
    required this.status,
    this.synopsis,
    this.rating = 0.0,
  });

  double get progressPercentage => totalCount > 0 ? (currentProgress / totalCount).clamp(0.0, 1.0) : 0.0;

  String get unitLabel {
    switch (mediaType.toLowerCase()) {
      case 'anime':
      case 'series':
        return 'Ep';
      case 'manga':
        return 'Ch';
      default:
        return 'Item';
    }
  }

  MediaItem copyWith({
    String? id,
    String? title,
    String? coverUrl,
    int? currentProgress,
    int? totalCount,
    String? mediaType,
    String? status,
    String? synopsis,
    double? rating,
  }) {
    return MediaItem(
      id: id ?? this.id,
      title: title ?? this.title,
      coverUrl: coverUrl ?? this.coverUrl,
      currentProgress: currentProgress ?? this.currentProgress,
      totalCount: totalCount ?? this.totalCount,
      mediaType: mediaType ?? this.mediaType,
      status: status ?? this.status,
      synopsis: synopsis ?? this.synopsis,
      rating: rating ?? this.rating,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'coverUrl': coverUrl,
      'currentProgress': currentProgress,
      'totalCount': totalCount,
      'mediaType': mediaType,
      'status': status,
      'synopsis': synopsis,
      'rating': rating,
    };
  }

  factory MediaItem.fromMap(Map<String, dynamic> map) {
    return MediaItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      coverUrl: map['coverUrl'] ?? '',
      currentProgress: map['currentProgress'] ?? 0,
      totalCount: map['totalCount'] ?? 0,
      mediaType: map['mediaType'] ?? 'anime',
      status: map['status'] ?? 'Watching',
      synopsis: map['synopsis'],
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory MediaItem.fromJson(String source) => MediaItem.fromMap(jsonDecode(source));
}
