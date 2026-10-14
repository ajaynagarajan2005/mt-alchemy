import 'dart:math' as math;

import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../data/models/course.dart';
import '../../router/routes.dart';
import '../../state/auth_store.dart';
import '../../state/catalog_store.dart';
import '../../state/learning_store.dart';
import '../../theme/colors.dart';
import '../../theme/radii.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/common/alchemy_button.dart';
import '../../widgets/common/app_icon.dart';
import '../../widgets/common/gradient_backdrop.dart';
import '../../widgets/layout/app_shell.dart';
import '../../widgets/layout/section.dart';
import '../upskilling/notice_page.dart';

/// The short film that plays after the last lesson, while the certificate and
/// the learner's review are written. When it ends the certificate opens.
///
/// SCAFFOLD note: lives inside the AppShell Scaffold like the player.
class CertificateGenerationScreen extends StatefulWidget {
  const CertificateGenerationScreen({super.key, required this.courseId});

  final String courseId;

  @override
  State<CertificateGenerationScreen> createState() =>
      _CertificateGenerationScreenState();
}

class _CertificateGenerationScreenState
    extends State<CertificateGenerationScreen>
    with SingleTickerProviderStateMixin {
  static const _stages = [
    'Checking every lesson',
    'Marking your quizzes',
    'Writing your personal review',
    'Sealing your certificate',
  ];

  late final AnimationController _film;
  Certificate? _certificate;
  bool _started = false;
  bool _failed = false;
  bool _filmDone = false;

  @override
  void initState() {
    super.initState();
    _film =
        AnimationController(vsync: this, duration: const Duration(seconds: 8))
          ..addStatusListener((s) {
            if (s == AnimationStatus.completed) {
              _filmDone = true;
              _maybeOpen();
            }
          });
  }

  @override
  void dispose() {
    _film.dispose();
    super.dispose();
  }

  void _start(Course course) {
    if (_started) return;
    _started = true;
    final learning = context.read<LearningStore>();
    final existing = learning.certificateFor(course.id);
    if (existing != null) {
      // Already issued: no need to play the film again.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(Routes.certificate(existing.code));
      });
      return;
    }
    final reduce = MediaQuery.of(context).disableAnimations;
    _film.duration = reduce
        ? const Duration(milliseconds: 600)
        : const Duration(seconds: 8);
    _film.forward();
    learning.issueCertificate(course).then((c) {
      _certificate = c;
      if (c == null && mounted) setState(() => _failed = true);
      _maybeOpen();
    });
  }

  void _maybeOpen() {
    if (!mounted || !_filmDone || _certificate == null) return;
    context.go(Routes.certificate(_certificate!.code));
  }

  @override
  Widget build(BuildContext context) {
    final course = context.watch<CatalogStore>().courseById(widget.courseId);
    final learning = context.watch<LearningStore>();
    final user = context.watch<AuthStore>().currentUser;

    if (course == null) {
      return NoticePage(
        title: 'We could not find that course',
        message: 'It may have moved or the link may be wrong.',
        action: AlchemyButton(
          label: 'Browse all courses',
          onPressed: () => context.go(Routes.upskilling),
        ),
      );
    }
    final e = learning.enrolment(course.id);
    if (e == null && !learning.loaded) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(Space.section),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (e == null || !e.isCompleteIn(course)) {
      final left = e == null
          ? course.modules.length
          : course.modules
                .where((m) => !e.completedModuleIds.contains(m.id))
                .length;
      return NoticePage(
        title: 'Finish the course first',
        message: e == null
            ? 'You are not enrolled on ${course.title}.'
            : 'You have $left lesson${left == 1 ? '' : 's'} left in '
                  '${course.title}. Complete them to receive your certificate.',
        action: AlchemyButton(
          label: 'Back to the course',
          onPressed: () => context.go(Routes.learn(course.id)),
        ),
      );
    }
    _start(course);

    return PageScroll(
      underNav: true,
      children: [
        GradientBackdrop(
          child: Padding(
            padding: EdgeInsets.only(top: pageHeaderTop(context)),
            child: Section(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: AnimatedBuilder(
                    animation: _film,
                    builder: (context, _) => _Film(
                      t: _film.value,
                      name: user?.name ?? '',
                      course: course.title,
                      stages: _stages,
                      failed: _failed,
                      onRetry: _failed
                          ? () => setState(() {
                              _failed = false;
                              _started = false;
                              _filmDone = false;
                              _film.reset();
                              _start(course);
                            })
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Film extends StatelessWidget {
  const _Film({
    required this.t,
    required this.name,
    required this.course,
    required this.stages,
    required this.failed,
    this.onRetry,
  });

  final double t;
  final String name;
  final String course;
  final List<String> stages;
  final bool failed;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final stage = math.min((t * stages.length).floor(), stages.length - 1);
    final sealT = ((t - 0.78) / 0.14).clamp(0.0, 1.0);
    final nameT = ((t - 0.5) / 0.2).clamp(0.0, 1.0);
    // CONTAINER (card): the sheet that is being "written".
    return Semantics(
      liveRegion: true,
      label: 'Generating your certificate. ${stages[stage]}.',
      child: Column(
        children: [
          Text('GENERATING YOUR CERTIFICATE', style: AppText.eyebrow),
          const SizedBox(height: Space.lg),
          SizedBox(
            height: 300,
            width: 300,
            child: CustomPaint(
              painter: _FilmPainter(t: t),
              child: Center(
                child: Transform.scale(
                  scale:
                      0.9 +
                      0.1 * Curves.easeOutBack.transform(math.min(1, t * 4)),
                  child: Container(
                    width: 190,
                    height: 134,
                    padding: const EdgeInsets.all(Space.sm),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: Radii.inputAll,
                      border: Border.all(color: AppColors.red, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowTint,
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'CERTIFICATE',
                              style: AppText.eyebrow.copyWith(fontSize: 9),
                            ),
                            const SizedBox(height: 6),
                            Opacity(
                              opacity: nameT,
                              child: Text(
                                name,
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.h4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Opacity(
                              opacity: nameT,
                              child: Text(
                                course,
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.small.copyWith(
                                  color: AppColors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Opacity(
                            opacity: sealT,
                            child: Transform.scale(
                              scale:
                                  1.8 -
                                  0.8 * Curves.easeOutBack.transform(sealT),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: AppIcon(
                                  HugeIcons.strokeRoundedAward01,
                                  size: 22,
                                  color: AppColors.onInverse,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: Space.lg),
          for (var i = 0; i < stages.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 22,
                    child: i < stage || t >= 1
                        ? AppIcon(
                            HugeIcons.strokeRoundedCheckmarkCircle02,
                            size: 18,
                            color: AppColors.success,
                          )
                        : i == stage
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(width: Space.xs),
                  Text(
                    stages[i],
                    style: i <= stage || t >= 1
                        ? AppText.body
                        : AppText.bodyMuted,
                  ),
                ],
              ),
            ),
          const SizedBox(height: Space.md),
          ClipRRect(
            borderRadius: Radii.pillAll,
            child: LinearProgressIndicator(
              value: t,
              minHeight: 6,
              color: AppColors.red,
              backgroundColor: AppColors.grey200,
            ),
          ),
          if (failed) ...[
            const SizedBox(height: Space.lg),
            Text(
              'We could not save your certificate. Check your connection and try again.',
              textAlign: TextAlign.center,
              style: AppText.body,
            ),
            const SizedBox(height: Space.sm),
            AlchemyButton(label: 'Try again', onPressed: onRetry),
          ],
        ],
      ),
    );
  }
}

/// Orbiting ring and a burst of sparkles when the seal lands.
class _FilmPainter extends CustomPainter {
  _FilmPainter({required this.t});
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = AppColors.red.withValues(alpha: 0.85);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = AppColors.grey200;
    final r = size.width / 2 - 8;
    canvas.drawCircle(c, r, track);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * t,
      false,
      ring,
    );
    // Dots orbit while the film runs.
    for (var i = 0; i < 3; i++) {
      final a = t * 2 * math.pi * 2 + i * 2 * math.pi / 3;
      canvas.drawCircle(
        c + Offset(math.cos(a), math.sin(a)) * (r - 18),
        3,
        Paint()..color = AppColors.red.withValues(alpha: 0.35),
      );
    }
    // Sparkle burst after the seal lands.
    final burst = ((t - 0.88) / 0.12).clamp(0.0, 1.0);
    if (burst > 0) {
      for (var i = 0; i < 14; i++) {
        final a = i * 2 * math.pi / 14;
        final d = 40 + 90 * Curves.easeOut.transform(burst);
        canvas.drawCircle(
          c + Offset(math.cos(a), math.sin(a)) * d,
          3.5 * (1 - burst) + 1,
          Paint()..color = AppColors.red.withValues(alpha: 1 - burst),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_FilmPainter old) => old.t != t;
}
