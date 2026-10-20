import 'package:fl_chart/fl_chart.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';

import '../../assistant/assistant_engine.dart' hide Intent;
import '../../router/routes.dart';
import '../../theme/colors.dart';
import '../../theme/radii.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../common/app_icon.dart';
import '../common/course_thumb.dart';

/// What the chat panel lets an answer do.
class BlockActions {
  const BlockActions({required this.ask, required this.go, required this.buy});

  /// Ask a follow-up question.
  final void Function(String question) ask;

  /// Open a page.
  final void Function(String path) go;

  /// Put a course in the cart and go to checkout.
  final void Function(CourseSuggestion course) buy;
}

String _pounds(double v) =>
    '£${v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2)}';

String _date(DateTime? d) {
  if (d == null) return '';
  const m = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${d.day} ${m[d.month - 1]} ${d.year}';
}

/// Draws one [ReplyBlock] in the chat.
class ReplyBlockView extends StatelessWidget {
  const ReplyBlockView({super.key, required this.block, required this.actions});

  final ReplyBlock block;
  final BlockActions actions;

  @override
  Widget build(BuildContext context) {
    // A ListView cuts off the Material above it, so each block carries its own
    // for the ink effects on links and buttons.
    return Material(type: MaterialType.transparency, child: _content(context));
  }

  Widget _content(BuildContext context) => switch (block) {
    TextBlock b => Text(b.text, style: AppText.body.copyWith(height: 1.5)),
    ProgressBlock b => _ProgressView(block: b, actions: actions),
    PaymentBlock b => _PaymentView(block: b, actions: actions),
    CoursesBlock b => _CoursesView(block: b, actions: actions),
    AnswerBlock b => _AnswerView(block: b, actions: actions),
    RagAnswerBlock b => _RagAnswerView(block: b, actions: actions),
    CertificatesBlock b => _CertificatesView(block: b, actions: actions),
    SuggestionsBlock b => _Chips(questions: b.questions, onTap: actions.ask),
    SignInBlock() => Align(
      alignment: Alignment.centerLeft,
      child: FilledButton(
        onPressed: () => actions.go(Routes.login),
        child: const Text('Sign in'),
      ),
    ),
  };
}

