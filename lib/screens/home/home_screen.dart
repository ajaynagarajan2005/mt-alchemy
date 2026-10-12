import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../widgets/layout/app_shell.dart';
import 'sections/course_row.dart';
import 'sections/cta_band.dart';
import 'sections/home_hero.dart';
import 'sections/insights_list.dart';
import '../../router/home_sections.dart';
import '../../router/routes.dart';
import 'sections/landing_extras.dart';
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
    // Hero fills the viewport on every device; the floor only helps very
    // short viewports (landscape phones).
    final heroHeight = math.max(viewport, 560.0);

    return PageScroll(
      controller: _scroll,
      underNav: true,
      eager: true,
      // One landing page: each menu item has a section here (see
      // HomeSections). Menu clicks on this page glide to them.
      children: [
        HomeHero(scroll: _scroll, height: heroHeight),
        KeyedSubtree(
          key: HomeSections.keyFor(Routes.services),
          child: ZoomThrough(
            scroll: _scroll,
            distance: heroHeight * 0.7,
            child: const ServicesBento(),
          ),
        ),
        KeyedSubtree(
          key: HomeSections.keyFor(Routes.about),
          child: const AboutTeaser(),
        ),
        const Manifesto(),
        KeyedSubtree(
          key: HomeSections.keyFor(Routes.upskilling),
          child: const CourseRow(),
        ),
        const TestimonialSection(),
        KeyedSubtree(
          key: HomeSections.keyFor(Routes.store),
          child: const StoreTeaser(),
        ),
        KeyedSubtree(
          key: HomeSections.keyFor(Routes.insights),
          child: const InsightsList(),
        ),
        KeyedSubtree(
          key: HomeSections.keyFor(Routes.contact),
          child: const ContactTeaser(),
        ),
        const CtaBand(),
      ],
    );
  }
}
