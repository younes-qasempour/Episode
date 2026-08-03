import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otaku_log/models/data_transfer.dart';
import 'package:otaku_log/models/media_item.dart';
import 'package:otaku_log/repositories/local_storage_repository.dart';
import 'package:otaku_log/screens/data_management_screen.dart';
import 'package:otaku_log/screens/import_preview_screen.dart';
import 'package:otaku_log/services/file_transfer_platform.dart';
import 'package:otaku_log/services/file_transfer_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeFileTransfer implements PlatformFileTransfer {
  final List<ExportArtifact> saved = [];

  @override
  String get platformLabel => 'test';

  @override
  Future<ImportSource?> pickFile({
    required List<String> allowedExtensions,
    required int maxBytes,
  }) async {
    return null;
  }

  @override
  Future<bool> saveArtifact(ExportArtifact artifact) async {
    saved.add(artifact);
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('data management screen exposes core import and backup actions', (
    tester,
  ) async {
    final files = _FakeFileTransfer();
    await tester.pumpWidget(
      MaterialApp(
        home: DataManagementScreen(
          mediaItems: const [],
          storageRepository: const LocalStorageRepository(),
          onLibraryChanged: (_) {},
          fileTransferService: FileTransferService(delegate: files),
        ),
      ),
    );

    expect(find.text('Data, Backup & Transfer'), findsOneWidget);
    expect(find.byKey(const Key('import-mal-action')), findsOneWidget);
    expect(find.byKey(const Key('import-file-action')), findsOneWidget);
    expect(find.byKey(const Key('restore-backup-action')), findsOneWidget);
    expect(find.byKey(const Key('create-backup-action')), findsOneWidget);
  });

  testWidgets('cancelled picker leaves the screen and library unchanged', (
    tester,
  ) async {
    final files = _FakeFileTransfer();
    var callbackCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: DataManagementScreen(
          mediaItems: const [],
          storageRepository: const LocalStorageRepository(),
          onLibraryChanged: (_) => callbackCount++,
          fileTransferService: FileTransferService(delegate: files),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('import-mal-action')));
    await tester.pumpAndSettle();

    expect(callbackCount, 0);
    expect(find.text('Data, Backup & Transfer'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('preview shows conflict warning and entry action',
      (tester) async {
    const imported = ImportedMediaEntry(
      mediaType: MediaType.anime,
      sourceProvider: 'myanimelist',
      sourceId: '1',
      title: 'Possible Match',
      status: 'Watching',
    );
    const inspection = ImportInspectionResult(
      providerId: 'fixture',
      providerName: 'Fixture',
      sourceType: ImportSourceType.malAnime,
      fileName: 'fixture.xml',
      entries: [imported],
    );
    const candidate = ImportCandidate(
      imported: imported,
      local: null,
      action: ImportAction.conflict,
      matchReason: 'Similar title requires confirmation',
      isConfidentMatch: false,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ImportPreviewScreen(
          inspection: inspection,
          buildPreview: (options) => ImportPreview(
            inspection: inspection,
            options: options,
            candidates: const [candidate],
            warnings: const [],
          ),
        ),
      ),
    );

    expect(find.text('Review import'), findsOneWidget);
    expect(find.textContaining('Uncertain matches'), findsOneWidget);
    expect(find.byKey(const Key('confirm-import-button')), findsOneWidget);
  });

  testWidgets('empty native backup can proceed only as an explicit restore', (
    tester,
  ) async {
    const inspection = ImportInspectionResult(
      providerId: 'otakulog-native',
      providerName: 'OtakuLog backup',
      sourceType: ImportSourceType.nativeBackup,
      fileName: 'empty.json',
      entries: [],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ImportPreviewScreen(
          inspection: inspection,
          restoreFlow: true,
          buildPreview: (options) => ImportPreview(
            inspection: inspection,
            options: options,
            candidates: const [],
            warnings: const [],
          ),
        ),
      ),
    );

    final button = tester.widget<FilledButton>(
      find.byKey(const Key('confirm-import-button')),
    );
    expect(button.onPressed, isNotNull);
    expect(find.text('Create backup & restore'), findsOneWidget);
  });
}
