import 'package:flutter/material.dart';
import '../models/media_item.dart';
import '../theme/app_theme.dart';

class MediaCard extends StatelessWidget {
  final MediaItem item;
  final VoidCallback? onIncrementProgress;
  final ValueChanged<int>? onBatchIncrementProgress;
  final VoidCallback? onTap;
  final VoidCallback? onToggleFavorite;

  const MediaCard({
    super.key,
    required this.item,
    this.onIncrementProgress,
    this.onBatchIncrementProgress,
    this.onTap,
    this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final trackingStatusLabel = item.trackingStatus.label;
    final statusColor = AppTheme.getStatusColor(trackingStatusLabel, isDark);
    final cardSeason = item.cardSeason;
    final incrementSeason = item.defaultIncrementSeason;
    final isSeasonBeyondTotal = cardSeason?.isBeyondKnownTotal ?? false;
    final canIncrement = onIncrementProgress != null &&
        item.supportsProgress &&
        (item.progressMode == ProgressMode.flat || incrementSeason != null);
    final String progressText;
    if (item.type == MediaType.movie) {
      progressText = '${item.releaseStatus.label} release';
    } else if (item.currentProgress > 0) {
      if (item.progressMode == ProgressMode.seasonal) {
        progressText = cardSeason == null
            ? 'No seasons added'
            : '${cardSeason.displayName} · ${cardSeason.progressSummary} Ep';
      } else {
        progressText = '${item.progressSummary} ${item.unitLabel}';
      }
    } else {
      if (item.progressMode == ProgressMode.seasonal &&
          item.seasons.isNotEmpty) {
        final totalEps = item.hasKnownTotal ? ' · ${item.totalCount} Ep' : '';
        progressText = '${item.seasons.length} Seasons$totalEps';
      } else if (item.hasKnownTotal) {
        progressText =
            '${item.totalCount} ${item.unitLabel == 'Ch' ? 'chapters' : 'episodes'}';
      } else {
        switch (item.releaseStatus) {
          case ReleaseStatus.ongoing:
            progressText =
                'Ongoing · ${item.unitLabel == 'Ch' ? 'Publishing' : 'Airing'}';
            break;
          case ReleaseStatus.upcoming:
            progressText = 'Upcoming';
            break;
          case ReleaseStatus.finished:
            progressText = 'Finished';
            break;
          case ReleaseStatus.hiatus:
            progressText = 'On Hiatus';
            break;
          case ReleaseStatus.cancelled:
            progressText = 'Cancelled';
            break;
          default:
            progressText = 'Ongoing';
            break;
        }
      }
    }

    IconData typeIcon;
    switch (item.mediaType.toLowerCase()) {
      case 'manga':
        typeIcon = Icons.menu_book_rounded;
        break;
      case 'series':
        typeIcon = Icons.tv_rounded;
        break;
      case 'movie':
        typeIcon = Icons.local_movies_rounded;
        break;
      case 'anime':
      default:
        typeIcon = Icons.movie_filter_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
                  color: AppTheme.primaryIndigo.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Media Cover Image
                Hero(
                  tag: 'media_cover_${item.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 84,
                      height: 116,
                    child: item.coverUrl.trim().isEmpty
                        ? Container(
                            color: isDark
                                ? const Color(0xFF1E2E44)
                                : const Color(0xFFE0E7FF),
                            child: Icon(
                              typeIcon,
                              size: 32,
                              color: theme.colorScheme.primary,
                            ),
                          )
                        : Image.network(
                            item.coverUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: isDark
                                    ? const Color(0xFF1E2E44)
                                    : const Color(0xFFE0E7FF),
                                child: Icon(
                                  typeIcon,
                                  size: 32,
                                  color: theme.colorScheme.primary,
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) {
                                return child;
                              }
                              return Container(
                                color: isDark
                                    ? const Color(0xFF1E2E44)
                                    : const Color(0xFFE0E7FF),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Card Details Column
                Expanded(
                  child: SizedBox(
                    height: 116,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Title & Type/Status Row
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        // Media Type Chip
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary
                                                .withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                typeIcon,
                                                size: 12,
                                                color:
                                                    theme.colorScheme.primary,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                item.mediaType.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color:
                                                      theme.colorScheme.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 6),

                                        // Status Badge Pill
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(
                                              alpha: 0.14,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              AppTheme.chipRadius,
                                            ),
                                          ),
                                          child: Text(
                                            trackingStatusLabel,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: statusColor,
                                            ),
                                          ),
                                        ),

                                        if (item.rating > 0) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.withValues(
                                                alpha: 0.15,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.star_rounded,
                                                  size: 12,
                                                  color: Colors.amber,
                                                ),
                                                const SizedBox(width: 2),
                                                Text(
                                                  item.rating
                                                      .toStringAsFixed(1),
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w800,
                                                    color: Colors.amber,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                                if (onToggleFavorite != null ||
                                    item.isFavorite) ...[
                                  IconButton(
                                    icon: Icon(
                                      item.isFavorite
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_border_rounded,
                                      color: item.isFavorite
                                          ? Colors.redAccent
                                          : theme.colorScheme.onSurfaceVariant
                                              .withValues(alpha: 0.5),
                                      size: 18,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 28,
                                      minHeight: 28,
                                    ),
                                    onPressed: onToggleFavorite,
                                    tooltip: item.isFavorite
                                        ? 'Remove from favorites'
                                        : 'Add to favorites',
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),

                        // Progress Section Row
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  progressText,
                                  style: TextStyle(
                                    fontFamily: 'Be Vietnam Pro',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: item.isBeyondKnownTotal ||
                                            isSeasonBeyondTotal
                                        ? theme.colorScheme.error
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                if (canIncrement)
                                  _PlusOneButton(
                                    onPressed: onIncrementProgress!,
                                    tooltip: item.progressMode ==
                                            ProgressMode.seasonal
                                        ? 'Add 1 episode to ${incrementSeason!.displayName}'
                                        : 'Add 1 ${item.unitLabel == 'Ch' ? 'chapter' : 'episode'}',
                                  ),
                              ],
                            ),
                            if (item.type != MediaType.movie) ...[
                              const SizedBox(height: 6),

                              // Progress Bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: item.hasKnownTotal
                                      ? item.progressPercentage
                                      : 0,
                                  minHeight: 6,
                                  backgroundColor: isDark
                                      ? const Color(0xFF263852)
                                      : const Color(0xFFE2E8F0),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    item.trackingStatus ==
                                            TrackingStatus.completed
                                        ? const Color(0xFF10B981)
                                        : theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlusOneButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String tooltip;

  const _PlusOneButton({required this.onPressed, required this.tooltip});

  @override
  State<_PlusOneButton> createState() => _PlusOneButtonState();
}

class _PlusOneButtonState extends State<_PlusOneButton> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    setState(() => _scale = 0.85);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0);
    widget.onPressed();
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: widget.tooltip,
      child: Semantics(
        button: true,
        label: widget.tooltip,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          child: AnimatedScale(
            scale: _scale,
            duration: const Duration(milliseconds: 100),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 14, color: Colors.white),
                  SizedBox(width: 2),
                  Text(
                    '+1',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
