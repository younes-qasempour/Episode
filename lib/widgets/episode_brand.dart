import 'package:flutter/material.dart';

/// The canonical Episode mark and optional wordmark used across app surfaces.
class EpisodeBrand extends StatelessWidget {
  static const String assetPath = 'assets/branding/episode_mark.png';

  final double markSize;
  final bool showName;
  final TextStyle? textStyle;
  final double spacing;

  const EpisodeBrand({
    super.key,
    this.markSize = 36,
    this.showName = true,
    this.textStyle,
    this.spacing = 10,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedTextStyle = textStyle ??
        Theme.of(context).textTheme.titleLarge?.copyWith(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: Theme.of(context).colorScheme.onSurface,
            );

    return Semantics(
      label: 'Episode',
      image: !showName,
      container: true,
      child: ExcludeSemantics(
        child: Row(
          key: const Key('episode-brand'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              assetPath,
              width: markSize,
              height: markSize,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.play_circle_fill_rounded,
                size: markSize,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            if (showName) ...[
              SizedBox(width: spacing),
              Text('Episode', style: resolvedTextStyle),
            ],
          ],
        ),
      ),
    );
  }
}
