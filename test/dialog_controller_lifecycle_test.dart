import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:episode/models/media_item.dart';
import 'package:episode/models/user_profile_data.dart';
import 'package:episode/screens/media_detail_screen.dart';
import 'package:episode/theme/app_theme.dart';
import 'package:episode/widgets/profile_stats_dashboard.dart';

void main() {
  group('BUG-004: Dialog Controller Lifecycle & Memory Leak Tests', () {
    const sampleProfile = UserProfileData(
      displayName: 'Shinobi',
      bio: 'Dattebayo!',
      favoriteQuote: 'Never give up',
      avatarColorIndex: 2,
    );

    const sampleMediaItem = MediaItem(
      id: 'test_item_1',
      title: 'Death Note',
      coverUrl: 'https://example.com/cover.jpg',
      currentProgress: 10,
      totalCount: 37,
      mediaType: 'anime',
      status: 'Watching',
      releaseStatus: ReleaseStatus.finished,
      progressMode: ProgressMode.flat,
    );

    testWidgets('ProfileStatsDashboard edit profile dialog opens, updates, and disposes cleanly', (tester) async {
      UserProfileData? updatedProfile;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProfileStatsDashboard(
                mediaItems: const [sampleMediaItem],
                userProfile: sampleProfile,
                onProfileUpdated: (p) => updatedProfile = p,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open Edit dialog by tapping edit bio icon
      final editIcon = find.byIcon(Icons.edit_note_rounded);
      expect(editIcon, findsOneWidget);
      await tester.tap(editIcon);
      await tester.pumpAndSettle();

      // Find Display Name field and change it
      final nameField = find.widgetWithText(TextField, 'Shinobi');
      expect(nameField, findsOneWidget);
      await tester.enterText(nameField, 'Hokage Naruto');
      await tester.pumpAndSettle();

      // Save
      final saveBtn = find.text('Save Profile');
      expect(saveBtn, findsOneWidget);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(updatedProfile, isNotNull);
      expect(updatedProfile!.displayName, 'Hokage Naruto');
      expect(tester.takeException(), isNull);
    });

    testWidgets('MediaDetailScreen cover URL dialog opens, edits, and disposes cleanly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MediaDetailScreen(
            item: sampleMediaItem,
            onSave: (_) {},
            onDelete: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Edit Cover URL button
      final editCoverBtn = find.byKey(const Key('detail-edit-cover-button'));
      expect(editCoverBtn, findsOneWidget);
      await tester.tap(editCoverBtn);
      await tester.pumpAndSettle();

      // Find textfield by key
      final coverField = find.byKey(const Key('detail-cover-url-field'));
      expect(coverField, findsOneWidget);
      await tester.enterText(coverField, 'https://example.com/new_cover.jpg');
      await tester.pumpAndSettle();

      // Tap Apply
      final applyBtn = find.byKey(const Key('detail-save-cover-url-button'));
      expect(applyBtn, findsOneWidget);
      await tester.tap(applyBtn);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
