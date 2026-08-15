import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:episode/models/media_item.dart';
import 'package:episode/models/user_profile_data.dart';
import 'package:episode/screens/media_detail_screen.dart';
import 'package:episode/theme/app_theme.dart';
import 'package:episode/widgets/media_card.dart';
import 'package:episode/widgets/profile_stats_dashboard.dart';

void main() {
  group('QA Audit Automated Exploration Tests', () {
    const sampleMediaItem = MediaItem(
      id: 'test_item_1',
      title: 'Attack on Titan: The Final Season Part 3 Very Long Title That Wraps Around',
      coverUrl: '',
      currentProgress: 12,
      totalCount: 24,
      mediaType: 'anime',
      status: 'Watching',
      releaseStatus: ReleaseStatus.finished,
      progressMode: ProgressMode.flat,
      rating: 9.5,
      isFavorite: true,
    );

    testWidgets('MediaCard renders with short title without overflow',
        (tester) async {
      final shortTitleItem = sampleMediaItem.copyWith(title: 'Naruto');
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: MediaCard(
              item: shortTitleItem,
              onTap: () {},
              onIncrementProgress: () {},
              onToggleFavorite: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('MediaCard renders without overflow when title wraps 2 lines',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: MediaCard(
              item: sampleMediaItem,
              onTap: () {},
              onIncrementProgress: () {},
              onToggleFavorite: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('MediaDetailScreen renders in expanded mode with two panes on 1280px width',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

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
      expect(find.byKey(const Key('expanded-media-detail-layout')), findsOneWidget);
    });

    testWidgets('ProfileStatsDashboard renders analytics cards and bio',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: SingleChildScrollView(
              child: ProfileStatsDashboard(
                mediaItems: [sampleMediaItem],
                userProfile: UserProfileData(
                  displayName: 'Otaku Tester',
                  bio: 'Testing all features',
                  favoriteQuote: 'Plus Ultra!',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Otaku Tester'), findsOneWidget);
      expect(find.text('Episodes Watched'), findsOneWidget);
    });
  });
}
