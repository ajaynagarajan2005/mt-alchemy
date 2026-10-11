import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../theme/breakpoints.dart';
import '../../widgets/layout/app_shell.dart';
import 'sections/course_row.dart';
import 'sections/cta_band.dart';
import 'sections/home_hero.dart';
import 'sections/insights_list.dart';
import 'sections/manifesto.dart';
import 'sections/services_bento.dart';
import 'sections/store_teaser.dart';
import 'sections/testimonial.dart';

/// Home. One ScrollController drives the zoom-through from the hero into
/// Services through AnimatedBuilder, so scrolling never calls setState.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context).height;
    final heroHeight = math.max(viewport, context.isCompact ? 600.0 : 680.0);

    return PageScroll(
      controller: _scroll,
      underNav: true,
      children: [
        HomeHero(scroll: _scroll, height: heroHeight),
        ZoomThrough(
          scroll: _scroll,
          distance: heroHeight * 0.7,
          child: const ServicesBento(),
        ),
        const Manifesto(),
        const CourseRow(),
        const TestimonialSection(),
        const StoreTeaser(),
        const InsightsList(),
        const CtaBand(),
      ],
    );
  }
}
