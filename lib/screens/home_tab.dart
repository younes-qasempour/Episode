import 'package:flutter/material.dart';
import '../layout/responsive_layout.dart';
import '../models/media_item.dart';
import '../widgets/episode_brand.dart';
import '../widgets/media_card.dart';
import '../theme/app_theme.dart';

enum LibrarySortOption {
  recentlyUpdated('Recently Updated'),
  titleAZ('Title (A-Z)'),
  ratingHighToLow('Rating (High → Low)'),
  completionPercentage('Completion %');

  final String label;
  const LibrarySortOption(this.label);
}

class HomeTab extends StatefulWidget {
  final List<MediaItem> mediaItems;
  final Function(String id) onIncrementProgress;
  final Function(MediaItem item)? onItemTap;
  final VoidCallback? onAddManually;
  final Function(String id)? onToggleFavorite;

  const HomeTab({
    super.key,
    required this.mediaItems,
    required this.onIncrementProgress,
    this.onItemTap,
    this.onAddManually,
    this.onToggleFavorite,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String _selectedCategory = 'All';
  String _selectedStatus = 'All';
  String _selectedCollection = 'All';
  String _searchQuery = '';
  LibrarySortOption _sortOption = LibrarySortOption.recentlyUpdated;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetFiltersAndSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedCategory = 'All';
      _selectedStatus = 'All';
      _selectedCollection = 'All';
      _sortOption = LibrarySortOption.recentlyUpdated;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filteredItems = widget.mediaItems.where((item) {
      final matchesCategory = _selectedCategory == 'All' ||
          item.mediaType.toLowerCase() == _selectedCategory.toLowerCase();

      bool matchesStatus = true;
      if (_selectedStatus == 'Watching') {
        matchesStatus = item.trackingStatus == TrackingStatus.watching ||
            item.trackingStatus == TrackingStatus.reading;
      } else if (_selectedStatus == 'Completed') {
        matchesStatus = item.trackingStatus == TrackingStatus.completed;
      } else if (_selectedStatus == 'Favorites') {
        matchesStatus = item.isFavorite;
      }

      final matchesSearch = _searchQuery.isEmpty ||
          item.title.toLowerCase().contains(_searchQuery.toLowerCase());

      bool matchesCollection = true;
      if (_selectedCollection == '🌟 Favorites') {
        matchesCollection = item.isFavorite;
      } else if (_selectedCollection == '⭐ Top Rated') {
        matchesCollection = item.rating >= 8.0;
      } else if (_selectedCollection == '⚡ Binge Worthy') {
        matchesCollection =
            item.tags.contains('Binge Worthy') || item.currentProgress > 10;
      } else if (_selectedCollection == '📡 On-Going') {
        matchesCollection = item.releaseStatus == ReleaseStatus.ongoing;
      } else if (_selectedCollection == '🏆 Classics') {
        matchesCollection = item.tags.contains('Classic');
      }

      return matchesCategory &&
          matchesStatus &&
          matchesSearch &&
          matchesCollection;
    }).toList();

    filteredItems.sort((a, b) {
      switch (_sortOption) {
        case LibrarySortOption.titleAZ:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case LibrarySortOption.ratingHighToLow:
          final ratingCompare = b.rating.compareTo(a.rating);
          if (ratingCompare != 0) return ratingCompare;
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case LibrarySortOption.completionPercentage:
          final pctCompare =
              b.progressPercentage.compareTo(a.progressPercentage);
          if (pctCompare != 0) return pctCompare;
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case LibrarySortOption.recentlyUpdated:
          return b.updatedAt.compareTo(a.updatedAt);
      }
    });

    final currentlyWatchingCount = widget.mediaItems
        .where(
          (item) =>
              item.trackingStatus == TrackingStatus.watching ||
              item.trackingStatus == TrackingStatus.reading,
        )
        .length;
    final completedCount = widget.mediaItems
        .where((item) => item.trackingStatus == TrackingStatus.completed)
        .length;

    final isFilteredOrSearched = _selectedCategory != 'All' ||
        _selectedStatus != 'All' ||
        _searchQuery.isNotEmpty;

    return ResponsiveBuilder(
      builder: (context, layout) {
        final maxWidth = layout.maxWidthFor(ContentWidth.standard);
        final contentWidth = layout.width > maxWidth ? maxWidth : layout.width;
        final libraryColumns = layout.columnsFor(
          availableWidth: contentWidth - layout.horizontalPadding * 2,
          minItemWidth: 480,
          maxColumns: 2,
        );
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: CustomScrollView(
              slivers: [
                // App Bar Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      layout.horizontalPadding,
                      16,
                      layout.horizontalPadding,
                      12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const EpisodeBrand(
                              markSize: 44,
                              showName: false,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back, 👋',
                                  style: TextStyle(
                                    fontFamily: 'Be Vietnam Pro',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Episode',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: theme.colorScheme.primary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Icon(
                              Icons.person_rounded,
                              color: theme.colorScheme.onPrimaryContainer,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Quick Stats Header Banner
                SliverToBoxAdapter(
                  child: Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: layout.horizontalPadding,
                      vertical: 8,
                    ),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF4648D4), const Color(0xFF6063EE)]
                            : [AppTheme.primaryIndigo, const Color(0xFF6366F1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryIndigo.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          'Tracked',
                          '${widget.mediaItems.length}',
                          Colors.white,
                        ),
                        Container(height: 36, width: 1, color: Colors.white24),
                        _buildStatItem(
                          'Active',
                          '$currentlyWatchingCount',
                          AppTheme.peachAccentDark,
                        ),
                        Container(height: 36, width: 1, color: Colors.white24),
                        _buildStatItem(
                          'Completed',
                          '$completedCount',
                          const Color(0xFF34D399),
                        ),
                      ],
                    ),
                  ),
                ),

                // Fast In-Library Search Bar Input
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: layout.horizontalPadding,
                      vertical: 8,
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _searchQuery = value.trim()),
                      decoration: InputDecoration(
                        hintText: 'Search saved titles...',
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                                tooltip: 'Clear search',
                              )
                            : null,
                      ),
                    ),
                  ),
                ),

                // Multi-Axis Filter Chips (Media Type & Status)
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Media Type Chips
                      SizedBox(
                        height: 44,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(
                            horizontal: layout.horizontalPadding - 4,
                            vertical: 2,
                          ),
                          children: ['All', 'Anime', 'Manga', 'Series', 'Movie']
                              .map((category) {
                            final isSelected = _selectedCategory == category;
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: ChoiceChip(
                                label: Text(category),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(
                                        () => _selectedCategory = category);
                                  }
                                },
                                selectedColor: theme.colorScheme.primary,
                                backgroundColor: isDark
                                    ? const Color(0xFF16253B)
                                    : const Color(0xFFE5EEFF),
                                labelStyle: TextStyle(
                                  fontFamily: 'Be Vietnam Pro',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: isSelected
                                      ? Colors.white
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.chipRadius),
                                  side: BorderSide.none,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Status Filter Chips
                      SizedBox(
                        height: 44,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(
                            horizontal: layout.horizontalPadding - 4,
                            vertical: 2,
                          ),
                          children: [
                            _buildStatusChip('All', 'All Status',
                                Icons.filter_alt_outlined, theme, isDark),
                            _buildStatusChip(
                                'Watching',
                                'Watching',
                                Icons.play_circle_outline_rounded,
                                theme,
                                isDark),
                            _buildStatusChip(
                                'Completed',
                                'Completed',
                                Icons.check_circle_outline_rounded,
                                theme,
                                isDark),
                            _buildStatusChip('Favorites', 'Favorites',
                                Icons.favorite_border_rounded, theme, isDark),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Smart Collections Filter Chips
                      SizedBox(
                        height: 44,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(
                            horizontal: layout.horizontalPadding - 4,
                            vertical: 2,
                          ),
                          children: [
                            _buildCollectionChip(
                                'All', 'All Collections', theme, isDark),
                            _buildCollectionChip('🌟 Favorites', '🌟 Favorites',
                                theme, isDark),
                            _buildCollectionChip('⭐ Top Rated', '⭐ Top Rated',
                                theme, isDark),
                            _buildCollectionChip('⚡ Binge Worthy',
                                '⚡ Binge Worthy', theme, isDark),
                            _buildCollectionChip('📡 On-Going', '📡 On-Going',
                                theme, isDark),
                            _buildCollectionChip(
                                '🏆 Classics', '🏆 Classics', theme, isDark),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Header Section with Item Count and Sort Menu
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      layout.horizontalPadding,
                      16,
                      layout.horizontalPadding,
                      8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Continue Watching & Reading',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        PopupMenuButton<LibrarySortOption>(
                          initialValue: _sortOption,
                          onSelected: (option) =>
                              setState(() => _sortOption = option),
                          tooltip: 'Sort Options',
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF16253B)
                                  : const Color(0xFFE5EEFF),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.sort_rounded,
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _sortOption.label,
                                  style: TextStyle(
                                    fontFamily: 'Be Vietnam Pro',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_drop_down,
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                              ],
                            ),
                          ),
                          itemBuilder: (context) =>
                              LibrarySortOption.values.map((option) {
                            return PopupMenuItem<LibrarySortOption>(
                              value: option,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    option == _sortOption
                                        ? Icons.check_rounded
                                        : Icons.radio_button_unchecked,
                                    size: 16,
                                    color: option == _sortOption
                                        ? theme.colorScheme.primary
                                        : Colors.transparent,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      option.label,
                                      style: TextStyle(
                                        fontFamily: 'Be Vietnam Pro',
                                        fontWeight: option == _sortOption
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

                // Media Item List
                filteredItems.isEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 48,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  widget.mediaItems.isEmpty
                                      ? Icons.library_add_rounded
                                      : Icons.search_off_rounded,
                                  size: 52,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                widget.mediaItems.isEmpty
                                    ? 'No shows added yet'
                                    : 'No media items match your filter',
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
                                widget.mediaItems.isEmpty
                                    ? 'Explore remote results or add anime, manga, series, and movies manually.'
                                    : 'Try clearing your search term or resetting your category/status filters.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Be Vietnam Pro',
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (widget.mediaItems.isEmpty &&
                                  widget.onAddManually != null) ...[
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed: widget.onAddManually,
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('Add manually'),
                                ),
                              ] else if (isFilteredOrSearched) ...[
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  onPressed: _resetFiltersAndSearch,
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text('Reset filters & search'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: layout.horizontalPadding,
                        ),
                        sliver: layout.isCompact
                            ? SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) =>
                                      _buildMediaCard(filteredItems[index]),
                                  childCount: filteredItems.length,
                                ),
                              )
                            : SliverGrid(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: libraryColumns,
                                  mainAxisExtent: 172,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) =>
                                      _buildMediaCard(filteredItems[index]),
                                  childCount: filteredItems.length,
                                ),
                              ),
                      ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMediaCard(MediaItem item) {
    return MediaCard(
      item: item,
      onIncrementProgress: () => widget.onIncrementProgress(item.id),
      onToggleFavorite: widget.onToggleFavorite != null
          ? () => widget.onToggleFavorite!(item.id)
          : null,
      onTap: () => widget.onItemTap?.call(item),
    );
  }

  Widget _buildStatusChip(
    String key,
    String label,
    IconData icon,
    ThemeData theme,
    bool isDark,
  ) {
    final isSelected = _selectedStatus == key;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        avatar: Icon(
          icon,
          size: 14,
          color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
        ),
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() => _selectedStatus = key);
          }
        },
        selectedColor:
            key == 'Favorites' ? Colors.redAccent : theme.colorScheme.primary,
        backgroundColor:
            isDark ? const Color(0xFF16253B) : const Color(0xFFE5EEFF),
        labelStyle: TextStyle(
          fontFamily: 'Be Vietnam Pro',
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.chipRadius),
          side: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildCollectionChip(
    String key,
    String label,
    ThemeData theme,
    bool isDark,
  ) {
    final isSelected = _selectedCollection == key;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() => _selectedCollection = key);
          }
        },
        selectedColor: theme.colorScheme.secondary,
        backgroundColor:
            isDark ? const Color(0xFF16253B) : const Color(0xFFE5EEFF),
        labelStyle: TextStyle(
          fontFamily: 'Be Vietnam Pro',
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.chipRadius),
          side: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Be Vietnam Pro',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}
