import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';

import '../models/data_transfer.dart';
import '../models/media_item.dart';
import 'native_backup_service.dart';

class MalXmlImportProvider implements ImportProvider {
  static const maxCompressedBytes = 10 * 1024 * 1024;
  static const maxExpandedBytes = 25 * 1024 * 1024;

  const MalXmlImportProvider();

  @override
  String get id => 'myanimelist-xml';

  @override
  String get displayName => 'MyAnimeList XML';

  @override
  List<String> get supportedExtensions => const ['xml', 'gz'];

  @override
  bool canHandle(ImportSource source) {
    if (source.bytes.length >= 2 &&
        source.bytes[0] == 0x1f &&
        source.bytes[1] == 0x8b) {
      return true;
    }
    if (source.extension == 'xml' || source.extension == 'gz') {
      return true;
    }
    final prefixLength = source.bytes.length.clamp(0, 512);
    final prefix = utf8.decode(
      source.bytes.sublist(0, prefixLength),
      allowMalformed: true,
    );
    return prefix.contains('<myanimelist') ||
        prefix.contains('<anime>') ||
        prefix.contains('<manga>');
  }

  @override
  Future<ImportInspectionResult> inspect(ImportSource source) {
    if (source.bytes.length >= 128 * 1024) {
      return compute(_inspectMalSource, source);
    }
    return Future.value(_inspectMalSource(source));
  }
}

ImportInspectionResult _inspectMalSource(ImportSource source) {
  if (source.bytes.isEmpty) {
    throw const DataTransferException(
      'The selected MyAnimeList file is empty.',
      code: 'empty_file',
    );
  }
  if (source.bytes.length > MalXmlImportProvider.maxCompressedBytes) {
    throw const DataTransferException(
      'The selected file exceeds the 10 MB compressed-file safety limit.',
      code: 'file_too_large',
    );
  }

  Uint8List xmlBytes = source.bytes;
  final isGzip = source.bytes.length >= 2 &&
      source.bytes[0] == 0x1f &&
      source.bytes[1] == 0x8b;
  if (isGzip) {
    try {
      xmlBytes = const GZipDecoder().decodeBytes(source.bytes, verify: true);
    } catch (_) {
      throw const DataTransferException(
        'The compressed MyAnimeList export is invalid or corrupted.',
        code: 'invalid_gzip',
      );
    }
  }
  if (xmlBytes.length > MalXmlImportProvider.maxExpandedBytes) {
    throw const DataTransferException(
      'The expanded XML exceeds the 25 MB safety limit.',
      code: 'expanded_file_too_large',
    );
  }

  final warnings = <ImportWarning>[];
  String xmlText;
  try {
    xmlText = utf8.decode(xmlBytes).replaceFirst('\uFEFF', '');
  } on FormatException {
    xmlText = latin1.decode(xmlBytes).replaceFirst('\uFEFF', '');
    warnings.add(
      const ImportWarning(
        'legacy_encoding',
        'The XML was decoded with ISO-8859-1 compatibility mode.',
      ),
    );
  }

  final lower = xmlText.toLowerCase();
  if (lower.contains('<!doctype') || lower.contains('<!entity')) {
    throw const DataTransferException(
      'XML document type and entity declarations are not allowed.',
      code: 'unsafe_xml',
    );
  }

  final XmlDocument document;
  try {
    document = XmlDocument.parse(xmlText);
  } on XmlException {
    throw const DataTransferException(
      'The MyAnimeList XML is malformed.',
      code: 'invalid_xml',
    );
  }
  if (document.rootElement.name.local != 'myanimelist') {
    throw const DataTransferException(
      'The XML root must be <myanimelist>.',
      code: 'wrong_xml_root',
    );
  }

  final animeElements = document.rootElement.findElements('anime').toList();
  final mangaElements = document.rootElement.findElements('manga').toList();
  if (animeElements.isNotEmpty && mangaElements.isNotEmpty) {
    throw const DataTransferException(
      'Anime and manga entries must be imported from separate MAL exports.',
      code: 'mixed_mal_export',
    );
  }

  final sourceType = _detectSourceType(
    document.rootElement,
    animeElements,
    mangaElements,
  );
  final elements =
      sourceType == ImportSourceType.malAnime ? animeElements : mangaElements;
  final entries = <ImportedMediaEntry>[];
  final seenIds = <String>{};

  for (var index = 0; index < elements.length; index++) {
    final element = elements[index];
    final parsed = _parseMalEntry(element, sourceType, warnings, index + 1);
    if (parsed == null) {
      continue;
    }
    final duplicateKey = '${parsed.mediaType.name}:${parsed.sourceId}';
    if (!seenIds.add(duplicateKey)) {
      warnings.add(
        ImportWarning(
          'duplicate_source_id',
          'Duplicate MAL ID ${parsed.sourceId} was skipped.',
          entryTitle: parsed.title,
        ),
      );
      continue;
    }
    entries.add(parsed);
  }

  return ImportInspectionResult(
    providerId: 'myanimelist-xml',
    providerName: 'MyAnimeList XML',
    sourceType: sourceType,
    fileName: source.fileName,
    entries: entries,
    warnings: warnings,
  );
}

