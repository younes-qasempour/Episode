# Graph Report - D:\Coding\OtakuLog  (2026-08-01)

## Corpus Check
- Corpus is ~28,677 words - fits in a single context window. You may not need a graph.

## Summary
- 486 nodes · 621 edges · 32 communities (27 shown, 5 thin omitted)
- Extraction: 96% EXTRACTED · 4% INFERRED · 0% AMBIGUOUS · INFERRED: 26 edges (avg confidence: 0.93)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Media Domain Model
- Library and Search UI
- Widget and Service Tests
- Media Detail Editing
- Storage and API Data
- Manual Media Creation
- Search Quality Roadmap
- Application Theme
- Navigation and Library State
- Season Editing
- Flexible Progress Design
- Project Documentation
- Media Card Presentation
- Local Library Documentation
- Flutter Package Configuration
- Profile Feature Documentation
- Application Bootstrap
- Profile Screen
- Flutter Widget State
- Android Activity
- HDPI Launcher Asset
- MDPI Launcher Asset
- XHDPI Launcher Asset
- XXHDPI Launcher Asset
- XXXHDPI Launcher Asset
- Media Type Enum
- Progress Mode Enum
- Release Status Enum
- Tracking Status Enum

## God Nodes (most connected - your core abstractions)
1. `OtakuLog Documentation` - 19 edges
2. `Task Board` - 15 edges
3. `Local Library and Home` - 15 edges
4. `Remote Discovery and Explore` - 13 edges
5. `Manual Media and Flexible Progress` - 10 edges
6. `OtakuLog Package Manifest` - 10 edges
7. `Media Details and Editing` - 9 edges
8. `ApiService` - 8 edges
9. `Profile and Theme` - 8 edges
10. `Feature Documentation` - 7 edges

## Surprising Connections (you probably didn't know these)
- `ApiService` --conceptually_related_to--> `http Dependency`  [INFERRED]
  docs/features/media-search.md → pubspec.yaml
- `Package Resolution Blocker` --semantically_similar_to--> `OTAKU-001 Restore Reproducible Toolchain`  [INFERRED] [semantically similar]
  docs/TESTING_GUIDE.md → docs/TASK_BOARD.md
- `OTAKU-009 Decide Unused Persistence Dependencies` --conceptually_related_to--> `path_provider Dependency`  [EXTRACTED]
  docs/TASK_BOARD.md → pubspec.yaml
- `SharedPreferences JSON Store` --conceptually_related_to--> `shared_preferences Dependency`  [INFERRED]
  docs/features/local-library.md → pubspec.yaml
- `Flutter Bootstrap Script` --conceptually_related_to--> `Flutter SDK`  [INFERRED]
  web/index.html → pubspec.yaml

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Remote Search Pipeline** — docs_features_media_search_search_tab, docs_features_media_search_search_repository, docs_features_media_search_api_service, docs_features_media_search_jikan_v4, docs_features_media_search_tvmaze, docs_features_media_search_mediaitem [EXTRACTED 1.00]
- **Shared MediaItem Feature Model** — docs_features_local_library_mediaitem_model, docs_features_manual_media_and_progress_mediaitem, docs_features_media_details_mediaitem, docs_features_media_search_mediaitem [INFERRED 0.95]
- **Flexible Progress Consistency** — docs_features_local_library_uncapped_progress_rule, docs_features_manual_media_and_progress_authoritative_progress_modes, docs_features_manual_media_and_progress_reversible_progress_conversion, docs_features_media_details_explicit_completion_rule, docs_features_media_details_reversible_progress_conversion [INFERRED 0.85]

## Communities (32 total, 5 thin omitted)

### Community 0 - "Media Domain Model"
Cohesion: 0.04
Nodes (52): int get, cardSeason, converted, convertedTo, copyWith, coverUrl, createManualId, createSeasonId (+44 more)

### Community 1 - "Library and Search UI"
Cohesion: 0.05
Nodes (41): dart:async, sampleMediaItems, _apiService, searchMedia, SearchRepository, build, _buildStatItem, createState (+33 more)

### Community 2 - "Widget and Service Tests"
Cohesion: 0.07
Nodes (30): Exception, ApiService, package:flutter/material.dart, package:flutter_test/flutter_test.dart, package:otaku_log/main.dart, package:otaku_log/models/media_item.dart, package:otaku_log/repositories/search_repository.dart, package:otaku_log/screens/manual_media_screen.dart (+22 more)

### Community 3 - "Media Detail Editing"
Cohesion: 0.05
Nodes (37): int?, build, _buildFlatProgress, _buildHeader, _buildInfoPanel, _buildRating, _buildSeasonProgress, _changeProgressMode (+29 more)

### Community 4 - "Storage and API Data"
Cohesion: 0.07
Nodes (29): Client, dart:convert, ../data/mock_data.dart, MediaItem, deleteMediaItem, _getPrefs, incrementProgress, loadMediaItems (+21 more)

### Community 5 - "Manual Media Creation"
Cohesion: 0.07
Nodes (27): bool get, build, _coverController, createState, _deleteSeason, dispose, _draftId, _editSeason (+19 more)

### Community 6 - "Search Quality Roadmap"
Cohesion: 0.11
Nodes (28): ApiService, Concurrent Provider Search, Failure Collapses to Empty Results, Jikan v4, MediaItem, Remote Discovery and Explore, Repository Injection, SearchRepository (+20 more)

### Community 7 - "Application Theme"
Cohesion: 0.07
Nodes (26): AppTheme, buttonRadius, cardRadius, chipRadius, darkBg, darkOnSurface, darkOnSurfaceVariant, darkOutline (+18 more)

