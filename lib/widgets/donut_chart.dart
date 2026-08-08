import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Data point for rendering segments in the Donut Chart.
class DonutDataPoint {
  final String label;
  final int count;
  final double percentage;
  final Color color;

  const DonutDataPoint({
    required this.label,
    required this.count,
    required this.percentage,
    required this.color,
  });
}

/// Custom animated Donut Chart widget built with [CustomPainter].
class DonutChart extends StatefulWidget {
  final List<DonutDataPoint> dataPoints;
  final String centerTitle;
  final String centerSubtitle;
  final double height;

  const DonutChart({
    super.key,
    required this.dataPoints,
    required this.centerTitle,
    required this.centerSubtitle,
    this.height = 180,
  });

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _sweepAnimation;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _sweepAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void didUpdateWidget(DonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataPoints != widget.dataPoints) {
      _animController.forward(from: 0.0);
      _selectedIndex = null;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (widget.dataPoints.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text(
            'No distribution data available',
            style: TextStyle(
              fontFamily: 'Be Vietnam Pro',
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final selectedPoint = (_selectedIndex != null &&
            _selectedIndex! < widget.dataPoints.length)
        ? widget.dataPoints[_selectedIndex!]
        : null;

    final displayTitle = selectedPoint != null
        ? '${selectedPoint.count}'
        : widget.centerTitle;
    final displaySubtitle = selectedPoint != null
        ? '${selectedPoint.label} (${selectedPoint.percentage.toStringAsFixed(1)}%)'
        : widget.centerSubtitle;

    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: AnimatedBuilder(
            animation: _sweepAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: _DonutChartPainter(
                  dataPoints: widget.dataPoints,
                  progress: _sweepAnimation.value,
                  selectedIndex: _selectedIndex,
                  trackColor: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFE2E8F0),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayTitle,
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: selectedPoint?.color ??
                              theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        displaySubtitle,
                        style: TextStyle(
                          fontFamily: 'Be Vietnam Pro',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        // Interactive Legend Wrap
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: List.generate(widget.dataPoints.length, (index) {
            final pt = widget.dataPoints[index];
            final isSelected = _selectedIndex == index;

            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() {
                  _selectedIndex = isSelected ? null : index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? pt.color.withValues(alpha: 0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? pt.color : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: pt.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${pt.label}: ',
                      style: TextStyle(
                        fontFamily: 'Be Vietnam Pro',
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '${pt.count} (${pt.percentage.toStringAsFixed(0)}%)',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: pt.color,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<DonutDataPoint> dataPoints;
  final double progress;
  final int? selectedIndex;
  final Color trackColor;

  _DonutChartPainter({
    required this.dataPoints,
    required this.progress,
    required this.selectedIndex,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = 16.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Draw background track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    final double totalCount = dataPoints
        .fold<double>(0, (sum, pt) => sum + pt.count)
        .clamp(1.0, double.infinity);

    double startAngle = -math.pi / 2;

    for (int i = 0; i < dataPoints.length; i++) {
      final pt = dataPoints[i];
      final sweepAngle =
          (pt.count / totalCount) * 2 * math.pi * progress.clamp(0.0, 1.0);
      final isSelected = selectedIndex == i;

      final paint = Paint()
        ..color = pt.color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = isSelected ? strokeWidth + 4 : strokeWidth;

      if (sweepAngle > 0.01) {
        // Draw gap
        final actualSweep = math.max(0.01, sweepAngle - 0.05);
        canvas.drawArc(rect, startAngle + 0.025, actualSweep, false, paint);
      }

      startAngle += (pt.count / totalCount) * 2 * math.pi * progress;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.dataPoints != dataPoints;
  }
}
