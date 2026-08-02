import 'dart:convert';
import 'dart:typed_data';

import '../models/data_transfer.dart';
import '../models/media_item.dart';
import 'native_backup_service.dart';

class CsvExportProvider implements ExportProvider {
  const CsvExportProvider();

  static const _headers = [
    'id',
    'title',
    'mediaType',
    'status',
    'releaseStatus',
    'progressMode',
    'currentProgress',
    'totalCount',
    'rating',
    'isManual',
    'isFavorite',
    'repeatCount',
    'startedAt',
    'completedAt',
    'addedAt',
    'updatedAt',
    'tags',
    'notes',
    'synopsis',
    'coverUrl',
    'externalIds',
    'seasons',
    'customMetadata',
  ];

  @override
  String get id => 'csv';

  @override
  String get displayName => 'CSV';

  @override
  Future<ExportArtifact> export(
    List<MediaItem> items, {
    MediaType? mediaType,
  }) async {
    final selected = mediaType == null
        ? items
        : items.where((item) => item.type == mediaType).toList();
    final buffer = StringBuffer('\uFEFF')..writeln(_row(_headers));
    for (final item in selected) {
      buffer.writeln(
        _row([
          item.id,
          item.title,
          item.type.storageValue,
          item.status,
          item.releaseStatus.storageValue,
          item.progressMode.storageValue,
          item.currentProgress,
          item.totalCount,
          item.rating,
          item.isManual,
          item.isFavorite,
          item.repeatCount,
          item.startedAt?.toUtc().toIso8601String(),
          item.completedAt?.toUtc().toIso8601String(),
          item.addedAt?.toUtc().toIso8601String(),
          item.updatedAt?.toUtc().toIso8601String(),
          item.tags.join(', '),
          item.notes,
          item.synopsis,
          item.coverUrl,
          jsonEncode(item.externalIds),
          jsonEncode(item.seasons.map((season) => season.toMap()).toList()),
          jsonEncode(item.customMetadata),
        ]),
      );
    }
    final now = DateTime.now().toUtc();
    return ExportArtifact(
      fileName: 'otakulog-${mediaType?.name ?? 'library'}-'
          '${fileTimestamp(now)}.csv',
      mimeType: 'text/csv;charset=utf-8',
      bytes: Uint8List.fromList(utf8.encode(buffer.toString())),
      exportedCount: selected.length,
    );
  }

  String _row(List<Object?> values) {
    return values.map(_field).join(',');
  }

  String _field(Object? value) {
    final text = value?.toString() ?? '';
    if (text.contains(',') ||
        text.contains('"') ||
        text.contains('\r') ||
        text.contains('\n')) {
      return '"${text.replaceAll('"', '""')}"';
    }
    return text;
  }
}
