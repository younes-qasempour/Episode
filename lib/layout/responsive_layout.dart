import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

enum LayoutBreakpoint { compact, medium, expanded, large }

enum ContentWidth { form, focused, detail, standard, dashboard }

class ResponsiveBreakpoints {
  static const double medium = 600;
  static const double expanded = 1024;
  static const double large = 1440;

  const ResponsiveBreakpoints._();
}

class ResponsiveGridSpec {
  final int columns;
  final double itemWidth;
  final double mainAxisExtent;
  final double spacing;

  const ResponsiveGridSpec({
    required this.columns,
    required this.itemWidth,
    required this.mainAxisExtent,
    required this.spacing,
  });

  SliverGridDelegate get delegate => SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisExtent: mainAxisExtent,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      );
}

@immutable
class ResponsiveLayoutInfo {
  final double width;
  final LayoutBreakpoint breakpoint;

  const ResponsiveLayoutInfo._({
    required this.width,
    required this.breakpoint,
  });

  factory ResponsiveLayoutInfo.fromWidth(double width) {
    final breakpoint = switch (width) {
      < ResponsiveBreakpoints.medium => LayoutBreakpoint.compact,
      < ResponsiveBreakpoints.expanded => LayoutBreakpoint.medium,
      < ResponsiveBreakpoints.large => LayoutBreakpoint.expanded,
      _ => LayoutBreakpoint.large,
    };
    return ResponsiveLayoutInfo._(width: width, breakpoint: breakpoint);
  }

  bool get isCompact => breakpoint == LayoutBreakpoint.compact;
  bool get isMedium => breakpoint == LayoutBreakpoint.medium;
  bool get isExpanded =>
      breakpoint == LayoutBreakpoint.expanded ||
      breakpoint == LayoutBreakpoint.large;
  bool get isLarge => breakpoint == LayoutBreakpoint.large;
  bool get usesNavigationRail => !isCompact;
  bool get usesExtendedNavigationRail => isExpanded;
  bool get usesTwoPaneLayout => isExpanded;

  double get horizontalPadding => switch (breakpoint) {
        LayoutBreakpoint.compact => 16,
        LayoutBreakpoint.medium => 24,
        LayoutBreakpoint.expanded => 32,
        LayoutBreakpoint.large => 40,
      };

  double maxWidthFor(ContentWidth contentWidth) => switch (contentWidth) {
        ContentWidth.form => 640,
        ContentWidth.focused => 900,
        ContentWidth.detail => 1200,
        ContentWidth.standard => 1320,
        ContentWidth.dashboard => 1480,
      };

  int columnsFor({
    required double availableWidth,
    required double minItemWidth,
    int minColumns = 1,
    int maxColumns = 6,
    double spacing = 16,
  }) {
    final count =
        ((availableWidth + spacing) / (minItemWidth + spacing)).floor();
    return count.clamp(minColumns, maxColumns);
  }

  ResponsiveGridSpec mediaGrid({
    double? availableWidth,
    double maxContentWidth = 1480,
  }) {
    final pageWidth = math.min(availableWidth ?? width, maxContentWidth);
    final usableWidth = math.max(0.0, pageWidth - horizontalPadding * 2);
    final spacing = isCompact ? 12.0 : 16.0;
    final minItemWidth = switch (breakpoint) {
      LayoutBreakpoint.compact => 145.0,
      LayoutBreakpoint.medium => 170.0,
      LayoutBreakpoint.expanded => 190.0,
      LayoutBreakpoint.large => 200.0,
    };
    final columns = columnsFor(
      availableWidth: usableWidth,
      minItemWidth: minItemWidth,
      minColumns: 2,
      maxColumns: isLarge ? 7 : 6,
      spacing: spacing,
    );
    final itemWidth = (usableWidth - spacing * (columns - 1)) / columns;
    return ResponsiveGridSpec(
      columns: columns,
      itemWidth: itemWidth,
      mainAxisExtent: itemWidth * 1.5 + 88,
      spacing: spacing,
    );
  }

  static ResponsiveLayoutInfo of(BuildContext context) {
    final scoped =
        context.dependOnInheritedWidgetOfExactType<_ResponsiveLayoutScope>();
    return scoped?.layout ??
        ResponsiveLayoutInfo.fromWidth(MediaQuery.sizeOf(context).width);
  }
}

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ResponsiveLayoutInfo layout)
      builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final layout = ResponsiveLayoutInfo.fromWidth(width);
        return _ResponsiveLayoutScope(
          layout: layout,
          child: builder(context, layout),
        );
      },
    );
  }
}

class PageContentConstraint extends StatelessWidget {
  final Widget child;
  final ContentWidth contentWidth;
  final EdgeInsets? padding;
  final Alignment alignment;

  const PageContentConstraint({
    super.key,
    required this.child,
    this.contentWidth = ContentWidth.standard,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, layout) {
        return Align(
          alignment: alignment,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: layout.maxWidthFor(contentWidth),
            ),
            child: Padding(
              padding: padding ??
                  EdgeInsets.symmetric(horizontal: layout.horizontalPadding),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        ...super.dragDevices,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

class _ResponsiveLayoutScope extends InheritedWidget {
  final ResponsiveLayoutInfo layout;

  const _ResponsiveLayoutScope({required this.layout, required super.child});

  @override
  bool updateShouldNotify(_ResponsiveLayoutScope oldWidget) {
    return layout.width != oldWidget.layout.width ||
        layout.breakpoint != oldWidget.layout.breakpoint;
  }
}
