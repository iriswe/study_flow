import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'stats_provider.dart';
import '../../../core/theme/app_theme.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  String _selectedFilter = 'day'; // day, week, month

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(statsProvider.notifier).loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(statsProvider);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            color: AppTheme.bg,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('数据统计', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                Row(
                  children: [
                    _FilterTab('日', _selectedFilter == 'day', () => setState(() => _selectedFilter = 'day')),
                    const SizedBox(width: 8),
                    _FilterTab('周', _selectedFilter == 'week', () => setState(() => _selectedFilter = 'week')),
                    const SizedBox(width: 8),
                    _FilterTab('月', _selectedFilter == 'month', () => setState(() => _selectedFilter = 'month')),
                  ],
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(state),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(StatsState state) {
    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppTheme.danger),
            const SizedBox(height: 12),
            Text(state.error!, style: TextStyle(color: AppTheme.textSecondary)),
            TextButton(
              onPressed: () => ref.read(statsProvider.notifier).loadAll(),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 5 stat cards - matching prototype
          Row(
            children: [
              Expanded(child: _StatCard(value: '${((state.overview?.todayStudyDuration ?? 0) / 60).toStringAsFixed(1)}h', label: '今日学习', color: AppTheme.primary)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(value: '${state.overview?.consecutiveDays ?? 0}', label: '连续天数', color: AppTheme.accent)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(value: '${((state.overview?.completionRate ?? 0) * 100).toInt()}%', label: '任务完成率', color: AppTheme.success)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(value: '${(state.overview?.completedToday ?? 0)}', label: '今日完成', color: AppTheme.warning)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(value: '${state.overview?.todayReviews ?? 0}', label: '待复习', color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 20),
          // Charts
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Weekly chart
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('本周学习时长', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 180,
                        child: _buildBarChart(state),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Memory stability
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('记忆稳定性', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 20),
                      Center(
                        child: _buildMemoryStability(state),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Review stats chart
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('复习情况', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),
                SizedBox(
                  height: 180,
                  child: _buildReviewChart(state),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(StatsState state) {
    final dailyDuration = state.learningStats?['dailyDuration'] as Map<String, dynamic>? ?? {};
    final now = DateTime.now();
    final days = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

    // Build data for last 7 days (starting from Monday)
    List<double> hours = [];
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      String dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      int minutes = (dailyDuration[dateKey] as int?) ?? 0;
      hours.add(minutes / 60.0);
    }

    double maxHours = hours.reduce((a, b) => a > b ? a : b);
    if (maxHours < 1) maxHours = 5;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxHours,
        barGroups: hours.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value,
                color: AppTheme.primary,
                width: 24,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}h', style: TextStyle(fontSize: 10, color: AppTheme.textMuted));
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < days.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(days[value.toInt()], style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppTheme.border,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildReviewChart(StatsState state) {
    final pendingCount = (state.reviewStats?['pendingCount'] as int? ?? 0).toDouble();
    final reviewingCount = (state.reviewStats?['reviewingCount'] as int? ?? 0).toDouble();
    final masteredCount = (state.reviewStats?['masteredCount'] as int? ?? 0).toDouble();

    final data = [
      {'label': '待复习', 'count': pendingCount, 'color': AppTheme.danger},
      {'label': '进行中', 'count': reviewingCount, 'color': AppTheme.warning},
      {'label': '已掌握', 'count': masteredCount, 'color': AppTheme.success},
    ];

    double maxCount = [pendingCount, reviewingCount, masteredCount].reduce((a, b) => a > b ? a : b);
    if (maxCount < 1) maxCount = 10;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxCount,
        barGroups: data.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value['count'] as double,
                color: entry.value['color'] as Color,
                width: 40,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}', style: TextStyle(fontSize: 10, color: AppTheme.textMuted));
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < data.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      data[value.toInt()]['label'] as String,
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppTheme.border,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }
Widget _buildMemoryStability(StatsState state) {
    final totalCount = (state.reviewStats?['pendingCount'] as int? ?? 0) +
        (state.reviewStats?['reviewingCount'] as int? ?? 0) +
        (state.reviewStats?['masteredCount'] as int? ?? 0);

    int stabilityPercent = 0;
    if (totalCount > 0) {
      final mastered = state.reviewStats?['masteredCount'] as int? ?? 0;
      stabilityPercent = ((mastered / totalCount) * 100).round();
    }

    return Column(
      children: [
        Text(
          '$stabilityPercent%',
          style: TextStyle(fontSize: 44, fontWeight: FontWeight.w700, color: stabilityPercent >= 80 ? AppTheme.success : (stabilityPercent >= 50 ? AppTheme.warning : AppTheme.danger)),
        ),
        Center(
          child: Text('记忆稳定度', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendItem(color: AppTheme.success, label: '掌握 ${state.reviewStats?['masteredCount'] ?? 0}'),
            const SizedBox(width: 12),
            _LegendItem(color: AppTheme.warning, label: '进行 ${state.reviewStats?['reviewingCount'] ?? 0}'),
            const SizedBox(width: 12),
            _LegendItem(color: AppTheme.danger, label: '待复习 ${state.reviewStats?['pendingCount'] ?? 0}'),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatCard({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
        boxShadow: [AppTheme.shadowSm],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterTab(this.label, this.active, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: active ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ],
    );
  }
}