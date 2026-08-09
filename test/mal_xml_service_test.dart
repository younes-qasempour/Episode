import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:episode/models/data_transfer.dart';
import 'package:episode/models/media_item.dart';
import 'package:episode/services/mal_xml_service.dart';
import 'package:xml/xml.dart';

void main() {
  const importer = MalXmlImportProvider();

  Future<ImportSource> fixture(String name) async {
    return ImportSource(
      fileName: name,
      bytes: await File('test/fixtures/$name').readAsBytes(),
    );
  }

  test('parses official-style anime XML into canonical entries', () async {
    final result = await importer.inspect(await fixture('mal_anime_valid.xml'));

    expect(result.sourceType, ImportSourceType.malAnime);
    expect(result.entries, hasLength(2));
    final first = result.entries.first;
    expect(first.externalIds['mal'], '5114');
    expect(first.status, 'Completed');
    expect(first.progress, 64);
    expect(first.totalUnits, 64);
    expect(first.score, 10);
    expect(first.notes, contains('Second line'));
    expect(first.tags, containsAll(['classic', 'favorite']));
    expect(first.repeatCount, 1);
    expect(result.entries.last.title, contains('シュタインズ'));
    expect(result.entries.last.notes, 'یادداشت فارسی');
  });

  test('parses manga chapters, volumes, dates, and reread metadata', () async {
    final result = await importer.inspect(await fixture('mal_manga_valid.xml'));
    final entry = result.entries.single;

    expect(result.sourceType, ImportSourceType.malManga);
    expect(entry.status, 'Reading');
    expect(entry.progress, 375);
    expect(entry.totalUnits, isNull);
    expect(entry.sourceMetadata['volumesRead'], 41);
    expect(entry.sourceMetadata['totalVolumes'], 42);
    expect(entry.sourceMetadata['isRepeating'], isTrue);
    expect(entry.startedAt, DateTime(2020, 5, 1));
  });

  test('supports gzip-compressed MAL XML', () async {
    final plain = await File('test/fixtures/mal_anime_valid.xml').readAsBytes();
    final source = ImportSource(
      fileName: 'anime-list.xml.gz',
      bytes: const GZipEncoder().encodeBytes(plain),
    );

    final result = await importer.inspect(source);

    expect(result.entries, hasLength(2));
    expect(result.sourceType, ImportSourceType.malAnime);
  });

  test('empty official export remains a valid zero-entry preview', () async {
    final result = await importer.inspect(await fixture('mal_empty.xml'));

    expect(result.sourceType, ImportSourceType.malAnime);
    expect(result.entries, isEmpty);
  });

  test('malformed and entity-bearing XML are rejected safely', () async {
    expect(
      () async => importer.inspect(await fixture('mal_invalid.xml')),
      throwsA(isA<DataTransferException>()),
    );
    final unsafe = ImportSource(
      fileName: 'unsafe.xml',
      bytes: Uint8List.fromList(
        '<!DOCTYPE foo [<!ENTITY xxe SYSTEM "file:///etc/passwd">]>'
                '<myanimelist><myinfo><user_export_type>1</user_export_type>'
                '</myinfo></myanimelist>'
            .codeUnits,
      ),
    );

    expect(
      () => importer.inspect(unsafe),
      throwsA(
        isA<DataTransferException>().having(
          (error) => error.code,
          'code',
          'unsafe_xml',
        ),
      ),
    );
  });

  test('unknown statuses are reported and missing IDs are skipped', () async {
    final unknown = await importer.inspect(
      await fixture('mal_unknown_status.xml'),
    );
    final missing = await importer.inspect(await fixture('mal_missing_id.xml'));

    expect(unknown.entries.single.status, 'Unknown');
    expect(unknown.warnings.any((warning) => warning.code == 'unknown_status'),
        isTrue);
    expect(missing.entries, isEmpty);
    expect(missing.warnings.any((warning) => warning.code == 'invalid_entry'),
        isTrue);
  });

  test('MAL export escapes Unicode and reports entries without MAL IDs',
      () async {
    const exporter = MalXmlExportProvider();
    final representable = MediaItem(
      id: 'jikan_anime_5114',
      title: '鋼の錬金術師 & Brotherhood',
      coverUrl: '',
      currentProgress: 64,
      totalCount: 64,
      mediaType: 'anime',
      status: 'Completed',
      rating: 9.6,
      notes: 'Great <ending> & finale',
      tags: ['favorite', 'classic'],
      externalIds: {'mal': '5114'},
      startedAt: DateTime(2020, 5, 1),
      completedAt: DateTime(2020, 5, 2),
    );
    const unsupported = MediaItem(
      id: 'manual_no_provider',
      title: 'No Provider ID',
      coverUrl: '',
      currentProgress: 0,
      totalCount: null,
      mediaType: 'anime',
      status: 'Plan to Watch',
      isManual: true,
    );

    final artifact = await exporter.export(
      [representable, unsupported],
      mediaType: MediaType.anime,
    );
    final document = XmlDocument.parse(utf8.decode(artifact.bytes));

    expect(document.rootElement.name.local, 'myanimelist');
    expect(document.findAllElements('anime'), hasLength(1));
    expect(document.findAllElements('series_title').single.innerText,
        representable.title);
    expect(document.findAllElements('my_score').single.innerText, '10');
    expect(document.findAllElements('my_comments').single.innerText,
        representable.notes);
    expect(document.findAllElements('my_start_date').single.innerText,
        '2020-05-01');
    expect(document.findAllElements('my_finish_date').single.innerText,
        '2020-05-02');
    expect(artifact.exportedCount, 1);
    expect(artifact.skippedCount, 1);
    expect(artifact.warnings.single, contains('No Provider ID'));
  });
}
