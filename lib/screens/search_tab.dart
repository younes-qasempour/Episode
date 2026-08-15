import 'dart:async';
import 'package:flutter/material.dart';

import '../layout/responsive_layout.dart';
import '../models/media_item.dart';
import '../models/search_result.dart';
import '../repositories/search_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/shimmer_skeleton.dart';

class SearchTab extends StatefulWidget {
  final Function(MediaItem item)? onAddToLibrary;
  final VoidCallback? onAddManually;
  final List<MediaItem> existingItems;
  final SearchRepository? searchRepository;

  const SearchTab({
    super.key,
    this.onAddToLibrary,
    this.onAddManually,
    this.existingItems = const [],
    this.searchRepository,
  });

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  late final SearchRepository _searchRepository;
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'All';
  List<MediaItem> _searchResults = [];
  bool _isLoading = false;
  SearchFailure? _searchFailure;
  Timer? _debounceTimer;
  int _searchRequestId = 0;
  final Set<String> _pendingAddIds = <String>{};

  @override
  void initState() {
    super.initState();
    _searchRepository = widget.searchRepository ?? SearchRepository();
    _performSearch('');
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    final requestId = ++_searchRequestId;

    setState(() {
      _isLoading = true;
      _searchFailure = null;
    });

    try {
      final result = await _searchRepository.searchMedia(
        query,
        category: _selectedCategory,
      );
      if (mounted && requestId == _searchRequestId) {
        setState(() {
          _isLoading = false;
          switch (result) {
            case SearchSuccess(:final data):
              _searchResults = data;
              _searchFailure = null;
            case SearchFailure():
              _searchResults = [];
              _searchFailure = result;
          }
        });
      }
    } catch (e) {
      if (mounted && requestId == _searchRequestId) {
        setState(() {
          _searchResults = [];
          _searchFailure = SearchFailure(
            type: SearchFailureType.unknown,
            technicalMessage: e.toString(),
          );
          _isLoading = false;
        });
      }
    }
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _performSearch(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Live Media Search')),
      body: ResponsiveBuilder(
        builder: (context, layout) {
          final maxWidth = layout.maxWidthFor(ContentWidth.dashboard);
          final contentWidth =
              layout.width > maxWidth ? maxWidth : layout.width;
          final gridSpec = layout.mediaGrid(
            availableWidth: contentWidth,
            maxContentWidth: maxWidth,
          );
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: CustomScrollView(
                slivers: [
                  // Search Input Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: layout.horizontalPadding,
                        vertical: 8,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            decoration: InputDecoration(
                              hintText: 'Search anime, manga, or TV series...',
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded),
                                      onPressed: () {
                                        _searchController.clear();
                                        _performSearch('');
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Category Chips Row (All, Anime, Manga, Series)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      child: SizedBox(
                        height: 44,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(
                            horizontal: layout.horizontalPadding - 4,
                          ),
                          children: ['All', 'Anime', 'Manga', 'Series']
                              .map((category) {
                            final isSelected = _selectedCategory == category;
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: FilterChip(
                                label: Text(category),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    _onCategorySelected(category);
                                  }
                                },
                                selectedColor: theme.colorScheme.primary,
                                backgroundColor: isDark
                                    ? const Color(0xFF16253B)
                                    : const Color(0xFFE5EEFF),
                                labelStyle: TextStyle(
                                  fontFamily: 'Be Vietnam Pro',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.chipRadius,
                                  ),
                                  side: BorderSide.none,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        layout.horizontalPadding,
                        4,
                        layout.horizontalPadding,
                        8,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          key: const Key('add-media-manually-button'),
                          onPressed: widget.onAddManually,
                          icon: const Icon(Icons.edit_note_rounded),
                          label: const Text("Can't find it? Add manually"),
                        ),
                      ),
                    ),
                  ),

                  // Results Header Title
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        layout.horizontalPadding,
                        12,
                        layout.horizontalPadding,
                        12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _searchController.text.isEmpty
                                  ? '🔥 Top & Popular Results'
                                  : 'Search Results',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (!_isLoading && _searchFailure == null) ...[
                            const SizedBox(width: 12),
                            Text(
                              '${_searchResults.length} items',
                              style: TextStyle(
                                fontFamily: 'Be Vietnam Pro',
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Loading Indicator
                  if (_isLoading)
                    SliverFillRemaining(
                      child: ShimmerSkeletonGrid(
                        itemCount: gridSpec.columns * 2,
                        gridDelegate: gridSpec.delegate,
                        padding: EdgeInsets.symmetric(
                          horizontal: layout.horizontalPadding,
                        ),
                      ),
                    )
                  // Failure State
                  else if (_searchFailure != null)
                    _buildErrorView(context, _searchFailure!)
                  // Empty State
                  else if (_searchResults.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.manage_search_rounded,
                              size: 56,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No results found for "${_searchController.text}"',
                              style: TextStyle(
                                fontFamily: 'Be Vietnam Pro',
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  // Search Results Grid
                  else
                    SliverPadding(
                      padding: EdgeInsets.symmetric(
                        horizontal: layout.horizontalPadding,
                      ),
                      sliver: SliverGrid(
                        key: const Key('responsive-explore-grid'),
                        gridDelegate: gridSpec.delegate,
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final item = _searchResults[index];
                          final isAlreadyAdded = widget.existingItems.any(
                                (e) =>
                                    e.id == item.id ||
                                    e.title.toLowerCase() ==
                                        item.title.toLowerCase(),
                              ) ||
                              _pendingAddIds.contains(item.id);

                          return _buildSearchResultCard(
                              context, item, isAlreadyAdded);
                        }, childCount: _searchResults.length),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, SearchFailure failure) {
    final theme = Theme.of(context);
    String title;
    String subtitle;
    IconData icon;

    switch (failure.type) {
      case SearchFailureType.network:
        title = 'No Internet Connection';
        subtitle = 'Please check your connection and try again.';
        icon = Icons.wifi_off_rounded;
      case SearchFailureType.timeout:
        title = 'Request Timed Out';
        subtitle = 'Taking longer than expected. Please try again.';
        icon = Icons.timer_off_rounded;
      case SearchFailureType.rateLimited:
        title = 'Rate Limit Exceeded';
        subtitle = 'Too many requests. Please wait a moment and try again.';
        icon = Icons.speed_rounded;
      case SearchFailureType.server:
        title = 'Service Temporarily Unavailable';
        subtitle =
            'The search service is temporarily down. Please try again later.';
        icon = Icons.cloud_off_rounded;
      case SearchFailureType.invalidResponse:
        title = 'Unable to Process Results';
        subtitle = 'Could not read search results. Please try again.';
        icon = Icons.data_object_rounded;
      case SearchFailureType.unknown:
        title = 'Search Failed';
        subtitle = 'Something went wrong during search. Please try again.';
        icon = Icons.error_outline_rounded;
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              icon,
              size: 52,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Be Vietnam Pro',
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              key: const Key('search-retry-button'),
              onPressed: _isLoading
                  ? null
                  : () {
                      _performSearch(_searchController.text);
                    },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.peachAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultCard(
    BuildContext context,
    MediaItem item,
    bool isAlreadyAdded,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    IconData typeIcon;
    switch (item.mediaType.toLowerCase()) {
      case 'manga':
        typeIcon = Icons.menu_book_rounded;
        break;
      case 'series':
        typeIcon = Icons.tv_rounded;
        break;
      case 'anime':
      default:
        typeIcon = Icons.movie_filter_rounded;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(
          color: isDark ? const Color(0xFF263852) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: AppTheme.primaryIndigo.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover Image + Type Chip
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppTheme.cardRadius),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: Image.network(
                      item.coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: isDark
                            ? const Color(0xFF1E2E44)
                            : const Color(0xFFE0E7FF),
                        child: Icon(
                          typeIcon,
                          size: 36,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(typeIcon, size: 11, color: Colors.white),
                        const SizedBox(width: 3),
                        Text(
                          item.mediaType.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Details & Add Button
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.unitLabel} count: ${item.totalCount ?? "Unknown"}',
                  style: TextStyle(
                    fontFamily: 'Be Vietnam Pro',
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),

                // Add to Library Button
                SizedBox(
                  width: double.infinity,
                  height: 32,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: isAlreadyAdded
                          ? (isDark
                              ? const Color(0xFF1E2E44)
                              : const Color(0xFFE2E8F0))
                          : AppTheme.peachAccent,
                      foregroundColor: isAlreadyAdded
                          ? theme.colorScheme.onSurfaceVariant
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: isAlreadyAdded
                        ? null
                        : () {
                            if (_pendingAddIds.contains(item.id)) return;
                            setState(() {
                              _pendingAddIds.add(item.id);
                            });
                            widget.onAddToLibrary?.call(item);
                          },
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isAlreadyAdded
                                ? Icons.check_circle_rounded
                                : Icons.bookmark_add_rounded,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isAlreadyAdded ? 'In Library' : 'Add to Library',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
