import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../models/data_transfer.dart';
import '../models/media_item.dart';

class NativeBackupCodec {
  // Stable legacy discriminator: changing it would make existing backups
  // unreadable. New user-visible filenames use the Episode brand.
  static const format = 'otakulog-backup';
  static const currentSchemaVersion = 1;
  static const defaultApplicationVersion = '1.0.0+1';
  static const maxBackupBytes = 20 * 1024 * 1024;

  final String applicationVersion;
  final List<BackupMigration> migrations;

  const NativeBackupCodec({
    this.applicationVersion = defaultApplicationVersion,
    this.migrations = const [LegacyBackupV0Migration()],
  });

  ExportArtifact createArtifact(
    List<MediaItem> items, {
    required String platform,
    DateTime? now,
  }) {
    final exportedAt = (now ?? DateTime.now()).toUtc();
    final data = <String, dynamic>{
      'mediaItems': items.map((item) => item.toMap()).toList(),
      'preferences': <String, dynamic>{},
    };
    final document = <String, dynamic>{
      'format': format,
      'schemaVersion': currentSchemaVersion,
      'applicationVersion': applicationVersion,
      'exportedAt': exportedAt.toIso8601String(),
      'platform': platform,
      'data': data,
      'integrity': {
        'algorithm': 'sha256',
        'checksum': _checksum(data),
        'itemCount': items.length,
      },
    };
    final bytes = Uint8List.fromList(
      utf8.encode(const JsonEncoder.withIndent('  ').convert(document)),
    );
    return ExportArtifact(
      fileName: 'episode-backup-${fileTimestamp(exportedAt)}.json',
      mimeType: 'application/json',
      bytes: bytes,
      exportedCount: items.length,
    );
  }

  DecodedNativeBackup decode(ImportSource source) {
    if (source.bytes.isEmpty) {
      throw const DataTransferException(
        'The selected backup is empty.',
        code: 'empty_file',
      );
    }
    if (source.bytes.length > maxBackupBytes) {
      throw const DataTransferException(
        'The selected backup exceeds the 20 MB safety limit.',
        code: 'file_too_large',
      );
    }

    final String text;
    try {
      text = utf8.decode(source.bytes).replaceFirst('\uFEFF', '');
    } on FormatException {
      throw const DataTransferException(
        'The backup is not valid UTF-8.',
        code: 'invalid_encoding',
      );
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException {
      throw const DataTransferException(
        'The backup contains malformed JSON.',
        code: 'invalid_json',
      );
    }
    if (decoded is! Map) {
      throw const DataTransferException(
        'The backup root must be a JSON object.',
        code: 'invalid_root',
      );
    }

    var document = Map<String, dynamic>.from(decoded);
    final originalVersion = (document['schemaVersion'] as num?)?.toInt() ?? 0;
    if (originalVersion > currentSchemaVersion) {
      throw DataTransferException(
        'This backup uses schema $originalVersion, but this app supports up to '
        'schema $currentSchemaVersion.',
        code: 'unsupported_future_schema',
      );
    }
    document = _migrate(document, originalVersion);

    if (document['format'] != format) {
      throw const DataTransferException(
        'This file is not an Episode backup.',
        code: 'wrong_format',
      );
    }
    final data = document['data'];
    if (data is! Map) {
      throw const DataTransferException(
        'The backup data section is missing or invalid.',
        code: 'invalid_data',
      );
    }
    final dataMap = Map<String, dynamic>.from(data);
    final rawItems = dataMap['mediaItems'];
    if (rawItems is! List) {
      throw const DataTransferException(
        'The backup mediaItems section must be a list.',
        code: 'invalid_media_items',
      );
    }

    final warnings = <ImportWarning>[];
    if (originalVersion == currentSchemaVersion) {
      _verifyIntegrity(document, dataMap, rawItems.length);
    } else {
      warnings.add(
        ImportWarning(
          'migrated_schema',
          'Backup schema $originalVersion was migrated to schema '
              '$currentSchemaVersion before preview.',
        ),
      );
    }

    final items = <MediaItem>[];
    final ids = <String>{};
    for (var index = 0; index < rawItems.length; index++) {
      final raw = rawItems[index];
      if (raw is! Map) {
        throw DataTransferException(
          'Backup entry ${index + 1} is not an object.',
          code: 'invalid_entry',
        );
      }
      final map = Map<String, dynamic>.from(raw);
      final id = map['id']?.toString().trim() ?? '';
      final title = map['title']?.toString().trim() ?? '';
      if (id.isEmpty || title.isEmpty) {
        throw DataTransferException(
          'Backup entry ${index + 1} is missing an ID or title.',
          code: 'invalid_entry',
        );
      }
      if (!ids.add(id)) {
        throw DataTransferException(
          'The backup contains duplicate media ID "$id".',
          code: 'duplicate_id',
        );
      }
      items.add(MediaItem.fromMap(map));
    }

    return DecodedNativeBackup(
      items: items,
      warnings: warnings,
      exportedAt: DateTime.tryParse(document['exportedAt']?.toString() ?? ''),
      applicationVersion: document['applicationVersion']?.toString(),
    );
  }

  Map<String, dynamic> _migrate(
    Map<String, dynamic> source,
    int sourceVersion,
  ) {
    var current = sourceVersion;
    var document = source;
    while (current < currentSchemaVersion) {
      BackupMigration? migration;
      for (final candidate in migrations) {
        if (candidate.sourceVersion == current) {
          migration = candidate;
          break;
        }
      }
      if (migration == null) {
        throw DataTransferException(
          'No migration is available from backup schema $current.',
          code: 'missing_migration',
        );
      }
      document = migration.migrate(document);
      current = migration.targetVersion;
    }
    return document;
  }

  void _verifyIntegrity(
    Map<String, dynamic> document,
    Map<String, dynamic> data,
    int actualCount,
  ) {
    final integrity = document['integrity'];
    if (integrity is! Map) {
      throw const DataTransferException(
        'The backup integrity section is missing.',
        code: 'missing_integrity',
      );
    }
    final map = Map<String, dynamic>.from(integrity);
    if (map['algorithm'] != 'sha256') {
      throw const DataTransferException(
        'The backup uses an unsupported checksum algorithm.',
        code: 'unsupported_checksum',
      );
    }
    final expected = map['checksum']?.toString() ?? '';
    if (expected.isEmpty || expected != _checksum(data)) {
      throw const DataTransferException(
        'The backup checksum does not match. The file may be incomplete or '
        'corrupted.',
        code: 'checksum_mismatch',
      );
    }
    final expectedCount = (map['itemCount'] as num?)?.toInt();
    if (expectedCount == null || expectedCount != actualCount) {
      throw const DataTransferException(
        'The backup item count does not match its integrity metadata.',
        code: 'count_mismatch',
      );
    }
  }

  static String _checksum(Map<String, dynamic> data) {
    return sha256.convert(utf8.encode(jsonEncode(data))).toString();
  }
}

class DecodedNativeBackup {
  final List<MediaItem> items;
  final List<ImportWarning> warnings;
  final DateTime? exportedAt;
  final String? applicationVersion;

