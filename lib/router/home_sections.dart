import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/motion.dart';
import 'routes.dart';

/// The landing page's sections, keyed by the page each one previews.
///
/// On the home page, a menu click glides to the matching section; from any
/// other page it opens the full page (with the fade-in page transition).
abstract final class HomeSections {
  static final _keys = <String, GlobalKey>{
    for (final p in [
      Routes.about,
      Routes.services,
      Routes.upskilling,
      Routes.store,
      Routes.insights,
      Routes.contact,
    ])
      p: GlobalKey(debugLabel: 'home-section $p'),
  };

  static GlobalKey keyFor(String path) => _keys[path]!;

  /// Goes to [path]: scrolls the landing page when we are on it and it has
  /// that section, otherwise navigates. Returns true if it scrolled.
  static bool navigate(BuildContext context, String path) {
    final here = GoRouterState.of(context).uri.path;
    final target = _keys[path]?.currentContext;
    if (here == Routes.home && target != null) {
      Scrollable.ensureVisible(
        target,
        duration: Motion.reduced(context)
            ? Duration.zero
            : const Duration(milliseconds: 900),
        curve: Curves.easeInOutCubic,
      );
      return true;
    }
    context.go(path);
    return false;
  }
}
