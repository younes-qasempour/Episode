import 'package:episode/models/media_item.dart';
import 'package:episode/models/user_profile_data.dart';
import 'package:episode/widgets/donut_chart.dart';
import 'package:episode/widgets/profile_stats_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProfileStatsDashboard Widget', () {
    testWidgets('renders milestones, mean score, and donut chart',
        (WidgetTester tester) async {
      final items = <MediaItem>[
        const MediaItem(
          id: '1',
          title: 'Attack on Titan',
          coverUrl: '',
          currentProgress: 25,
          totalCount: 25,
          mediaType: 'anime',
          status: 'Watching',
          rating: 9.0,
          tags: ['Action', 'Fantasy'],
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProfileStatsDashboard(
                mediaItems: items,
                userProfile: const UserProfileData(
                  displayName: 'Test Otaku',
                  bio: 'Testing profile dashboard',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Otaku'), findsOneWidget);
      expect(find.text('Testing profile dashboard'), findsOneWidget);
      expect(find.text('Episodes Watched'), findsOneWidget);
      expect(find.text('Chapters Read'), findsOneWidget);
      expect(find.text('Mean Score'), findsOneWidget);
      expect(find.text('Library Distribution'), findsOneWidget);
      expect(find.byType(DonutChart), findsOneWidget);
    });

    testWidgets('toggles distribution chart between Type and Status modes',
        (WidgetTester tester) async {
      final items = <MediaItem>[
        const MediaItem(
          id: '1',
          title: 'Monster',
          coverUrl: '',
          currentProgress: 74,
          totalCount: 74,
          mediaType: 'anime',
          status: 'Completed',
          rating: 10.0,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProfileStatsDashboard(
                mediaItems: items,
                userProfile: const UserProfileData(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Type'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);

      await tester.ensureVisible(find.text('Status'));
      await tester.tap(find.text('Status'));
      await tester.pumpAndSettle();

      expect(find.byType(DonutChart), findsOneWidget);
    });
  });
}
