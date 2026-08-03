import 'package:flutter_test/flutter_test.dart';
import 'package:otaku_log/models/data_transfer.dart';
import 'package:otaku_log/models/media_item.dart';
import 'package:otaku_log/services/import_planner.dart';

void main() {
  const planner = ImportPlanner();
  const local = MediaItem(
    id: 'jikan_anime_5114',
    title: 'Fullmetal Alchemist: Brotherhood',
    coverUrl: 'local-cover',
    currentProgress: 40,
    totalCount: 64,
    mediaType: 'anime',
    status: 'Watching',
    rating: 8,
    externalIds: {'mal': '5114'},
    notes: 'Keep my local note',
    tags: ['local'],
  );

  ImportedMediaEntry imported({
    String id = '5114',
    String title = 'Fullmetal Alchemist Brotherhood',
    int progress = 50,
  }) {
    return ImportedMediaEntry(
      mediaType: MediaType.anime,
      sourceProvider: 'myanimelist',
      sourceId: id,
      externalIds: {'mal': id},
      title: title,
      status: 'Watching',
      progress: progress,
      totalUnits: 64,
      score: 9,
      notes: 'Imported note',
      tags: const ['imported'],
    );
  }

  ImportInspectionResult inspection(ImportedMediaEntry entry) {
    return ImportInspectionResult(
      providerId: 'myanimelist-xml',
      providerName: 'MyAnimeList XML',
      sourceType: ImportSourceType.malAnime,
      fileName: 'anime.xml',
      entries: [entry],
    );
  }

  test('exact external ID is deterministic and outranks title differences', () {
    final preview = planner.buildPreview(
      inspection(imported(title: 'Completely Different Provider Title')),
      [local],
      const ImportOptions(),
    );

    expect(preview.candidates.single.local?.id, local.id);
    expect(preview.candidates.single.action, ImportAction.update);
    expect(preview.candidates.single.matchReason, 'Exact external provider ID');
  });

  test('normalized title matching handles punctuation and repeated spacing',
      () {
    final preview = planner.buildPreview(
      inspection(
          imported(id: '999', title: '  Fullmetal—Alchemist:  Brotherhood ')),
      [local],
      const ImportOptions(),
    );

    expect(preview.candidates.single.local?.id, local.id);
    expect(preview.candidates.single.isConfidentMatch, isTrue);
    expect(normalizeTitle('A—B   C'), 'a b c');
  });

  test('similar but non-exact titles are surfaced as uncertain conflicts', () {
    final preview = planner.buildPreview(
      inspection(imported(
        id: '999',
        title: 'Fullmetal Alchemist Brotherhoodd',
      )),
      [local],
      const ImportOptions(),
    );

    expect(preview.candidates.single.action, ImportAction.conflict);
    expect(preview.candidates.single.isConfidentMatch, isFalse);
  });

  test('pathological fuzzy buckets fail safe without unbounded comparisons',
      () {
    final manyLocalItems = List.generate(
      251,
      (index) => local.copyWith(
        id: 'local-$index',
        title: 'Full title candidate $index',
        externalIds: const {},
      ),
    );

    final preview = planner.buildPreview(
      inspection(imported(id: '999', title: 'Full title candidate unknown')),
      manyLocalItems,
      const ImportOptions(),
    );

    expect(preview.candidates.single.action, ImportAction.conflict);
    expect(
      preview.candidates.single.matchReason,
      contains('Too many similar-title candidates'),
    );
  });

  test('add-only strategy skips confident existing entries', () {
    final preview = planner.buildPreview(
      inspection(imported()),
      [local],
      const ImportOptions(strategy: ImportStrategy.addOnly),
    );

    expect(preview.candidates.single.action, ImportAction.skip);
  });

  test('safe merge never reduces progress or overwrites notes', () {
    final merged = planner.resolveConflict(
      local,
      imported(progress: 50),
      ConflictPolicy.mergeSafe,
    );
    final lower = planner.resolveConflict(
      local,
      imported(progress: 2),
      ConflictPolicy.mergeSafe,
    );

    expect(merged.currentProgress, 50);
    expect(lower.currentProgress, 40);
    expect(merged.notes, local.notes);
    expect(merged.tags, containsAll(['local', 'imported']));
    expect(merged.rating, 8);
    expect(merged.externalIds['mal'], '5114');
  });

  test('full restore emits the imported library without local leftovers', () {
    final preview = planner.buildPreview(
      inspection(imported(id: '999', title: 'Restored Item')),
      [local],
      const ImportOptions(strategy: ImportStrategy.fullRestore),
    );

    final applied = planner.apply([local], preview);

    expect(applied.library, hasLength(1));
    expect(applied.library.single.title, 'Restored Item');
    expect(applied.library.single.externalIds['mal'], '999');
  });
}
