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

  @override
  Widget build(BuildContext context) {
    // Effective brightness: the user's choice, else the browser setting.
    final brightness = context.watch<ThemeController>().effective(
      MediaQuery.platformBrightnessOf(context),
    );
    // Swap the palette before any widget builds, then key the app by
    // brightness so every widget re-reads the tokens. The router lives in
    // this State, so the current page survives the rebuild.
    AppColors.apply(brightness);
    return KeyedSubtree(
      key: ValueKey(brightness),
      child: MaterialApp.router(
        title: 'MT Alchemy',
        debugShowCheckedModeBanner: false,
        theme: brightness == Brightness.dark
            ? AppTheme.dark()
            : AppTheme.light(),
        routerConfig: _router,
      ),
    );
  }
}