class _Chips extends StatelessWidget {
  const _Chips({required this.questions, required this.onTap});
  final List<String> questions;
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Space.xs,
      runSpacing: Space.xs,
      children: [
        for (final q in questions)
          ActionChip(
            label: Text(q, style: AppText.small.copyWith(color: AppColors.red)),
            backgroundColor: AppColors.redSoft,
            side: BorderSide.none,
            shape: const StadiumBorder(),
            onPressed: () => onTap(q),
          ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label);
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: Space.sm,
          horizontal: Space.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: Radii.inputAll,
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          children: [
            Text(value, style: AppText.h3.copyWith(color: AppColors.red)),
            Text(label, style: AppText.small, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------- progress

class _ProgressView extends StatelessWidget {
  const _ProgressView({required this.block, required this.actions});
  final ProgressBlock block;
  final BlockActions actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _Stat('${block.items.length}', 'Courses'),
            const SizedBox(width: Space.xs),
            _Stat('${block.completed}', 'Finished'),
            const SizedBox(width: Space.xs),
            _Stat('${(block.average * 100).round()}%', 'Average'),
          ],
        ),
        const SizedBox(height: Space.sm),
        for (final item in block.items) ...[
          _ProgressRow(item: item, actions: actions),
          const SizedBox(height: Space.sm),
        ],
      ],
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.item, required this.actions});
  final ProgressItem item;
  final BlockActions actions;

  @override
  Widget build(BuildContext context) {
    final pct = (item.progress * 100).round();
    final finished = item.progress >= 1;
    return Container(
      padding: const EdgeInsets.all(Space.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: Radii.inputAll,
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CourseThumb(courseId: item.course.id, width: 52, height: 52),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.course.title,
                        style: AppText.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '$pct%',
                      style: AppText.label.copyWith(
                        color: finished ? AppColors.success : AppColors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: Radii.pillAll,
                  child: LinearProgressIndicator(
                    value: item.progress,
                    minHeight: 8,
                    color: finished ? AppColors.success : AppColors.red,
                    backgroundColor: AppColors.grey200,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  finished
                      ? 'All ${item.total} lessons done'
                      : '${item.done} of ${item.total} lessons. Next: ${item.nextLesson ?? 'finish'}',
                  style: AppText.small,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: Space.sm,
                  children: [
                    _Link(
                      finished ? 'Review course' : 'Continue',
                      () => actions.go(Routes.learn(item.course.id)),
                    ),
                    if (item.certificateCode != null)
                      _Link(
                        'Certificate',
                        () => actions.go(
                          Routes.certificate(item.certificateCode!),
                        ),
                      )
                    else if (finished)
                      _Link(
                        'Get certificate',
                        () =>
                            actions.go(Routes.issueCertificate(item.course.id)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Link extends StatelessWidget {
  const _Link(this.label, this.onTap);
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(label, style: AppText.label.copyWith(color: AppColors.red)),
      ),
    );
  }
}

// -------------------------------------------------------------- payments

class _PaymentView extends StatelessWidget {
  const _PaymentView({required this.block, required this.actions});
  final PaymentBlock block;
  final BlockActions actions;

  @override
  Widget build(BuildContext context) {
    final recent = block.items.take(6).toList().reversed.toList();
    final top = recent.fold<double>(0, (m, i) => i.amount > m ? i.amount : m);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _Stat(_pounds(block.total), 'Total paid'),
            const SizedBox(width: Space.xs),
            _Stat('${block.items.length}', 'Orders'),
            const SizedBox(width: Space.xs),
            _Stat(_pounds(block.total / block.items.length), 'Average'),
          ],
        ),
        const SizedBox(height: Space.md),
        Text('Amount per order', style: AppText.small),
        const SizedBox(height: Space.xs),
        SizedBox(
          height: 150,
          child: BarChart(
            BarChartData(
              maxY: top == 0 ? 10 : top * 1.2,
              minY: 0,
              alignment: BarChartAlignment.spaceAround,
              gridData: FlGridData(
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: AppColors.line, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppColors.inverseSurface,
                  getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                    '${recent[group.x].number}\n${_pounds(rod.toY)}',
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
                    reservedSize: 40,
                    getTitlesWidget: (v, meta) => v == meta.max
                        ? const SizedBox.shrink()
                        : Text(_pounds(v), style: AppText.small),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    getTitlesWidget: (v, _) {
                      final n = recent[v.toInt()].number;
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          n.length > 5 ? n.substring(n.length - 5) : n,
                          style: AppText.small,
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < recent.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: recent[i].amount,
                        width: 22,
                        color: i.isEven ? AppColors.red : AppColors.purple,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Space.sm),
        for (final p in block.items.take(5))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.summary,
                        style: AppText.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${p.number} · ${_date(p.date)}',
                        style: AppText.small,
                      ),
                    ],
                  ),
                ),
                Text(_pounds(p.amount), style: AppText.label),
              ],
            ),
          ),
        _Link('Open all orders', () => actions.go(Routes.myOrders)),
      ],
    );
  }
}

// --------------------------------------------------------------- courses

