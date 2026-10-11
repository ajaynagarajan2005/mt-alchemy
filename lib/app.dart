import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'router/app_router.dart';
import 'state/auth_store.dart';
import 'theme/app_theme.dart';

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
    return MaterialApp.router(
      title: 'MT Alchemy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: _router,
    );
  }
}