### Community 8 - "Navigation and Library State"
Cohesion: 0.08
Nodes (25): home_tab.dart, _addToLibrary, build, createState, _currentIndex, currentThemeMode, _deleteItem, _incrementProgress (+17 more)

### Community 9 - "Season Editing"
Cohesion: 0.09
Nodes (23): FormState, MediaSeason, build, createState, dispose, existingSeasons, _formKey, initState (+15 more)

### Community 10 - "Flexible Progress Design"
Cohesion: 0.15
Nodes (19): Authoritative Progress Modes, Manual ID Generation, Manual Media and Flexible Progress, ManualMediaScreen, MediaItem, MediaSeason, Reversible Progress Conversion, Tracking and Release Status Separation (+11 more)

### Community 11 - "Project Documentation"
Cohesion: 0.11
Nodes (19): Agent Changelog, Agent Workflow, Architecture, Codebase Map, Current State, Data and API, Decisions, Design System (+11 more)

### Community 12 - "Media Card Presentation"
Cohesion: 0.12
Nodes (17): Color, ProfileTab, build, createState, item, MediaCard, onIncrementProgress, onPressed (+9 more)

### Community 13 - "Local Library Documentation"
Cohesion: 0.17
Nodes (16): Backward-Compatible Media JSON, HomeTab, Local Library and Home, LocalStorageRepository, MainNavigationScreen, ManualMediaScreen, MediaCard, MediaItem Model (+8 more)

### Community 14 - "Flutter Package Configuration"
Cohesion: 0.15
Nodes (16): OTAKU-009 Decide Unused Persistence Dependencies, Dart SDK Constraint, flutter_lints Dependency, Flutter SDK, flutter_test Dependency, hive Dependency, hive_flutter Dependency, http Dependency (+8 more)

### Community 15 - "Profile Feature Documentation"
Cohesion: 0.39
Nodes (8): AppTheme, OtakuLogApp, Profile and Theme, Profile Placeholder Content, ProfileTab, Root Theme Ownership, Volatile Theme Preference, OTAKU-006 Confirm Profile Scope

### Community 16 - "Application Bootstrap"
Cohesion: 0.25
Nodes (7): build, createState, _handleThemeModeChanged, main, _themeMode, screens/main_navigation_screen.dart, ../theme/app_theme.dart

### Community 17 - "Profile Screen"
Cohesion: 0.25
Nodes (7): build, _buildOverviewCard, _buildSettingTile, currentThemeMode, onThemeModeChanged, ThemeMode, ValueChanged

### Community 18 - "Flutter Widget State"
Cohesion: 0.40
Nodes (6): OtakuLogApp, _OtakuLogAppState, ManualMediaScreen, _ManualMediaScreenState, State, StatefulWidget

### Community 20 - "HDPI Launcher Asset"
Cohesion: 0.67
Nodes (3): Android HDPI Launcher Asset, Flutter Logo, OtakuLog Android Launcher Icon

### Community 21 - "MDPI Launcher Asset"
Cohesion: 0.67
Nodes (3): Android MDPI Launcher Asset, Flutter Logo, OtakuLog Android Launcher Icon

### Community 22 - "XHDPI Launcher Asset"
Cohesion: 0.67
Nodes (3): Android XHDPI Launcher Asset, Flutter Logo, OtakuLog Android Launcher Icon

### Community 23 - "XXHDPI Launcher Asset"
Cohesion: 0.67
Nodes (3): Android XXHDPI Launcher Asset, Flutter Logo, OtakuLog Android Launcher Icon

### Community 24 - "XXXHDPI Launcher Asset"
Cohesion: 0.67
Nodes (3): Android XXXHDPI Launcher Asset, Flutter Logo, OtakuLog Android Launcher Icon

## Knowledge Gaps
- **285 isolated node(s):** `sampleMediaItems`, `_themeMode`, `main`, `createState`, `_handleThemeModeChanged` (+280 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **5 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `MediaItem` connect `Storage and API Data` to `Media Domain Model`, `Media Detail Editing`, `Media Card Presentation`?**
  _High betweenness centrality (0.026) - this node is a cross-community bridge._
- **Why does `Feature Documentation` connect `Flexible Progress Design` to `Project Documentation`, `Local Library Documentation`, `Search Quality Roadmap`, `Profile Feature Documentation`?**
  _High betweenness centrality (0.019) - this node is a cross-community bridge._
- **Why does `ReleaseStatus` connect `Release Status Enum` to `Media Domain Model`, `Season Editing`, `Media Detail Editing`, `Manual Media Creation`?**
  _High betweenness centrality (0.018) - this node is a cross-community bridge._
- **What connects `sampleMediaItems`, `_themeMode`, `main` to the rest of the system?**
  _285 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Media Domain Model` be split into smaller, more focused modules?**
  _Cohesion score 0.03773584905660377 - nodes in this community are weakly interconnected._
- **Should `Library and Search UI` be split into smaller, more focused modules?**
  _Cohesion score 0.050505050505050504 - nodes in this community are weakly interconnected._
- **Should `Widget and Service Tests` be split into smaller, more focused modules?**
  _Cohesion score 0.07254623044096728 - nodes in this community are weakly interconnected._

## Extraction Warning

Semantic extraction timed out for 16 documentation files in chunk 1; code AST extraction and the remaining 20 semantic files completed.

## Graph Health Warning

The undirected build collapsed 88 same-endpoint edges (87 in directed comparison). No missing endpoints, dangling endpoints, or self-loops were found.
