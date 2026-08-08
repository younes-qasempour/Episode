import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:episode/models/media_item.dart';
import 'package:episode/screens/manual_media_screen.dart';

void main() {
  testWidgets('valid manual media can be submitted', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    MediaItem? savedItem;

    await tester.pumpWidget(
      MaterialApp(home: ManualMediaScreen(onSave: (item) => savedItem = item)),
    );

    await tester.enterText(
      find.byKey(const Key('manual-title-field')),
      'My Missing Anime',
    );
    final saveButton = find.byKey(const Key('save-manual-media-button'));
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pump();

    expect(savedItem, isNotNull);
    expect(savedItem!.title, 'My Missing Anime');
    expect(savedItem!.isManual, isTrue);
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    expect(uuidRegex.hasMatch(savedItem!.id), isTrue);
    expect(savedItem!.totalCount, isNull);
  });

  testWidgets('manual form shows required-title validation', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: ManualMediaScreen()));

    final saveButton = find.byKey(const Key('save-manual-media-button'));
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pump();

    expect(find.text('Title is required.'), findsOneWidget);
  });

  testWidgets('movie form hides episodic progress controls', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: ManualMediaScreen()));

    await tester.tap(find.byKey(const Key('manual-media-type-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Movie').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('manual-progress-field')), findsNothing);
    expect(find.byKey(const Key('manual-known-total-switch')), findsNothing);
  });

  testWidgets('season can be added to a manual series', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: ManualMediaScreen()));

    await tester.tap(find.text('By season'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('manual-add-season-button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('season-progress-field')), '4');
    await tester.tap(find.byKey(const Key('save-season-button')));
    await tester.pumpAndSettle();

    expect(find.text('Season 1'), findsOneWidget);
    expect(find.textContaining('4 / ? Ep'), findsOneWidget);
  });
}
