import 'package:episode/layout/responsive_layout.dart';
import 'package:episode/main.dart';
import 'package:episode/models/media_item.dart';
import 'package:episode/models/search_result.dart';
import 'package:episode/repositories/search_repository.dart';
import 'package:episode/screens/manual_media_screen.dart';
import 'package:episode/screens/media_detail_screen.dart';
import 'package:episode/screens/search_tab.dart';
import 'package:episode/services/api_service.dart';
import 'package:episode/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ResponsiveTestApiService extends ApiService {
  final List<MediaItem> items;

  _ResponsiveTestApiService(this.items);

  @override
  Future<SearchResult<List<MediaItem>>> searchMedia(
    String query, {
    String category = 'All',
  }) async {
    return SearchSuccess(items);
  }
}

void main() {
  test('layout classes use centralized intent breakpoints', () {
    expect(
      ResponsiveLayoutInfo.fromWidth(599).breakpoint,
      LayoutBreakpoint.compact,
    );
    expect(
      ResponsiveLayoutInfo.fromWidth(600).breakpoint,
      LayoutBreakpoint.medium,
    );
    expect(
      ResponsiveLayoutInfo.fromWidth(1024).breakpoint,
      LayoutBreakpoint.expanded,
    );
    expect(
      ResponsiveLayoutInfo.fromWidth(1440).breakpoint,
      LayoutBreakpoint.large,
    );
  });

  test('navigation rail selection uses the Episode indigo accent', () {
    for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
      expect(theme.navigationRailTheme.indicatorColor, AppTheme.primaryIndigo);
      expect(theme.navigationRailTheme.selectedIconTheme?.color, Colors.white);
    }
  });

  testWidgets('primary navigation adapts live without restarting the app', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'episode_media_items': '[]'});
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const EpisodeApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('compact-bottom-navigation')), findsOneWidget);
    expect(find.byKey(const Key('adaptive-navigation-rail')), findsNothing);

    tester.view.physicalSize = const Size(1280, 800);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('compact-bottom-navigation')), findsNothing);
    expect(find.byKey(const Key('adaptive-navigation-rail')), findsOneWidget);
    expect(
      tester
          .widget<NavigationRail>(
            find.byKey(const Key('adaptive-navigation-rail')),
          )
          .extended,
      isTrue,
    );
  });

  testWidgets('Explore grid adds columns while keeping compact cards dense', (
    tester,
  ) async {
    final items = List.generate(
      12,
      (index) => MediaItem(
        id: 'responsive_$index',
        title: 'Media $index',
        coverUrl: '',
        currentProgress: 0,
        totalCount: 12,
        mediaType: 'anime',
        status: 'Plan to Watch',
      ),
    );
    final repository = SearchRepository(
      apiService: _ResponsiveTestApiService(items),
    );
    const viewports = <Size>[
      Size(360, 800),
      Size(390, 844),
      Size(600, 900),
      Size(768, 1024),
      Size(1024, 768),
      Size(1280, 720),
      Size(1366, 768),
      Size(1440, 900),
      Size(1920, 1080),
      Size(2560, 1440),
    ];
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = viewports.first;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(home: SearchTab(searchRepository: repository)),
    );
    await tester.pumpAndSettle();

    var previousColumnCount = 0;
    for (final viewport in viewports) {
      tester.view.physicalSize = viewport;
      await tester.pumpAndSettle();

      final delegate = tester
          .widget<SliverGrid>(find.byKey(const Key('responsive-explore-grid')))
          .gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, greaterThanOrEqualTo(2));
      expect(
        delegate.crossAxisCount,
        greaterThanOrEqualTo(previousColumnCount),
        reason: 'Grid density should not decrease at $viewport.',
      );
      expect(
        tester.takeException(),
        isNull,
        reason: 'Explore should render without overflow at $viewport.',
      );
      previousColumnCount = delegate.crossAxisCount;
    }

    expect(previousColumnCount, greaterThan(2));
  });

  testWidgets('media details switch between stacked and two-pane layouts', (
    tester,
  ) async {
    const item = MediaItem(
      id: 'responsive_detail',
      title: 'Responsive Detail',
      coverUrl: '',
      currentProgress: 3,
      totalCount: 12,
      mediaType: 'anime',
      status: 'Watching',
    );
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(home: MediaDetailScreen(item: item)),
    );
    await tester.pumpAndSettle();
    expect(
        find.byKey(const Key('stacked-media-detail-layout')), findsOneWidget);

    tester.view.physicalSize = const Size(1280, 800);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('expanded-media-detail-layout')),
      findsOneWidget,
    );
  });

  testWidgets('manual entry form remains readable on a wide window', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1600, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: ManualMediaScreen()));
    await tester.pump();

    final titleFieldSize = tester.getSize(
      find.byKey(const Key('manual-title-field')),
    );
    expect(titleFieldSize.width, lessThanOrEqualTo(640));
  });
}