ImportSourceType _detectSourceType(
  XmlElement root,
  List<XmlElement> anime,
  List<XmlElement> manga,
) {
  if (anime.isNotEmpty) {
    return ImportSourceType.malAnime;
  }
  if (manga.isNotEmpty) {
    return ImportSourceType.malManga;
  }
  XmlElement? info;
  for (final child in root.findElements('myinfo')) {
    info = child;
    break;
  }
  final exportType = info == null ? null : _childText(info, 'user_export_type');
  if (exportType == '1') {
    return ImportSourceType.malAnime;
  }
  if (exportType == '2') {
    return ImportSourceType.malManga;
  }
  throw const DataTransferException(
    'The XML does not contain a recognizable anime or manga list.',
    code: 'unknown_mal_list_type',
  );
}

ImportedMediaEntry? _parseMalEntry(
  XmlElement element,
  ImportSourceType sourceType,
  List<ImportWarning> warnings,
  int index,
) {
  final isAnime = sourceType == ImportSourceType.malAnime;
  final idField = isAnime ? 'series_animedb_id' : 'series_mangadb_id';
  final totalField = isAnime ? 'series_episodes' : 'series_chapters';
  final progressField = isAnime ? 'my_watched_episodes' : 'my_read_chapters';
  final id = _positiveInt(_childText(element, idField));
  final title = _childText(element, 'series_title').trim();
  final progress = _intOrNull(_childText(element, progressField));
  final total = _intOrNull(_childText(element, totalField));
  final score = _doubleOrNull(_childText(element, 'my_score')) ?? 0;

  if (id == null || title.isEmpty || title.length > 500) {
    warnings.add(
      ImportWarning(
        'invalid_entry',
        'Entry $index is missing a valid MAL ID/title or has an oversized title.',
        entryTitle: title.isEmpty ? null : title,
      ),
    );
    return null;
  }
  if (progress == null || progress < 0 || (total != null && total < 0)) {
    warnings.add(
      ImportWarning(
        'invalid_progress',
        'Entry $index has invalid progress and was skipped.',
        entryTitle: title,
      ),
    );
    return null;
  }
  if (score < 0 || score > 10) {
    warnings.add(
      ImportWarning(
        'invalid_score',
        'Entry $index has a score outside 0-10 and was skipped.',
        entryTitle: title,
      ),
    );
    return null;
  }

  final rawStatus = _childText(element, 'my_status');
  final status = _malStatus(rawStatus, isAnime: isAnime);
  if (status == 'Unknown') {
    warnings.add(
      ImportWarning(
        'unknown_status',
        'Unknown MAL status "$rawStatus" was preserved as Unknown.',
        entryTitle: title,
      ),
    );
  }

  var notes = _childText(element, 'my_comments').trim();
  if (notes.length > 50000) {
    notes = notes.substring(0, 50000);
    warnings.add(
      ImportWarning(
        'notes_truncated',
        'Notes longer than 50,000 characters were truncated.',
        entryTitle: title,
      ),
    );
  }
  final tags = _childText(element, 'my_tags')
      .split(',')
      .map((tag) => tag.trim())
      .where((tag) => tag.isNotEmpty)
      .toSet()
      .take(100)
      .toList(growable: false);
  final repeatField = isAnime ? 'my_times_watched' : 'my_times_read';
  final repeatCount = _intOrNull(_childText(element, repeatField)) ?? 0;
  final metadata = <String, dynamic>{
    'provider': 'myanimelist',
    'providerMediaType': _childText(element, 'series_type'),
    'providerSeriesStatus': _childText(element, 'series_status'),
    'volumesRead':
        isAnime ? null : _intOrNull(_childText(element, 'my_read_volumes')),
    'totalVolumes':
        isAnime ? null : _intOrNull(_childText(element, 'series_volumes')),
    'priority': _childText(element, 'my_priority'),
    'rewatchOrRereadValue': _childText(
      element,
      isAnime ? 'my_rewatch_value' : 'my_reread_value',
    ),
    'isRepeating': _truthy(
      _childText(element, isAnime ? 'my_rewatching' : 'my_rereading'),
    ),
  }..removeWhere((_, value) => value == null || value == '');

  return ImportedMediaEntry(
    mediaType: isAnime ? MediaType.anime : MediaType.manga,
    sourceProvider: 'myanimelist',
    sourceId: '$id',
    externalIds: {'mal': '$id', 'jikan': '$id'},
    title: title,
    status: status,
    releaseStatus: _malReleaseStatus(_childText(element, 'series_status')),
    progress: progress,
    totalUnits: total == null || total == 0 ? null : total,
    score: score,
    notes: notes.isEmpty ? null : notes,
    tags: tags,
    startedAt: _malDate(_childText(element, 'my_start_date')),
    completedAt: _malDate(_childText(element, 'my_finish_date')),
    updatedAt: _malUpdatedAt(_childText(element, 'my_last_updated')),
    repeatCount: repeatCount < 0 ? 0 : repeatCount,
    sourceMetadata: metadata,
  );
}

