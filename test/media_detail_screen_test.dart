import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otaku_log/models/media_item.dart';
import 'package:otaku_log/screens/media_detail_screen.dart';

void main() {
  testWidgets('MediaDetailScreen renders title, status, and allows save action', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const testItem = MediaItem(
      id: 'detail_test_1',
      title: 'Fullmetal Alchemist',
      coverUrl: 'https://example.com/fma.jpg',
      currentProgress: 10,
      totalCount: 64,
      mediaType: 'anime',
      status: 'Watching',
      synopsis: 'Two brothers search for Philosopher Stone.',
      rating: 9.5,
    );

    MediaItem? savedItem;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaDetailScreen(
          item: testItem,
          onSave: (item) {
            savedItem = item;
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Fullmetal Alchemist'), findsNWidgets(2)); // AppBar & Header
    expect(find.text('Watching'), findsWidgets);
    expect(find.text('Synopsis'), findsOneWidget);

    final saveButton = find.text('Save Changes');
    expect(saveButton, findsOneWidget);

    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(savedItem, isNotNull);
    expect(savedItem!.title, equals('Fullmetal Alchemist'));
  });

  testWidgets('MediaDetailScreen triggers onDelete when delete confirmed', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const testItem = MediaItem(
      id: 'detail_test_2',
      title: 'Item To Delete',
      coverUrl: 'https://example.com/cover.jpg',
      currentProgress: 0,
      totalCount: 10,
      mediaType: 'series',
      status: 'Plan to Watch',
    );

    String? deletedId;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaDetailScreen(
          item: testItem,
          onDelete: (id) {
            deletedId = id;
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    final deleteIcon = find.byIcon(Icons.delete_outline_rounded);
    expect(deleteIcon, findsOneWidget);
    await tester.tap(deleteIcon);
    await tester.pumpAndSettle();

    expect(find.text('Delete Media'), findsOneWidget);
    final confirmDeleteButton = find.text('Delete');
    await tester.tap(confirmDeleteButton);
    await tester.pumpAndSettle();

    expect(deletedId, equals('detail_test_2'));
  });
}
