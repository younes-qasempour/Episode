import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/activity_log_entry.dart';
import '../models/library_stats.dart';
import '../models/media_item.dart';
import '../models/user_profile_data.dart';
import '../theme/app_theme.dart';
import 'donut_chart.dart';
import 'streak_heatmap.dart';

/// Comprehensive Personal Analytics & Viewing Stats Dashboard.
class ProfileStatsDashboard extends StatefulWidget {
  final List<MediaItem> mediaItems;
  final UserProfileData userProfile;
  final List<ActivityLogEntry> activityLogs;
  final ValueChanged<UserProfileData>? onProfileUpdated;
  final ValueChanged<MediaItem>? onItemTap;
  final ValueChanged<String>? onIncrementProgress;

  const ProfileStatsDashboard({
    super.key,
    required this.mediaItems,
    required this.userProfile,
    this.activityLogs = const [],
    this.onProfileUpdated,
    this.onItemTap,
    this.onIncrementProgress,
  });

  @override
  State<ProfileStatsDashboard> createState() => _ProfileStatsDashboardState();
}

class _ProfileStatsDashboardState extends State<ProfileStatsDashboard> {
  bool _showMediaTypeChart = true;

  void _openEditProfileDialog() {
    final nameCtrl =
        TextEditingController(text: widget.userProfile.displayName);
    final bioCtrl = TextEditingController(text: widget.userProfile.bio);
    final quoteCtrl =
        TextEditingController(text: widget.userProfile.favoriteQuote);
    int selectedColorIdx = widget.userProfile.avatarColorIndex;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final theme = Theme.of(ctx);
            return AlertDialog(
              title: const Text('Edit Personal Profile'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Display Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: bioCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Bio / Status Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: quoteCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Favorite Quote / Motto',
                        border: OutlineInputBorder(),
                        hintText: 'e.g. "Believe it!"',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Avatar Accent Color',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        avatarAccentColors.length,
                        (index) {
                          final color = avatarAccentColors[index];
                          final isSelected = selectedColorIdx == index;
                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedColorIdx = index;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(
                                        color: theme.colorScheme.onSurface,
                                        width: 3,
                                      )
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final updated = widget.userProfile.copyWith(
                      displayName: nameCtrl.text.trim(),
                      bio: bioCtrl.text.trim(),
                      favoriteQuote: quoteCtrl.text.trim(),
                      avatarColorIndex: selectedColorIdx,
                    );
                    widget.onProfileUpdated?.call(updated);
                    Navigator.of(dialogCtx).pop();
                  },
                  child: const Text('Save Profile'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showShareableStatsCard(LibraryStats stats) {
    final summaryText = '''
🎬 Episode Viewing Stats:
• Episodes Watched: ${stats.totalEpisodesWatched}
• Chapters Read: ${stats.totalChaptersRead}
• Movies Watched: ${stats.totalMoviesWatched}
• Mean Score: ${stats.meanScore > 0 ? '${stats.meanScore} / 10 ⭐' : 'Unrated'}
• Top Genres: ${stats.topGenres.isNotEmpty ? stats.topGenres.join(', ') : 'Anime & Series'}
• Total Library: ${stats.totalItems} titles
''';

    showDialog<void>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;

        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.userProfile.avatarColor,
                      widget.userProfile.avatarColor.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppTheme.cardRadius),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.stars_rounded, color: Colors.white, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      widget.userProfile.displayName,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Episode Media Stats Snapshot',
                      style: TextStyle(
                        fontFamily: 'Be Vietnam Pro',
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildShareStatRow('Episodes Watched', '${stats.totalEpisodesWatched}'),
                    const Divider(height: 12),
                    _buildShareStatRow('Chapters Read', '${stats.totalChaptersRead}'),
                    const Divider(height: 12),
                    _buildShareStatRow('Mean Score', stats.meanScore > 0 ? '${stats.meanScore} ★' : 'N/A'),
                    const Divider(height: 12),
                    _buildShareStatRow('Top Genre', stats.topGenres.isNotEmpty ? stats.topGenres.first : 'Anime'),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: summaryText));
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Stats summary copied to clipboard!'),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Copy Stats Summary'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShareStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Be Vietnam Pro',
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final stats = LibraryStats.fromItems(widget.mediaItems);

    final favoriteItems =
        widget.mediaItems.where((i) => i.isFavorite).toList();
    final activeWatchingItems = widget.mediaItems
        .where((i) =>
            i.status == TrackingStatus.watching ||
            i.status == TrackingStatus.reading)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Personal Header & Bio Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            border: Border.all(
              color:
                  isDark ? const Color(0xFF263852) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: widget.userProfile.avatarColor,
                    child: Text(
                      widget.userProfile.displayName.isNotEmpty
                          ? widget.userProfile.displayName[0].toUpperCase()
                          : 'E',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.userProfile.displayName,
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.userProfile.bio,
                          style: TextStyle(
                            fontFamily: 'Be Vietnam Pro',
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_note_rounded),
                    tooltip: 'Edit Profile Bio',
                    onPressed: _openEditProfileDialog,
                  ),
                ],
              ),
              if (widget.userProfile.favoriteQuote.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: widget.userProfile.avatarColor
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: widget.userProfile.avatarColor
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '"${widget.userProfile.favoriteQuote}"',
                    style: TextStyle(
                      fontFamily: 'Be Vietnam Pro',
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                      color: widget.userProfile.avatarColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 2. Milestone Summary Grid Cards
        Row(
          children: [
            Expanded(
              child: _buildMilestoneCard(
                context,
                title: 'Episodes Watched',
                value: '${stats.totalEpisodesWatched}',
                subtitle: _formatHours(stats.estimatedWatchTimeHours),
                icon: Icons.play_circle_fill_rounded,
                color: const Color(0xFF6366F1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMilestoneCard(
                context,
                title: 'Chapters Read',
                value: '${stats.totalChaptersRead}',
                subtitle: _formatHours(stats.estimatedReadTimeHours),
                icon: Icons.menu_book_rounded,
                color: const Color(0xFFEC4899),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildMilestoneCard(
                context,
                title: 'Mean Score',
                value: stats.meanScore > 0 ? '${stats.meanScore} / 10' : 'N/A',
                subtitle: '${stats.ratedItemCount} rated items',
                icon: Icons.star_rounded,
                color: const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMilestoneCard(
                context,
                title: 'Total Library',
                value: '${stats.totalItems}',
                subtitle: '${stats.totalMoviesWatched} movies watched',
                icon: Icons.grid_view_rounded,
                color: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 3. 30-Day Activity Streak Heatmap
        StreakHeatmap(activityLogs: widget.activityLogs),
        const SizedBox(height: 20),

        // 3. Donut Chart Card (Media Types vs Statuses)
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            border: Border.all(
              color:
                  isDark ? const Color(0xFF263852) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Library Distribution',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  // Segmented Switch Toggle
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildToggleOption('Type', _showMediaTypeChart, () {
                          setState(() => _showMediaTypeChart = true);
                        }),
                        _buildToggleOption('Status', !_showMediaTypeChart, () {
                          setState(() => _showMediaTypeChart = false);
                        }),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_showMediaTypeChart) ...[
                DonutChart(
                  dataPoints: stats.mediaTypeSegments.map((s) {
                    return DonutDataPoint(
                      label: s.label,
                      count: s.count,
                      percentage: s.percentage,
                      color: _getMediaTypeColor(s.key),
                    );
                  }).toList(),
                  centerTitle: '${stats.totalItems}',
                  centerSubtitle: 'Total Items',
                ),
              ] else ...[
                DonutChart(
                  dataPoints: stats.statusSegments.map((s) {
                    return DonutDataPoint(
                      label: s.label,
                      count: s.count,
                      percentage: s.percentage,
                      color: _getStatusColor(s.key),
                    );
                  }).toList(),
                  centerTitle: '${stats.totalItems}',
                  centerSubtitle: 'Total Items',
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 4. Top Genres Insights
        if (stats.topGenres.isNotEmpty) ...[
          Text(
            'Top Favorite Genres',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: stats.topGenres.map((genre) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.userProfile.avatarColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.userProfile.avatarColor
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      size: 16,
                      color: widget.userProfile.avatarColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      genre,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: widget.userProfile.avatarColor,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],

        // 5. Quick Progress Strip (Active Watching / Reading)
        if (activeWatchingItems.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quick Progress Update',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                '${activeWatchingItems.length} active',
                style: TextStyle(
                  fontFamily: 'Be Vietnam Pro',
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: activeWatchingItems.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = activeWatchingItems[index];
                return _buildQuickProgressCard(context, item);
              },
            ),
          ),
          const SizedBox(height: 20),
        ],

        // 6. Favorites Showcase Shelf
        if (favoriteItems.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Starred Favorites',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                '${favoriteItems.length} items',
                style: TextStyle(
                  fontFamily: 'Be Vietnam Pro',
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: favoriteItems.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = favoriteItems[index];
                return GestureDetector(
                  onTap: () => widget.onItemTap?.call(item),
                  child: Container(
                    width: 95,
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFF59E0B),
                        width: 1.5,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: item.coverUrl.isNotEmpty
                              ? Image.network(
                                  item.coverUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(Icons.movie_outlined),
                                  ),
                                )
                              : const Center(child: Icon(Icons.movie_outlined)),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xB3000000),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFF59E0B),
                              size: 14,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            color: Colors.black87,
                            padding: const EdgeInsets.all(4),
                            child: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],

        // 7. Shareable Stats Card Action
        OutlinedButton.icon(
          onPressed: () => _showShareableStatsCard(stats),
          icon: const Icon(Icons.share_rounded),
          label: const Text('Share Stats Summary Card'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildQuickProgressCard(BuildContext context, MediaItem item) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isManga = item.mediaType == MediaType.manga;
    final unitLabel = isManga ? 'ch' : 'ep';

    return Container(
      width: 220,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF263852) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 46,
              height: 64,
              child: item.coverUrl.isNotEmpty
                  ? Image.network(
                      item.coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.movie_outlined, size: 20),
                    )
                  : const Icon(Icons.movie_outlined, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.currentProgress} / ${item.totalCount != null ? '${item.totalCount}' : '?'} $unitLabel',
                  style: TextStyle(
                    fontFamily: 'Be Vietnam Pro',
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 26,
                  child: FilledButton.tonal(
                    onPressed: () {
                      widget.onIncrementProgress?.call(item.id);
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text('+1 $unitLabel', style: const TextStyle(fontSize: 10)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(
          color: isDark ? const Color(0xFF263852) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Be Vietnam Pro',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: 'Be Vietnam Pro',
              fontSize: 10,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption(
      String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  String _formatHours(double hours) {
    if (hours < 1.0) {
      return '${(hours * 60).round()} mins';
    }
    if (hours > 24) {
      final days = (hours / 24).floor();
      final remHours = (hours % 24).round();
      return '${days}d ${remHours}h spent';
    }
    return '${hours.toStringAsFixed(1)}h spent';
  }

  Color _getMediaTypeColor(MediaType type) {
    switch (type) {
      case MediaType.anime:
        return const Color(0xFF6366F1); // Indigo
      case MediaType.manga:
        return const Color(0xFFEC4899); // Pink
      case MediaType.series:
        return const Color(0xFF10B981); // Emerald
      case MediaType.movie:
        return const Color(0xFFF59E0B); // Amber
    }
  }

  Color _getStatusColor(TrackingStatus status) {
    switch (status) {
      case TrackingStatus.watching:
      case TrackingStatus.reading:
        return const Color(0xFF3B82F6); // Blue
      case TrackingStatus.completed:
        return const Color(0xFF10B981); // Green
      case TrackingStatus.planToWatch:
        return const Color(0xFF8B5CF6); // Violet
      case TrackingStatus.onHold:
        return const Color(0xFFF59E0B); // Amber
      case TrackingStatus.dropped:
        return const Color(0xFFEF4444); // Red
      case TrackingStatus.unknown:
        return Colors.grey;
    }
  }
}
