import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../state/auth_store.dart';
import '../../state/catalog_store.dart';
import '../../state/org_store.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/radii.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import 'portal_widgets.dart';

/// Employer analytics (Innovation): completion mix, progress by course and
/// weekly learning activity, all drawn from live enrolments.
class EmployerReportsScreen extends StatelessWidget {
  const EmployerReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final org = context.watch<AuthStore>().currentOrganisation;
    final store = context.watch<OrgStore>();
    final catalog = context.watch<CatalogStore>();
    if (org == null) return const SizedBox.shrink();

    final assignments = store.assignments(org.id);
    if (assignments.isEmpty) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PortalHeader(title: 'Analytics'),
          EmptyState(
            title: 'Nothing to chart yet',
            message: 'Assign a course to your team and their progress will appear here.',
          ),
        ],
      );
    }

    final summaries = store.courseSummaries(org.id)
      ..sort((a, b) => b.averageProgress.compareTo(a.averageProgress));
    final weekly = store.weeklyActivity(org.id);

    final charts = [
      _ChartCard(
        title: 'Completion status',
        subtitle: '${assignments.length} course assignments',
        child: _StatusDonut(
          complete: store.countWith(org.id, ProgressStatus.complete),
          inProgress: store.countWith(org.id, ProgressStatus.inProgress),
          notStarted: store.countWith(org.id, ProgressStatus.notStarted),
        ),
      ),
      _ChartCard(
        title: 'Average progress by course',
        subtitle: 'Share of lessons completed',
        child: _ProgressBars(
          labels: [
            for (final s in summaries)
              catalog.courseById(s.courseId)?.title ?? s.courseId,
          ],
          values: [for (final s in summaries) s.averageProgress],
        ),
      ),
      _ChartCard(
        title: 'Learning activity',
        subtitle: 'Assignments worked on, per week (last 6 weeks)',
        child: _ActivityLine(counts: weekly),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PortalHeader(
          title: 'Analytics',
          subtitle: '${org.name}: how your team is growing.',
        ),
        PortalGrid(
          children: [
            StatTile(
              value: '${(store.averageProgress(org.id) * 100).round()}%',
              label: 'Average progress',
            ),
            StatTile(
              value: '${store.completedCount(org.id)}',
              label: 'Courses completed',
            ),
            StatTile(
              value: '${store.employeeCount(org.id)}',
              label: 'Employees',
            ),
            StatTile(
              value: '${org.seats.values.fold(0, (a, b) => a + b)}',
              label: 'Unassigned seats',
            ),
          ],
        ),
        const SizedBox(height: Space.xl),
        PortalGrid(
          compactColumns: 1,
          mediumColumns: 1,
          expandedColumns: 2,
          children: charts,
        ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PortalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.h4),
          Text(subtitle, style: AppText.small),
          const SizedBox(height: Space.lg),
          SizedBox(height: 240, child: child),
        ],
      ),
    );
  }
}

class _StatusDonut extends StatefulWidget {
  const _StatusDonut({
    required this.complete,
    required this.inProgress,
    required this.notStarted,
  });

  final int complete;
  final int inProgress;
  final int notStarted;

  @override
  State<_StatusDonut> createState() => _StatusDonutState();
}

class _StatusDonutState extends State<_StatusDonut> {
  int? _touched;

  @override
  Widget build(BuildContext context) {
    final slices = [
      (ProgressStatus.complete.label, widget.complete, AppColors.success),
      (ProgressStatus.inProgress.label, widget.inProgress, AppColors.red),
      (ProgressStatus.notStarted.label, widget.notStarted, AppColors.grey300),
    ];
    final total = slices.fold(0, (a, s) => a + s.$2);
    final donut = PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 56,
        pieTouchData: PieTouchData(
          touchCallback: (event, response) => setState(
            () => _touched = event.isInterestedForInteractions
                ? response?.touchedSection?.touchedSectionIndex
                : null,
          ),
        ),
        sections: [
          for (var i = 0; i < slices.length; i++)
            if (slices[i].$2 > 0)
              PieChartSectionData(
                value: slices[i].$2.toDouble(),
                color: slices[i].$3,
                radius: _touched == i ? 34 : 28,
                title: _touched == i ? '${slices[i].$2}' : '',
                titleStyle: AppText.label.copyWith(color: Colors.white),
              ),
        ],
      ),
    );
    final legend = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final s in slices)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.xxs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: s.$3,
                    borderRadius: Radii.smallAll,
                  ),
                ),
                const SizedBox(width: Space.xs),
                Text(
                  '${s.$1}  ${s.$2} (${total == 0 ? 0 : (s.$2 * 100 / total).round()}%)',
                  style: AppText.small.copyWith(color: AppColors.ink),
                ),
              ],
            ),
          ),
      ],
    );
    return Row(
      children: [
        Expanded(child: donut),
        const SizedBox(width: Space.md),
        legend,
      ],
    );
  }
}

class _ProgressBars extends StatelessWidget {
  const _ProgressBars({required this.labels, required this.values});

  final List<String> labels;
  final List<double> values;

  String _short(String s) => s.length > 14 ? '${s.substring(0, 13)}…' : s;

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        maxY: 100,
        minY: 0,
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: AppColors.line, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.inverseSurface,
            getTooltipItem: (group, _, rod, _) => BarTooltipItem(
              '${labels[group.x]}\n${rod.toY.round()}%',
              AppText.small.copyWith(color: AppColors.onInverse),
            ),
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 25,
              reservedSize: 36,
              getTitlesWidget: (v, _) => Text('${v.round()}%', style: AppText.small),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: !context.isCompact,
              reservedSize: 32,
              getTitlesWidget: (v, _) => Padding(
                padding: const EdgeInsets.only(top: Space.xs),
                child: Text(_short(labels[v.toInt()]), style: AppText.small),
              ),
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < values.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i] * 100,
                  width: 22,
                  color: AppColors.red,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ActivityLine extends StatelessWidget {
  const _ActivityLine({required this.counts});

  final List<int> counts;

  @override
  Widget build(BuildContext context) {
    final maxY = (counts.fold(0, (a, b) => a > b ? a : b) + 1).toDouble();
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: AppColors.line, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.inverseSurface,
            getTooltipItems: (spots) => [
              for (final s in spots)
                LineTooltipItem(
                  '${s.y.round()} active',
                  AppText.small.copyWith(color: AppColors.onInverse),
                ),
            ],
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 28,
              getTitlesWidget: (v, _) => Text('${v.round()}', style: AppText.small),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 28,
              getTitlesWidget: (v, _) {
                final weeksAgo = counts.length - 1 - v.toInt();
                return Padding(
                  padding: const EdgeInsets.only(top: Space.xs),
                  child: Text(
                    weeksAgo == 0 ? 'This wk' : '-${weeksAgo}w',
                    style: AppText.small,
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < counts.length; i++)
                FlSpot(i.toDouble(), counts[i].toDouble()),
            ],
            isCurved: true,
            preventCurveOverShooting: true,
            color: AppColors.red,
            barWidth: 2,
            dotData: FlDotData(
              getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                radius: 4,
                color: AppColors.red,
                strokeWidth: 2,
                strokeColor: AppColors.surface,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.red.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }
}
