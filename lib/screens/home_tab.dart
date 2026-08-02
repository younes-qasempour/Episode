import 'package:flutter/material.dart';
import '../models/media_item.dart';
import '../widgets/media_card.dart';
import '../theme/app_theme.dart';

class HomeTab extends StatefulWidget {
  final List<MediaItem> mediaItems;
  final Function(String id) onIncrementProgress;
  final Function(MediaItem item)? onItemTap;
  final VoidCallback? onAddManually;

  const HomeTab({
    super.key,
    required this.mediaItems,
    required this.onIncrementProgress,
    this.onItemTap,
    this.onAddManually,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String _selectedCategory = 'All';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filteredItems = widget.mediaItems.where((item) {
      final matchesCategory = _selectedCategory == 'All' ||
          item.mediaType.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          item.title.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

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

    return CustomScrollView(
      slivers: [
        // App Bar Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                      'OtakuLog',
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
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  child: const CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(
                      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
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
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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

        // Search Bar Input
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search your anime, manga, or series...',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),

        // Category Filter Chips
        SliverToBoxAdapter(
          child: SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              children: ['All', 'Anime', 'Manga', 'Series', 'Movie'].map((
                category,
              ) {
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCategory = category);
                      }
                    },
                    selectedColor: theme.colorScheme.primary,
                    backgroundColor: isDark
                        ? const Color(0xFF16253B)
                        : const Color(0xFFE5EEFF),
                    labelStyle: TextStyle(
                      fontFamily: 'Be Vietnam Pro',
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.chipRadius),
                      side: BorderSide.none,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Title Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Continue Watching & Reading',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  '${filteredItems.length} items',
                  style: TextStyle(
                    fontFamily: 'Be Vietnam Pro',
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
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
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.1),
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
                            : 'Try clearing your search term or switching category filters.',
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
                      ],
                    ],
                  ),
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = filteredItems[index];
                    return MediaCard(
                      item: item,
                      onIncrementProgress: () =>
                          widget.onIncrementProgress(item.id),
                      onTap: () {
                        if (widget.onItemTap != null) {
                          widget.onItemTap!(item);
                        }
                      },
                    );
                  }, childCount: filteredItems.length),
                ),
              ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
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
