import 'package:flutter/material.dart';

/// Zero-dependency animated shimmer skeleton widget for loading states.
class ShimmerSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12.0,
  });

  @override
  State<ShimmerSkeleton> createState() => _ShimmerSkeletonState();
}

class _ShimmerSkeletonState extends State<ShimmerSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor =
        isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final highlightColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final double value = _animation.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(-1.5 + (value * 3.0), -0.3),
              end: Alignment(-0.5 + (value * 3.0), 0.3),
            ),
          ),
        );
      },
    );
  }
}

/// Grid of shimmer skeleton cards for search loading states.
class ShimmerSkeletonGrid extends StatelessWidget {
  final int itemCount;

  const ShimmerSkeletonGrid({
    super.key,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF263852)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          padding: const EdgeInsets.all(10),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ShimmerSkeleton(
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: 12,
                ),
              ),
              SizedBox(height: 10),
              ShimmerSkeleton(
                width: 120,
                height: 14,
                borderRadius: 4,
              ),
              SizedBox(height: 6),
              ShimmerSkeleton(
                width: 80,
                height: 12,
                borderRadius: 4,
              ),
            ],
          ),
        );
      },
    );
  }
}
