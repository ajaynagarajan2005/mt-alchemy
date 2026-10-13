import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'router/app_router.dart';
import 'state/auth_store.dart';
import 'state/theme_controller.dart';
import 'theme/app_theme.dart';
import 'theme/colors.dart';

class MtAlchemyApp extends StatefulWidget {
  const MtAlchemyApp({super.key});

  @override
  State<MtAlchemyApp> createState() => _MtAlchemyAppState();
}

class _MtAlchemyAppState extends State<MtAlchemyApp> {
  late final GoRouter _router = createRouter(context.read<AuthStore>());

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  Brightness? _applied;

  /// Palette tokens are static, so after the brightness changes every widget
  /// must rebuild to re-read them. Marking each element dirty does that
  /// without recreating the tree, which keeps the current page, scroll
  /// position and any widget state (a full-tree key swap broke widgets that
  /// hold GlobalKeys, such as the landing sections, and left them stale).
  void _rebuildAll() {
    void visit(Element element) {
      element.markNeedsBuild();
      element.visitChildren(visit);
    }

    (context as Element).visitChildren(visit);
  }

  @override
  Widget build(BuildContext context) {
    // Effective brightness: the user's choice, else the browser setting.
    final brightness = context.watch<ThemeController>().effective(
      MediaQuery.platformBrightnessOf(context),
    );
    AppColors.apply(brightness);
    if (_applied != null && _applied != brightness) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _rebuildAll();
      });
    }
    _applied = brightness;
    return MaterialApp.router(
      title: 'MT Alchemy',
      debugShowCheckedModeBanner: false,
      theme: brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
      routerConfig: _router,
    );
  }
}