  const DecodedNativeBackup({
    required this.items,
    required this.warnings,
    this.exportedAt,
    this.applicationVersion,
  });
}

abstract interface class BackupMigration {
  int get sourceVersion;
  int get targetVersion;
  Map<String, dynamic> migrate(Map<String, dynamic> input);
}

class LegacyBackupV0Migration implements BackupMigration {
  const LegacyBackupV0Migration();

  @override
  int get sourceVersion => 0;

  @override
  int get targetVersion => 1;

  @override
  Map<String, dynamic> migrate(Map<String, dynamic> input) {
    final rawData = input['data'];
    final data = rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : <String, dynamic>{};
    final mediaItems =
        data['mediaItems'] ?? input['mediaItems'] ?? input['items'];
    if (mediaItems is! List) {
      throw const DataTransferException(
        'Legacy backup does not contain a media item list.',
        code: 'invalid_legacy_backup',
      );
    }
    return {
      'format': NativeBackupCodec.format,
      'schemaVersion': targetVersion,
      'applicationVersion': input['applicationVersion'] ?? 'unknown',
      'exportedAt': input['exportedAt'] ??
          DateTime.fromMillisecondsSinceEpoch(0).toUtc().toIso8601String(),
      'platform': input['platform'] ?? 'unknown',
      'data': {
        'mediaItems': mediaItems,
        'preferences': data['preferences'] ?? <String, dynamic>{},
      },
    };
  }
}

class NativeBackupImportProvider implements ImportProvider {
  static const backgroundParseThresholdBytes = 128 * 1024;

  final NativeBackupCodec codec;

  const NativeBackupImportProvider({this.codec = const NativeBackupCodec()});

  @override
  String get id => 'episode-native';

  @override
  String get displayName => 'Episode backup';

  @override
  List<String> get supportedExtensions => const ['json'];

  @override
  bool canHandle(ImportSource source) {
    if (source.bytes.isEmpty) {
      return false;
    }
    final prefixLength = source.bytes.length.clamp(0, 512);
    final prefix = utf8.decode(
      source.bytes.sublist(0, prefixLength),
      allowMalformed: true,
    );
    return prefix.contains('"${NativeBackupCodec.format}"') ||
        (source.extension == 'json' && prefix.trimLeft().startsWith('{'));
  }

  @override
  Future<ImportInspectionResult> inspect(ImportSource source) async {
    final decoded = source.bytes.length >= backgroundParseThresholdBytes
        ? await compute(
            _decodeNativeBackup,
            _NativeDecodeRequest(source: source, codec: codec),
          )
        : codec.decode(source);
    return ImportInspectionResult(
      providerId: id,
      providerName: displayName,
      sourceType: ImportSourceType.nativeBackup,
      fileName: source.fileName,
      entries: decoded.items
          .map(ImportedMediaEntry.fromMediaItem)
          .toList(growable: false),
      warnings: decoded.warnings,
    );
  }
}

class _NativeDecodeRequest {
  final ImportSource source;
  final NativeBackupCodec codec;

  const _NativeDecodeRequest({required this.source, required this.codec});
}

DecodedNativeBackup _decodeNativeBackup(_NativeDecodeRequest request) {
  return request.codec.decode(request.source);
}

class NativeBackupExportProvider implements ExportProvider {
  final NativeBackupCodec codec;
  final String platform;

  const NativeBackupExportProvider({
    this.codec = const NativeBackupCodec(),
    required this.platform,
  });

  @override
  String get id => 'episode-native';

  @override
  String get displayName => 'Episode backup';

  @override
  Future<ExportArtifact> export(
    List<MediaItem> items, {
    MediaType? mediaType,
  }) async {
    return codec.createArtifact(items, platform: platform);
  }
}

String fileTimestamp(DateTime value) {
  final utc = value.toUtc();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${utc.year.toString().padLeft(4, '0')}-'
      '${two(utc.month)}-${two(utc.day)}T${two(utc.hour)}'
      '${two(utc.minute)}${two(utc.second)}Z';
}
