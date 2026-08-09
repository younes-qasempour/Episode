import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:episode/models/media_item.dart';
import 'package:episode/services/csv_export_service.dart';

void main() {
  test('CSV export follows RFC-style escaping and preserves Unicode', () async {
    const item = MediaItem(
      id: 'csv-1',
      title: 'عنوان، 日本語, "quoted"',
      coverUrl: '',
      currentProgress: 12,
      totalCount: null,
      mediaType: 'manga',
      status: 'Reading',
      notes: 'Line one\nLine two, with comma and "quote"',
      tags: ['فارسی', '日本語'],
      externalIds: {'mal': '2'},
    );

    final artifact = await const CsvExportProvider().export([item]);
    final csv = utf8.decode(artifact.bytes);

    expect(artifact.bytes.take(3), [0xEF, 0xBB, 0xBF]);
    expect(csv.startsWith('id,title,'), isTrue);
    expect(csv, contains('"عنوان، 日本語, ""quoted"""'));
    expect(csv, contains('"Line one\nLine two, with comma and ""quote"""'));
    expect(csv, contains('فارسی'));
    expect(csv, contains('日本語'));
    expect(artifact.exportedCount, 1);
  });

  test('CSV can filter a media category without changing source order',
      () async {
    const anime = MediaItem(
      id: 'anime',
      title: 'Anime',
      coverUrl: '',
      currentProgress: 1,
      totalCount: 12,
      mediaType: 'anime',
      status: 'Watching',
    );
    const manga = MediaItem(
      id: 'manga',
      title: 'Manga',
      coverUrl: '',
      currentProgress: 2,
      totalCount: 20,
      mediaType: 'manga',
      status: 'Reading',
    );

    final artifact = await const CsvExportProvider().export(
      [anime, manga],
      mediaType: MediaType.manga,
    );
    final csv = utf8.decode(artifact.bytes);

    expect(csv, contains('Manga'));
    expect(csv, isNot(contains('Anime')));
    expect(artifact.exportedCount, 1);
  });
}