String _childText(XmlElement parent, String name) {
  for (final element in parent.findElements(name)) {
    return element.innerText;
  }
  return '';
}

int? _intOrNull(String value) => int.tryParse(value.trim());

int? _positiveInt(String value) {
  final parsed = _intOrNull(value);
  return parsed != null && parsed > 0 ? parsed : null;
}

double? _doubleOrNull(String value) => double.tryParse(value.trim());

bool _truthy(String value) {
  final normalized = value.trim().toLowerCase();
  return normalized == '1' || normalized == 'true' || normalized == 'yes';
}

DateTime? _malDate(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty || normalized == '0000-00-00') {
    return null;
  }
  return DateTime.tryParse(normalized);
}

DateTime? _malUpdatedAt(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty || normalized == '0') {
    return null;
  }
  final unix = int.tryParse(normalized);
  if (unix != null) {
    return DateTime.fromMillisecondsSinceEpoch(unix * 1000, isUtc: true);
  }
  return DateTime.tryParse(normalized);
}

String _malStatus(String value, {required bool isAnime}) {
  switch (value.trim().toLowerCase().replaceAll('_', ' ')) {
    case '1':
    case 'watching':
      return isAnime ? 'Watching' : 'Reading';
    case 'reading':
      return 'Reading';
    case '2':
    case 'completed':
      return 'Completed';
    case '3':
    case 'on hold':
    case 'on-hold':
      return 'On Hold';
    case '4':
    case 'dropped':
      return 'Dropped';
    case '6':
    case 'plan to watch':
    case 'plan to read':
      return isAnime ? 'Plan to Watch' : 'Plan to Read';
    default:
      return 'Unknown';
  }
}