class _CoursesView extends StatelessWidget {
  const _CoursesView({required this.block, required this.actions});
  final CoursesBlock block;
  final BlockActions actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final s in block.items) ...[
          Container(
            padding: const EdgeInsets.all(Space.sm),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: Radii.inputAll,
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CourseThumb(courseId: s.course.id, width: 56, height: 56),
                    const SizedBox(width: Space.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.course.title, style: AppText.label),
                          Text(
                            '${s.course.level.name[0].toUpperCase()}${s.course.level.name.substring(1)} · ${s.course.modules.length} lessons · ${_pounds(s.course.price)}',
                            style: AppText.small,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s.reason,
                            style: AppText.small.copyWith(
                              color: s.canBuy
                                  ? AppColors.success
                                  : AppColors.grey600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Space.xs),
                Wrap(
                  spacing: Space.sm,
                  runSpacing: 4,
                  children: [
                    if (s.canBuy)
                      FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onPressed: () => actions.buy(s),
                        child: Text(
                          'Add to cart and pay ${_pounds(s.course.price)}',
                        ),
                      ),
                    if (s.enrolled)
                      _Link(
                        'Open course',
                        () => actions.go(Routes.learn(s.course.id)),
                      )
                    else
                      _Link(
                        'View details',
                        () => actions.go(Routes.course(s.course.id)),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.sm),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------- answer

class _AnswerView extends StatelessWidget {
  const _AnswerView({required this.block, required this.actions});
  final AnswerBlock block;
  final BlockActions actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Space.md),
          decoration: BoxDecoration(
            color: AppColors.grey50,
            borderRadius: Radii.inputAll,
            border: Border(left: BorderSide(color: AppColors.purple, width: 4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppIcon(
                    HugeIcons.strokeRoundedBookOpen01,
                    size: 18,
                    color: AppColors.purple,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${block.courseTitle} · ${block.passage.title}',
                      style: AppText.small.copyWith(color: AppColors.purple),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.xs),
              SelectableText(
                block.excerpt,
                style: AppText.body.copyWith(height: 1.55),
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.xs),
        _Link(
          'Open this course',
          () => actions.go(Routes.learn(block.passage.courseId)),
        ),
        if (block.related.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text('Related in the course material', style: AppText.small),
          const SizedBox(height: Space.xxs),
          _Chips(
            questions: [
              for (final p in block.related)
                p.title.replaceFirst(RegExp(r'^[A-Za-z ]+: '), ''),
            ],
            onTap: (q) => actions.ask('Explain $q'),
          ),
        ],
      ],
    );
  }
}

/// An answer from the retrieval service: the text, then the passages it used.
class _RagAnswerView extends StatelessWidget {
  const _RagAnswerView({required this.block, required this.actions});
  final RagAnswerBlock block;
  final BlockActions actions;

  String _path(RagSource s) {
    if (s.kind != 'record') return Routes.learn(s.courseId);
    if (s.title.contains('certificate')) return Routes.myCertificates;
    if (s.title.contains('order')) return Routes.myOrders;
    return s.courseId.isNotEmpty ? Routes.learn(s.courseId) : Routes.portalMe;
  }

  @override
  Widget build(BuildContext context) {
    final a = block.answer;
    final byModel = a.mode == 'llm';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Space.md),
          decoration: BoxDecoration(
            color: AppColors.grey50,
            borderRadius: Radii.inputAll,
            border: Border(left: BorderSide(color: AppColors.purple, width: 4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                byModel
                    ? 'AI answer, grounded in ${a.personalised ? 'your records and ' : ''}the course material'
                    : 'From ${a.personalised ? 'your records and ' : ''}the course material',
                style: AppText.small.copyWith(color: AppColors.purple),
              ),
              const SizedBox(height: Space.xs),
              SelectableText(
                a.answer,
                style: AppText.body.copyWith(height: 1.55),
              ),
            ],
          ),
        ),
        if (a.sources.isNotEmpty) ...[
          const SizedBox(height: Space.xs),
          Text('Sources', style: AppText.small),
          const SizedBox(height: Space.xxs),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              for (final s in a.sources)
                ActionChip(
                  avatar: AppIcon(
                    s.kind == 'record'
                        ? HugeIcons.strokeRoundedUserAccount
                        : HugeIcons.strokeRoundedBookOpen01,
                    size: 16,
                    color: AppColors.red,
                  ),
                  label: Text(
                    s.kind == 'record' || s.courseTitle.isEmpty
                        ? s.title
                        : '${s.courseTitle} · ${s.title}',
                    style: AppText.small.copyWith(color: AppColors.red),
                  ),
                  backgroundColor: AppColors.redSoft,
                  side: BorderSide.none,
                  shape: const StadiumBorder(),
                  onPressed: () => actions.go(_path(s)),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _CertificatesView extends StatelessWidget {
  const _CertificatesView({required this.block, required this.actions});
  final CertificatesBlock block;
  final BlockActions actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final c in block.items)
          Container(
            margin: const EdgeInsets.only(bottom: Space.xs),
            padding: const EdgeInsets.all(Space.sm),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: Radii.inputAll,
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                AppIcon(
                  HugeIcons.strokeRoundedAward01,
                  size: 28,
                  color: AppColors.red,
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.courseTitle, style: AppText.label),
                      Text(
                        '${c.code} · ${_date(c.issuedAt)}',
                        style: AppText.small,
                      ),
                    ],
                  ),
                ),
                _Link('View', () => actions.go(Routes.certificate(c.code))),
              ],
            ),
          ),
      ],
    );
  }
}
