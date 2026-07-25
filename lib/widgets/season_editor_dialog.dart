import 'package:flutter/material.dart';

import '../models/media_item.dart';

Future<MediaSeason?> showSeasonEditorDialog(
  BuildContext context, {
  required String mediaId,
  required List<MediaSeason> existingSeasons,
  MediaSeason? season,
}) {
  return showDialog<MediaSeason>(
    context: context,
    builder: (context) => _SeasonEditorDialog(
      mediaId: mediaId,
      existingSeasons: existingSeasons,
      season: season,
    ),
  );
}

class _SeasonEditorDialog extends StatefulWidget {
  final String mediaId;
  final List<MediaSeason> existingSeasons;
  final MediaSeason? season;

  const _SeasonEditorDialog({
    required this.mediaId,
    required this.existingSeasons,
    this.season,
  });

  @override
  State<_SeasonEditorDialog> createState() => _SeasonEditorDialogState();
}

class _SeasonEditorDialogState extends State<_SeasonEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _numberController;
  late final TextEditingController _titleController;
  late final TextEditingController _progressController;
  late final TextEditingController _totalController;
  late bool _knownTotal;
  late ReleaseStatus _releaseStatus;

  @override
  void initState() {
    super.initState();
    final season = widget.season;
    final suggestedNumber =
        season?.seasonNumber ??
        widget.existingSeasons.fold<int>(
              0,
              (highest, item) =>
                  item.seasonNumber > highest ? item.seasonNumber : highest,
            ) +
            1;
    _numberController = TextEditingController(text: '$suggestedNumber');
    _titleController = TextEditingController(text: season?.title ?? '');
    _progressController = TextEditingController(
      text: '${season?.currentProgress ?? 0}',
    );
    _totalController = TextEditingController(
      text: season?.totalCount?.toString() ?? '',
    );
    _knownTotal = season?.hasKnownTotal ?? false;
    _releaseStatus = season?.releaseStatus ?? ReleaseStatus.unknown;
  }

  @override
  void dispose() {
    _numberController.dispose();
    _titleController.dispose();
    _progressController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  String? _validateSeasonNumber(String? value) {
    final number = int.tryParse(value?.trim() ?? '');
    if (number == null || number < 1) {
      return 'Enter a positive season number.';
    }
    final duplicate = widget.existingSeasons.any(
      (existing) =>
          existing.id != widget.season?.id && existing.seasonNumber == number,
    );
    return duplicate ? 'Season $number already exists.' : null;
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

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final number = int.parse(_numberController.text.trim());
    final title = _titleController.text.trim();
    Navigator.of(context).pop(
      MediaSeason(
        id:
            widget.season?.id ??
            MediaItem.createSeasonId(widget.mediaId, number),
        seasonNumber: number,
        title: title.isEmpty ? null : title,
        currentProgress: int.parse(_progressController.text.trim()),
        totalCount: _knownTotal
            ? int.parse(_totalController.text.trim())
            : null,
        releaseStatus: _releaseStatus,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.season == null ? 'Add season' : 'Edit season'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  key: const Key('season-number-field'),
                  controller: _numberController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Season number'),
                  validator: _validateSeasonNumber,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('season-title-field'),
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Custom name (optional)',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('season-progress-field'),
                  controller: _progressController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Watched episodes',
                  ),
                  validator: (value) => _validateNonNegative(value, 'progress'),
                ),
                const SizedBox(height: 4),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Total episode count is known'),
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
                    key: const Key('season-total-field'),
                    controller: _totalController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Total episodes',
                    ),
                    validator: (value) => _validateNonNegative(value, 'total'),
                  ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ReleaseStatus>(
                  initialValue: _releaseStatus,
                  decoration: const InputDecoration(
                    labelText: 'Season release status',
                  ),
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
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('save-season-button'),
          onPressed: _submit,
          child: Text(widget.season == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}