ReleaseStatus _malReleaseStatus(String value) {
  switch (value.trim().toLowerCase()) {
    case '1':
    case 'airing':
    case 'publishing':
      return ReleaseStatus.ongoing;
    case '2':
    case 'finished airing':
    case 'finished publishing':
      return ReleaseStatus.finished;
    case '3':
    case 'not yet aired':
    case 'not yet published':
      return ReleaseStatus.upcoming;
    default:
      return releaseStatusFromStorage(value);
  }
}

class MalXmlExportProvider implements ExportProvider {
  const MalXmlExportProvider();

  @override
  String get id => 'myanimelist-xml';

  @override
  String get displayName => 'MyAnimeList XML';

  @override
  Future<ExportArtifact> export(
    List<MediaItem> items, {
    MediaType? mediaType,
  }) async {
    if (mediaType != MediaType.anime && mediaType != MediaType.manga) {
      throw const DataTransferException(
        'Choose anime or manga for a MyAnimeList-compatible export.',
        code: 'mal_type_required',
      );
    }
    final selectedType = mediaType!;
    final activeItems = items.where((item) => item.deletedAt == null).toList();
    final matching =
        activeItems.where((item) => item.type == selectedType).toList();
    final representable = <(MediaItem, int)>[];
    final warnings = <String>[];
    for (final item in matching) {
      final malId = _malIdFor(item);
      if (malId == null) {
        warnings.add('${item.title}: missing MAL ID');
      } else {
        representable.add((item, malId));
      }
    }

    final builder = XmlBuilder();
    builder.declaration(encoding: 'UTF-8');
    builder.element('myanimelist', nest: () {
      _buildMyInfo(builder, selectedType, representable.length);
      for (final record in representable) {
        if (selectedType == MediaType.anime) {
          _buildAnime(builder, record.$1, record.$2);
        } else {
          _buildManga(builder, record.$1, record.$2);
        }
      }
    });
    final xml = builder.buildDocument().toXmlString(pretty: true, indent: '  ');
    try {
      XmlDocument.parse(xml);
    } on XmlException {
      throw const DataTransferException(
        'Generated MyAnimeList XML failed validation.',
        code: 'generated_xml_invalid',
      );
    }
    final now = DateTime.now().toUtc();
    return ExportArtifact(
      fileName: 'episode-mal-${selectedType.name}-${fileTimestamp(now)}.xml',
      mimeType: 'application/xml',
      bytes: Uint8List.fromList(utf8.encode(xml)),
      exportedCount: representable.length,
      skippedCount: matching.length - representable.length,
      warnings: warnings,
    );
  }

  void _buildMyInfo(XmlBuilder builder, MediaType type, int count) {
    builder.element('myinfo', nest: () {
      _element(builder, 'user_id', 0);
      _element(builder, 'user_name', 'Episode');
      _element(builder, 'user_export_type', type == MediaType.anime ? 1 : 2);
      _element(
          builder,
          type == MediaType.anime ? 'user_total_anime' : 'user_total_manga',
          count);
    });
  }

