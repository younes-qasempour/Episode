import 'package:flutter/material.dart';

import '../models/media_item.dart';
import '../theme/app_theme.dart';
import '../widgets/season_editor_dialog.dart';

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
  final _formKey = GlobalKey<FormState>();
  late TrackingStatus _trackingStatus;
  late ReleaseStatus _releaseStatus;
  late ProgressMode _progressMode;
  late int _flatCurrentProgress;
  late int? _flatTotalCount;
  late bool _knownTotal;
  late List<MediaSeason> _seasons;
  late double _rating;
  late final TextEditingController _progressController;
  late final TextEditingController _totalController;
  late final TextEditingController _synopsisController;

  @override
  void initState() {
    super.initState();
    _trackingStatus = widget.item.trackingStatus;
    _releaseStatus = widget.item.releaseStatus;
    _progressMode = widget.item.supportsSeasons
        ? widget.item.progressMode
        : ProgressMode.flat;
    _flatCurrentProgress = widget.item.flatCurrentProgress;
    _flatTotalCount = widget.item.flatTotalCount;
    _knownTotal = _flatTotalCount != null;
    _seasons = List<MediaSeason>.from(widget.item.seasons);
    _rating = widget.item.rating;
    _progressController = TextEditingController(text: '$_flatCurrentProgress');
    _totalController = TextEditingController(
      text: _flatTotalCount?.toString() ?? '',
    );
    _synopsisController = TextEditingController(
      text: widget.item.synopsis ?? '',
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    _totalController.dispose();
    _synopsisController.dispose();
    super.dispose();
  }

  String? _validateNonNegative(String? value, String label) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null) {
      return 'Enter a $label.';
    }
    if (parsed < 0) {
      return '$label cannot be negative.';
    }
    return null;
  }

  MediaItem _workingItem() {
    final synopsis = _synopsisController.text.trim();
    return widget.item.copyWith(
      currentProgress: _flatCurrentProgress,
      totalCount: _flatTotalCount,
      clearTotalCount: !_knownTotal || _flatTotalCount == null,
      status: _trackingStatus.label,
      releaseStatus: _releaseStatus,
      progressMode: _progressMode,
      seasons: _seasons,
      rating: _rating,
      synopsis: synopsis,
      clearSynopsis: synopsis.isEmpty,
    );
  }

  void _saveChanges() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _flatCurrentProgress = int.tryParse(_progressController.text) ?? 0;
    _flatTotalCount = _knownTotal ? int.tryParse(_totalController.text) : null;
    final updated = _workingItem();

    widget.onSave?.call(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Updated "${updated.title}"'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.of(context).pop();
  }

  void _confirmDelete() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Media'),
        content: Text(
          'Are you sure you want to remove "${widget.item.title}" from your library?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDelete?.call(widget.item.id);
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _setFlatProgress(int value) {
    final nextValue = value < 0 ? 0 : value;
    setState(() {
      _flatCurrentProgress = nextValue;
      _progressController.text = '$nextValue';
    });
  }

  void _changeProgressMode(ProgressMode mode) {
    _flatCurrentProgress = int.tryParse(_progressController.text) ?? 0;
    _flatTotalCount = _knownTotal ? int.tryParse(_totalController.text) : null;
    final converted = _workingItem().convertedTo(mode);
    setState(() {
      _progressMode = converted.progressMode;
      _flatCurrentProgress = converted.flatCurrentProgress;
      _flatTotalCount = converted.flatTotalCount;
      _knownTotal = _flatTotalCount != null;
      _seasons = List<MediaSeason>.from(converted.seasons);
      _progressController.text = '$_flatCurrentProgress';
      _totalController.text = _flatTotalCount?.toString() ?? '';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mode == ProgressMode.seasonal
              ? 'Flat progress was preserved in Season 1.'
              : 'Season progress was copied into the flat total. Season data is retained.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _editSeason([MediaSeason? existing]) async {
    final result = await showSeasonEditorDialog(
      context,
      mediaId: widget.item.id,
      existingSeasons: _seasons,
      season: existing,
    );
    if (result == null || !mounted) {
      return;
    }
    final updated = _workingItem().upsertSeason(result);
    setState(() => _seasons = List<MediaSeason>.from(updated.seasons));
  }

  Future<void> _deleteSeason(MediaSeason season) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete season?'),
        content: Text('Remove ${season.displayName} and its saved progress?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() {
        _seasons = _seasons.where((item) => item.id != season.id).toList();
      });
    }
  }

  void _changeSeasonProgress(MediaSeason season, int delta) {
    final nextProgress = season.currentProgress + delta;
    final updated = season.copyWith(
      currentProgress: nextProgress < 0 ? 0 : nextProgress,
    );
    setState(() {
      _seasons = _seasons
          .map((item) => item.id == season.id ? updated : item)
          .toList();
    });
  }

  IconData get _typeIcon {
    switch (widget.item.type) {
      case MediaType.manga:
        return Icons.menu_book_rounded;
      case MediaType.series:
        return Icons.tv_rounded;
      case MediaType.movie:
        return Icons.local_movies_rounded;
      case MediaType.anime:
        return Icons.movie_filter_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final workingItem = _workingItem();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item.title, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.redAccent,
            ),
            onPressed: _confirmDelete,
            tooltip: 'Delete Media',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildHeader(theme, isDark, workingItem),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            _buildDropdownSection<TrackingStatus>(
              context,
              title: 'Tracking status',
              value: _trackingStatus,
              values: TrackingStatus.values,
              labelFor: (status) => status.label,
              onChanged: (value) => setState(() => _trackingStatus = value),
            ),
            const SizedBox(height: 20),
            _buildDropdownSection<ReleaseStatus>(
              context,
              title: 'Release status',
              value: _releaseStatus,
              values: ReleaseStatus.values,
              labelFor: (status) => status.label,
              onChanged: (value) => setState(() => _releaseStatus = value),
            ),
            if (widget.item.supportsSeasons) ...[
              const SizedBox(height: 24),
              Text(
                'Progress tracking',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<ProgressMode>(
                segments: ProgressMode.values
                    .map(
                      (mode) =>
                          ButtonSegment(value: mode, label: Text(mode.label)),
                    )
                    .toList(),
                selected: {_progressMode},
                onSelectionChanged: (selection) {
                  _changeProgressMode(selection.first);
                },
              ),
            ],
            if (widget.item.supportsProgress &&
                _progressMode == ProgressMode.flat) ...[
              const SizedBox(height: 24),
              _buildFlatProgress(theme, isDark),
            ],
            if (widget.item.supportsProgress &&
                _progressMode == ProgressMode.seasonal) ...[
              const SizedBox(height: 24),
              _buildSeasonProgress(theme),
            ],
            if (widget.item.type == MediaType.movie) ...[
              const SizedBox(height: 24),
              _buildInfoPanel(
                context,
                icon: Icons.movie_outlined,
                text:
                    'Movies use tracking status and rating without an episode counter.',
              ),
            ],
            const SizedBox(height: 24),
            _buildRating(theme, isDark),
            const SizedBox(height: 24),
            Text(
              'Synopsis or personal description',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _synopsisController,
              minLines: 3,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: 'Add notes or a synopsis',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('save-media-details-button'),
              onPressed: _saveChanges,
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark, MediaItem workingItem) {
    final progressText = widget.item.type == MediaType.movie
        ? workingItem.releaseStatus.label
        : '${workingItem.progressSummary} ${workingItem.unitLabel}';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 110,
            height: 160,
            child: widget.item.coverUrl.trim().isEmpty
                ? _coverFallback(theme, isDark)
                : Image.network(
                    widget.item.coverUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _coverFallback(theme, isDark),
                  ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_typeIcon, size: 13, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      widget.item.type.label.toUpperCase(),
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
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                progressText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: workingItem.isBeyondKnownTotal
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (workingItem.isBeyondKnownTotal) ...[
                const SizedBox(height: 6),
                Text(
                  'Progress is beyond the saved total. You can update or clear the total below.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _coverFallback(ThemeData theme, bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF1E2E44) : const Color(0xFFE0E7FF),
      child: Icon(_typeIcon, size: 40, color: theme.colorScheme.primary),
    );
  }

  Widget _buildDropdownSection<T>(
    BuildContext context, {
    required String title,
    required T value,
    required List<T> values,
    required String Function(T value) labelFor,
    required ValueChanged<T> onChanged,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          initialValue: value,
          items: values
              .map(
                (item) =>
                    DropdownMenuItem(value: item, child: Text(labelFor(item))),
              )
              .toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
        ),
      ],
    );
  }

  Widget _buildFlatProgress(ThemeData theme, bool isDark) {
    final total = _knownTotal ? int.tryParse(_totalController.text) : null;
    final beyondTotal = total != null && _flatCurrentProgress > total;
    return _sectionCard(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress (${widget.item.unitLabel})',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                tooltip: 'Decrease progress',
                onPressed: _flatCurrentProgress > 0
                    ? () => _setFlatProgress(_flatCurrentProgress - 1)
                    : null,
                icon: const Icon(Icons.remove_circle_outline_rounded),
              ),
              Expanded(
                child: TextFormField(
                  key: const Key('detail-progress-field'),
                  controller: _progressController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Current progress',
                  ),
                  validator: (value) => _validateNonNegative(value, 'progress'),
                  onChanged: (value) {
                    setState(() {
                      _flatCurrentProgress = int.tryParse(value) ?? 0;
                    });
                  },
                ),
              ),
              IconButton(
                key: const Key('detail-increment-progress-button'),
                tooltip: 'Increase progress',
                onPressed: () => _setFlatProgress(_flatCurrentProgress + 1),
                icon: const Icon(Icons.add_circle_outline_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            key: const Key('detail-known-total-switch'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Total count is known'),
            value: _knownTotal,
            onChanged: (value) {
              setState(() {
                _knownTotal = value;
                if (!value) {
                  _flatTotalCount = null;
                  _totalController.clear();
                }
              });
            },
          ),
          if (_knownTotal)
            TextFormField(
              key: const Key('detail-total-field'),
              controller: _totalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Total count'),
              validator: (value) => _validateNonNegative(value, 'total'),
              onChanged: (value) {
                setState(() {
                  _flatTotalCount = int.tryParse(value);
                });
              },
            ),
          if (beyondTotal) ...[
            const SizedBox(height: 12),
            Text(
              'Progress exceeds the current total. It will be saved as entered.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSeasonProgress(ThemeData theme) {
    final aggregate = _workingItem();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Seasons',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${aggregate.progressSummary} Ep total',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_seasons.isEmpty)
          _buildInfoPanel(
            context,
            icon: Icons.video_library_outlined,
            text: 'No seasons yet. Add one when you are ready to track it.',
          ),
        ..._seasons.map(
          (season) => Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                title: Text(season.displayName),
                subtitle: Text(
                  '${season.progressSummary} Ep · ${season.releaseStatus.label}'
                  '${season.isBeyondKnownTotal ? ' · Beyond saved total' : ''}',
                ),
                trailing: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Decrease ${season.displayName}',
                      onPressed: season.currentProgress > 0
                          ? () => _changeSeasonProgress(season, -1)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    IconButton(
                      tooltip: 'Increase ${season.displayName}',
                      onPressed: () => _changeSeasonProgress(season, 1),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Season actions',
                      onSelected: (value) {
                        if (value == 'edit') {
                          _editSeason(season);
                        } else if (value == 'delete') {
                          _deleteSeason(season);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const Key('detail-add-season-button'),
          onPressed: _editSeason,
          icon: const Icon(Icons.add),
          label: const Text('Add season'),
        ),
      ],
    );
  }

  Widget _buildRating(ThemeData theme, bool isDark) {
    return _sectionCard(
      isDark,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Score rating',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                _rating > 0
                    ? '${_rating.toStringAsFixed(1)} / 10 ★'
                    : 'Unrated',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          Slider(
            value: _rating.clamp(0.0, 10.0),
            min: 0,
            max: 10,
            divisions: 20,
            label: _rating.toStringAsFixed(1),
            onChanged: (value) => setState(() => _rating = value),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(bool isDark, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2E44) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF263852) : const Color(0xFFE2E8F0),
        ),
      ),
      child: child,
    );
  }

  Widget _buildInfoPanel(
    BuildContext context, {
    required IconData icon,
    required String text,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
