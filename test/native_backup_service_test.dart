import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:episode/models/data_transfer.dart';
import 'package:episode/models/media_item.dart';
import 'package:episode/services/native_backup_service.dart';

void main() {
  const codec = NativeBackupCodec(applicationVersion: 'test+1');
  const richItem = MediaItem(
    id: 'jikan_anime_5114',
    title: '鋼の錬金術師 — کیمیاگر',
    coverUrl: 'https://example.com/cover.jpg',
    currentProgress: 64,
    totalCount: 64,
    mediaType: 'anime',
    status: 'Completed',
    releaseStatus: ReleaseStatus.finished,
    synopsis: 'Unicode synopsis',
    rating: 10,
    externalIds: {'mal': '5114', 'jikan': '5114'},
    notes: 'Private note\nwith another line',
    tags: ['favorite', 'classic'],
    repeatCount: 2,
    isFavorite: true,
    customMetadata: {'source': 'fixture'},
  );

  test('native schema v1 round-trips all current MediaItem fields', () {
    final artifact = codec.createArtifact(
      [richItem],
      platform: 'test',
      now: DateTime.utc(2026, 8, 1, 9, 30),
    );
    final decoded = codec.decode(
      ImportSource(fileName: artifact.fileName, bytes: artifact.bytes),
    );

    expect(decoded.items, hasLength(1));
    final restored = decoded.items.single;
    expect(restored.title, richItem.title);
    expect(restored.externalIds, richItem.externalIds);
    expect(restored.notes, richItem.notes);
    expect(restored.tags, richItem.tags);
    expect(restored.repeatCount, 2);
    expect(restored.isFavorite, isTrue);
    expect(restored.customMetadata['source'], 'fixture');
    expect(artifact.fileName, 'otakulog-backup-2026-08-01T093000Z.json');
  });

  test('checksum detects accidental backup corruption', () {
    final artifact = codec.createArtifact([richItem], platform: 'test');
    final map = jsonDecode(utf8.decode(artifact.bytes)) as Map<String, dynamic>;
    final data = map['data'] as Map<String, dynamic>;
    final items = data['mediaItems'] as List<dynamic>;
    (items.single as Map<String, dynamic>)['title'] = 'Tampered';
    final source = ImportSource(
      fileName: 'tampered.json',
      bytes: Uint8List.fromList(utf8.encode(jsonEncode(map))),
    );

    expect(
      () => codec.decode(source),
      throwsA(
        isA<DataTransferException>().having(
          (error) => error.code,
          'code',
          'checksum_mismatch',
        ),
      ),
    );
  });

  test('legacy schema zero migrates before mapping', () {
    final source = ImportSource(
      fileName: 'legacy.json',
      bytes: Uint8List.fromList(
        utf8.encode(
          jsonEncode({
            'schemaVersion': 0,
            'items': [richItem.toMap()],
          }),
        ),
      ),
    );

    final decoded = codec.decode(source);

    expect(decoded.items.single.id, richItem.id);
    expect(decoded.warnings.single.code, 'migrated_schema');
  });

  test('unsupported future schema is rejected before data changes', () {
    final source = ImportSource(
      fileName: 'future.json',
      bytes: Uint8List.fromList(
        utf8.encode(
          jsonEncode({
            'format': NativeBackupCodec.format,
            'schemaVersion': NativeBackupCodec.currentSchemaVersion + 1,
          }),
        ),
      ),
    );

    expect(
      () => codec.decode(source),
      throwsA(
        isA<DataTransferException>().having(
          (error) => error.code,
          'code',
          'unsupported_future_schema',
        ),
      ),
    );
  });

  test('structurally invalid native entry is rejected', () {
    final artifact = codec.createArtifact([richItem], platform: 'test');
    final map = jsonDecode(utf8.decode(artifact.bytes)) as Map<String, dynamic>;
    final data = map['data'] as Map<String, dynamic>;
    final items = data['mediaItems'] as List<dynamic>;
    (items.single as Map<String, dynamic>)['id'] = '';
    // Re-encode as schema 0 to exercise structural validation after migration.
    final source = ImportSource(
      fileName: 'invalid-entry.json',
      bytes: Uint8List.fromList(
        utf8.encode(jsonEncode({'schemaVersion': 0, 'items': items})),
      ),
    );

    expect(
      () => codec.decode(source),
      throwsA(
        isA<DataTransferException>().having(
          (error) => error.code,
          'code',
          'invalid_entry',
        ),
      ),
    );
  });

  test('large native backup is inspected through the background path',
      () async {
    final items = List.generate(
      180,
      (index) => richItem.copyWith(
        id: 'large-$index',
        title: 'Large backup entry $index',
        notes: List.filled(900, 'x').join(),
      ),
    );
    final artifact = codec.createArtifact(items, platform: 'test');
    expect(
      artifact.bytes.length,
      greaterThanOrEqualTo(
        NativeBackupImportProvider.backgroundParseThresholdBytes,
      ),
    );

    final inspection = await const NativeBackupImportProvider(
      codec: codec,
    ).inspect(
      ImportSource(fileName: artifact.fileName, bytes: artifact.bytes),
    );

    expect(inspection.entries, hasLength(items.length));
    expect(inspection.sourceType, ImportSourceType.nativeBackup);
  });
}
