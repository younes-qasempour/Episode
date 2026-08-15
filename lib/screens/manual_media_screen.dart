import 'package:flutter/material.dart';

import '../layout/responsive_layout.dart';
import '../models/media_item.dart';
import '../widgets/season_editor_dialog.dart';

class ManualMediaScreen extends StatefulWidget {
  final ValueChanged<MediaItem>? onSave;

  const ManualMediaScreen({super.key, this.onSave});

  @override
  State<ManualMediaScreen> createState() => _ManualMediaScreenState();
}

class _ManualMediaScreenState extends State<ManualMediaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _coverController = TextEditingController();
  final _synopsisController = TextEditingController();
  final _progressController = TextEditingController(text: '0');
  final _totalController = TextEditingController();

  MediaType _mediaType = MediaType.anime;
  TrackingStatus _trackingStatus = TrackingStatus.planToWatch;
  ReleaseStatus _releaseStatus = ReleaseStatus.unknown;
  ProgressMode _progressMode = ProgressMode.flat;
  bool _knownTotal = false;
  double _rating = 0;
  List<MediaSeason> _seasons = [];
  late final String _draftId;

  @override
  void initState() {
    super.initState();
    _draftId = MediaItem.createManualId();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _coverController.dispose();
    _synopsisController.dispose();
    _progressController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  bool get _showsFlatProgress =>
      _mediaType.supportsProgress && _progressMode == ProgressMode.flat;

  String? _validateTitle(String? value) {
    return value == null || value.trim().isEmpty ? 'Title is required.' : null;
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

  Future<void> _editSeason([MediaSeason? existing]) async {
    final result = await showSeasonEditorDialog(
      context,
      mediaId: _draftId,
      existingSeasons: _seasons,
      season: existing,
    );
    if (result == null || !mounted) {
      return;
    }

    final item = MediaItem(
      id: _draftId,
      title: _titleController.text.trim(),
      coverUrl: _coverController.text.trim(),
      currentProgress: 0,
      totalCount: null,
      mediaType: _mediaType.storageValue,
      status: _trackingStatus.label,
      progressMode: ProgressMode.seasonal,
      seasons: _seasons,
      isManual: true,
    ).upsertSeason(result);
    setState(() => _seasons = item.seasons);
  }

  Future<void> _deleteSeason(MediaSeason season) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete season?'),
        content: Text(
          'Remove ${season.displayName} and its progress from this item?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
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

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final isMovie = _mediaType == MediaType.movie;
    final isSeasonal =
        _mediaType.supportsSeasons && _progressMode == ProgressMode.seasonal;
    final synopsis = _synopsisController.text.trim();
    final item = MediaItem(
      id: _draftId,
      title: _titleController.text.trim(),
      coverUrl: _coverController.text.trim(),
      currentProgress:
          isMovie || isSeasonal ? 0 : int.parse(_progressController.text),
      totalCount: isMovie || isSeasonal || !_knownTotal
          ? null
          : int.parse(_totalController.text),
      mediaType: _mediaType.storageValue,
      status: _trackingStatus.label,
      releaseStatus: _releaseStatus,
      progressMode: isSeasonal ? ProgressMode.seasonal : ProgressMode.flat,
      seasons: isSeasonal ? _seasons : const [],
      isManual: true,
      synopsis: synopsis.isEmpty ? null : synopsis,
      rating: _rating,
    );

    widget.onSave?.call(item);
    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add media manually'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
      body: ResponsiveBuilder(
        builder: (context, layout) => Form(
          key: _formKey,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: layout.maxWidthFor(ContentWidth.form),
              ),
              child: ListView(
                padding: EdgeInsets.all(layout.horizontalPadding),
                children: [
                  TextFormField(
                    key: const Key('manual-title-field'),
                    controller: _titleController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Title *',
                      hintText: 'Enter a title',
                    ),
                    validator: _validateTitle,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<MediaType>(
                    key: const Key('manual-media-type-field'),
                    initialValue: _mediaType,
                    decoration:
                        const InputDecoration(labelText: 'Media type *'),
                    items: MediaType.values
                        .map(
                          (type) => DropdownMenuItem(
                              value: type, child: Text(type.label)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _mediaType = value;
                        if (!value.supportsSeasons) {
                          _progressMode = ProgressMode.flat;
                        }
                        if (value == MediaType.manga &&
                            _trackingStatus == TrackingStatus.watching) {
                          _trackingStatus = TrackingStatus.reading;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _coverController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Cover image URL (optional)',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  if (_coverController.text.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 160,
                        child: Image.network(
                          _coverController.text.trim(),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            alignment: Alignment.center,
                            child: const Text('Cover preview unavailable'),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _synopsisController,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Synopsis or personal description (optional)',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<TrackingStatus>(
                    initialValue: _trackingStatus,
                    decoration:
                        const InputDecoration(labelText: 'Tracking status'),
                    items: TrackingStatus.values
                        .where((status) => status != TrackingStatus.unknown)
                        .map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(status.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _trackingStatus = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ReleaseStatus>(
                    initialValue: _releaseStatus,
                    decoration:
                        const InputDecoration(labelText: 'Release status'),
                    items: ReleaseStatus.values
                        .map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(status.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _releaseStatus = value);
                      }
                    },
                  ),
                  if (_mediaType.supportsSeasons) ...[
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
                            (mode) => ButtonSegment(
                                value: mode, label: Text(mode.label)),
                          )
                          .toList(),
                      selected: {_progressMode},
                      onSelectionChanged: (selection) {
                        setState(() => _progressMode = selection.first);
                      },
                    ),
                  ],
                  if (_showsFlatProgress) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('manual-progress-field'),
                      controller: _progressController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText:
                            'Current ${_mediaType == MediaType.manga ? 'chapters' : 'episodes'}',
                      ),
                      validator: (value) =>
                          _validateNonNegative(value, 'progress'),
                    ),
                    const SizedBox(height: 4),
                    SwitchListTile(
                      key: const Key('manual-known-total-switch'),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Total count is known'),
                      value: _knownTotal,
                      onChanged: (value) {
                        setState(() {
                          _knownTotal = value;
                          if (!value) {
                            _totalController.clear();
                          }
                        });
                      },
                    ),
                    if (_knownTotal)
                      TextFormField(
                        key: const Key('manual-total-field'),
                        controller: _totalController,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Total count'),
                        validator: (value) =>
                            _validateNonNegative(value, 'total'),
                      ),
                  ],
                  if (_mediaType.supportsProgress &&
                      _progressMode == ProgressMode.seasonal) ...[
                    const SizedBox(height: 16),
                    ..._seasons.where((s) => s.deletedAt == null).map(
                          (season) => Card(
                            child: ListTile(
                              title: Text(season.displayName),
                              subtitle: Text(
                                '${season.progressSummary} Ep · ${season.releaseStatus.label}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Edit ${season.displayName}',
                                    onPressed: () => _editSeason(season),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    tooltip: 'Delete ${season.displayName}',
                                    onPressed: () => _deleteSeason(season),
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    OutlinedButton.icon(
                      key: const Key('manual-add-season-button'),
                      onPressed: _editSeason,
                      icon: const Icon(Icons.add),
                      label: const Text('Add season'),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rating',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _rating == 0
                            ? 'Unrated'
                            : '${_rating.toStringAsFixed(1)} / 10',
                      ),
                    ],
                  ),
                  Slider(
                    value: _rating,
                    min: 0,
                    max: 10,
                    divisions: 20,
                    label: _rating.toStringAsFixed(1),
                    onChanged: (value) => setState(() => _rating = value),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    key: const Key('save-manual-media-button'),
                    onPressed: _save,
                    icon: const Icon(Icons.library_add_rounded),
                    label: const Text('Save to Library'),
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
