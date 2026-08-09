import 'package:flutter/material.dart';
import '../models/activity_log_entry.dart';

/// 30-Day Contribution Heatmap Grid and Streak Counter.
class StreakHeatmap extends StatelessWidget {
  final List<ActivityLogEntry> activityLogs;
  final int days;

  const StreakHeatmap({
    super.key,
    required this.activityLogs,
    this.days = 28,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dailyMap = StreakCalculator.computeDailyActivity(activityLogs);
    final streak = StreakCalculator.calculateCurrentStreak(activityLogs);

    final today = DateTime.now();
    final startDate = today.subtract(Duration(days: days - 1));

    final dates = List.generate(days, (index) {
      return startDate.add(Duration(days: index));
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF263852) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Activity Streak',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      size: 16,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$streak Day Streak',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 28-Day Heatmap Grid (4 rows x 7 columns)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: days,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemBuilder: (context, index) {
              final date = dates[index];
              final dateKey = _dateKey(date);
              final count = dailyMap[dateKey] ?? 0;

              return Tooltip(
                message: '$dateKey: $count updates',
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: _getHeatmapColor(count, isDark),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155).withValues(alpha: 0.5)
                          : const Color(0xFFCBD5E1),
                      width: 0.5,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Less ',
                style: TextStyle(
                  fontFamily: 'Be Vietnam Pro',
                  fontSize: 10,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              _buildLegendBox(_getHeatmapColor(0, isDark)),
              const SizedBox(width: 4),
              _buildLegendBox(_getHeatmapColor(1, isDark)),
              const SizedBox(width: 4),
              _buildLegendBox(_getHeatmapColor(4, isDark)),
              const SizedBox(width: 4),
              _buildLegendBox(_getHeatmapColor(8, isDark)),
              Text(
                ' More',
                style: TextStyle(
                  fontFamily: 'Be Vietnam Pro',
                  fontSize: 10,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendBox(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Color _getHeatmapColor(int count, bool isDark) {
    if (count <= 0) {
      return isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    }
    if (count < 3) {
      return const Color(0xFF818CF8); // Soft Violet
    }
    if (count < 7) {
      return const Color(0xFF6366F1); // Medium Indigo
    }
    return const Color(0xFF4F46E5); // Deep Indigo
  }

  String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