  void _buildAnime(XmlBuilder builder, MediaItem item, int malId) {
    builder.element('anime', nest: () {
      _element(builder, 'series_animedb_id', malId);
      _element(builder, 'series_title', item.title);
      _element(builder, 'series_type', 'TV');
      _element(builder, 'series_episodes', item.totalCount ?? 0);
      _element(builder, 'my_id', 0);
      _element(builder, 'my_watched_episodes', item.currentProgress);
      _element(builder, 'my_start_date', _dateText(item.startedAt));
      _element(builder, 'my_finish_date', _dateText(item.completedAt));
      _element(builder, 'my_rated', item.rating > 0 ? 'Rated' : '');
      _element(builder, 'my_score', item.rating.round().clamp(0, 10));
      _element(builder, 'my_status', _malExportStatus(item, isAnime: true));
      _element(builder, 'my_comments', item.notes ?? '');
      _element(builder, 'my_times_watched', item.repeatCount);
      _element(builder, 'my_rewatch_value', '');
      _element(builder, 'my_tags', item.tags.join(', '));
      _element(builder, 'my_rewatching', 0);
      _element(builder, 'my_last_updated', _unixSeconds(item.updatedAt));
      _element(builder, 'update_on_import', 1);
    });
  }

  void _buildManga(XmlBuilder builder, MediaItem item, int malId) {
    final volumesRead = item.customMetadata['volumesRead'] as num?;
    final totalVolumes = item.customMetadata['totalVolumes'] as num?;
    builder.element('manga', nest: () {
      _element(builder, 'series_mangadb_id', malId);
      _element(builder, 'series_title', item.title);
      _element(builder, 'series_type', 'Manga');
      _element(builder, 'series_chapters', item.totalCount ?? 0);
      _element(builder, 'series_volumes', totalVolumes?.toInt() ?? 0);
      _element(builder, 'my_id', 0);
      _element(builder, 'my_read_chapters', item.currentProgress);
      _element(builder, 'my_read_volumes', volumesRead?.toInt() ?? 0);
      _element(builder, 'my_start_date', _dateText(item.startedAt));
      _element(builder, 'my_finish_date', _dateText(item.completedAt));
      _element(builder, 'my_score', item.rating.round().clamp(0, 10));
      _element(builder, 'my_status', _malExportStatus(item, isAnime: false));
      _element(builder, 'my_comments', item.notes ?? '');
      _element(builder, 'my_times_read', item.repeatCount);
      _element(builder, 'my_reread_value', '');
      _element(builder, 'my_tags', item.tags.join(', '));
      _element(builder, 'my_rereading', 0);
      _element(builder, 'my_last_updated', _unixSeconds(item.updatedAt));
      _element(builder, 'update_on_import', 1);
    });
  }

  void _element(XmlBuilder builder, String name, Object value) {
    builder.element(name, nest: () => builder.text(value));
  }

  int? _malIdFor(MediaItem item) {
    final direct = int.tryParse(item.externalIds['mal'] ?? '');
    if (direct != null && direct > 0) {
      return direct;
    }
    final match = RegExp(r'^jikan_(?:anime|manga)_(\d+)$').firstMatch(item.id);
    final parsed = match == null ? null : int.tryParse(match.group(1)!);
    return parsed != null && parsed > 0 ? parsed : null;
  }

  String _malExportStatus(MediaItem item, {required bool isAnime}) {
    switch (item.trackingStatus) {
      case TrackingStatus.watching:
        return isAnime ? 'Watching' : 'Reading';
      case TrackingStatus.reading:
        return 'Reading';
      case TrackingStatus.completed:
        return 'Completed';
      case TrackingStatus.onHold:
        return 'On-Hold';
      case TrackingStatus.dropped:
        return 'Dropped';
      case TrackingStatus.planToWatch:
        return isAnime ? 'Plan to Watch' : 'Plan to Read';
      case TrackingStatus.unknown:
        return isAnime ? 'Plan to Watch' : 'Plan to Read';
    }
  }

  String _dateText(DateTime? date) {
    if (date == null) {
      return '0000-00-00';
    }
    String two(int number) => number.toString().padLeft(2, '0');
    return '${date.year.toString().padLeft(4, '0')}-${two(date.month)}-${two(date.day)}';
  }

  int _unixSeconds(DateTime? value) =>
      value == null ? 0 : value.toUtc().millisecondsSinceEpoch ~/ 1000;
}
