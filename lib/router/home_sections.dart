import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'routes.dart';

/// The landing page's sections, keyed by the page each one previews.
///
/// The keys let the landing page mark each preview section.
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

  /// Opens the page at [path] from the menu. The landing page used to glide
  /// to its preview section instead, which left the address on "/" and made
  /// About, Services and the rest look broken there; every menu link now opens
  /// its full page (with the fade-in page transition), the same on all pages.
  /// Returns false because it never scrolls.
  static bool navigate(BuildContext context, String path) {
    context.go(path);
    return false;
  }
}
