import 'package:flutter/material.dart';
import '../models/media_item.dart';
import '../theme/app_theme.dart';

class MediaDetailScreen extends StatefulWidget {
  final MediaItem item;
  final Function(MediaItem updatedItem)? onSave;
  final Function(String id)? onDelete;

  const MediaDetailScreen({
    super.key,
    required this.item,
    this.onSave,
    this.onDelete,
  });

  @override
  State<MediaDetailScreen> createState() => _MediaDetailScreenState();
}

class _MediaDetailScreenState extends State<MediaDetailScreen> {
  late String _status;
  late int _currentProgress;
  late int _totalCount;
  late double _rating;
  late TextEditingController _synopsisController;

  final List<String> _statusOptions = [
    'Watching',
    'Reading',
    'Plan to Watch',
    'Completed',
    'On Hold',
  ];

  @override
  void initState() {
    super.initState();
    _status = widget.item.status;
    _currentProgress = widget.item.currentProgress;
    _totalCount = widget.item.totalCount;
    _rating = widget.item.rating;
    _synopsisController = TextEditingController(text: widget.item.synopsis ?? '');
  }

  @override
  void dispose() {
    _synopsisController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    final updated = widget.item.copyWith(
      status: _status,
      currentProgress: _currentProgress,
      totalCount: _totalCount,
      rating: _rating,
      synopsis: _synopsisController.text.trim(),
    );

    if (widget.onSave != null) {
      widget.onSave!(updated);
    }

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Updated "${updated.title}"'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Media'),
        content: Text('Are you sure you want to remove "${widget.item.title}" from your library?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              if (widget.onDelete != null) {
                widget.onDelete!(widget.item.id);
              }
              Navigator.of(context).pop(); // Close detail screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Removed "${widget.item.title}" from library'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    IconData typeIcon;
    switch (widget.item.mediaType.toLowerCase()) {
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.item.title,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            onPressed: _confirmDelete,
            tooltip: 'Delete Media',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Media Header Card with Cover Image
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 110,
                    height: 160,
                    child: Image.network(
                      widget.item.coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: isDark ? const Color(0xFF1E2E44) : const Color(0xFFE0E7FF),
                        child: Icon(typeIcon, size: 40, color: theme.colorScheme.primary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type Chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(typeIcon, size: 13, color: theme.colorScheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              widget.item.mediaType.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        widget.item.title,
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        '${widget.item.unitLabel} Progress: $_currentProgress / $_totalCount',
                        style: TextStyle(
                          fontFamily: 'Be Vietnam Pro',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Section 1: Status Dropdown
            Text(
              'Status',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2E44) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF263852) : const Color(0xFFE2E8F0),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _statusOptions.contains(_status) ? _status : _statusOptions.first,
                  isExpanded: true,
                  items: _statusOptions.map((status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(
                        status,
                        style: const TextStyle(
                          fontFamily: 'Be Vietnam Pro',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (newStatus) {
                    if (newStatus != null) {
                      setState(() {
                        _status = newStatus;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Section 2: Progress Controls (Steppers & Counter)
            Text(
              'Progress (${widget.item.unitLabel}s)',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2E44) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF263852) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Completed Count:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline_rounded),
                            onPressed: _currentProgress > 0
                                ? () {
                                    setState(() {
                                      _currentProgress--;
                                    });
                                  }
                                : null,
                          ),
                          Text(
                            '$_currentProgress',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline_rounded),
                            onPressed: _currentProgress < _totalCount
                                ? () {
                                    setState(() {
                                      _currentProgress++;
                                      if (_currentProgress == _totalCount) {
                                        _status = 'Completed';
                                      }
                                    });
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _currentProgress.toDouble().clamp(0, _totalCount > 0 ? _totalCount.toDouble() : 1),
                    min: 0,
                    max: _totalCount > 0 ? _totalCount.toDouble() : 1,
                    divisions: _totalCount > 0 ? _totalCount : 1,
                    label: '$_currentProgress',
                    onChanged: (val) {
                      setState(() {
                        _currentProgress = val.round();
                        if (_currentProgress == _totalCount && _totalCount > 0) {
                          _status = 'Completed';
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 3: Score Rating (0.0 to 10.0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Score Rating',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  _rating > 0 ? '${_rating.toStringAsFixed(1)} / 10 ★' : 'Unrated',
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2E44) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF263852) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Slider(
                value: _rating.clamp(0.0, 10.0),
                min: 0.0,
                max: 10.0,
                divisions: 20,
                activeColor: Colors.amber,
                label: _rating.toStringAsFixed(1),
                onChanged: (val) {
                  setState(() {
                    _rating = val;
                  });
                },
              ),
            ),
            const SizedBox(height: 24),

            // Synopsis Section
            if (widget.item.synopsis != null && widget.item.synopsis!.isNotEmpty) ...[
              Text(
                'Synopsis',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.item.synopsis!,
                style: TextStyle(
                  fontFamily: 'Be Vietnam Pro',
                  fontSize: 13,
                  height: 1.5,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryIndigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _saveChanges,
                child: const Text(
                  'Save Changes',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
