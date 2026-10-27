import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mt_alchemy/state/auth_store.dart';
import 'package:mt_alchemy/state/cart_store.dart';
import 'package:mt_alchemy/state/catalog_store.dart';
import 'package:mt_alchemy/state/chat_store.dart';
import 'package:mt_alchemy/state/commerce_store.dart';
import 'package:mt_alchemy/state/learning_store.dart';
import 'package:mt_alchemy/state/theme_controller.dart';
import 'package:mt_alchemy/widgets/assistant/assistant_launcher.dart';
import 'package:provider/provider.dart';

import 'helpers/fake_backend.dart';

void main() {
  testWidgets('the chat opens, answers a question and closes again', (t) async {
    t.view.physicalSize = const Size(1280, 800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final s = (await t.runAsync(() => FakeSession.signedIn()))!;
    final catalog = CatalogStore(s.backend);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) =>
              const Scaffold(body: Center(child: Text('Home page'))),
        ),
      ],
    );
    await t.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthStore>.value(value: s.auth),
          ChangeNotifierProvider<CatalogStore>.value(value: catalog),
          ChangeNotifierProvider(
            create: (_) => CartStore(s.backend, s.auth, catalog),
          ),
          ChangeNotifierProvider(
            create: (_) => LearningStore(s.backend, s.auth),
          ),
          ChangeNotifierProvider(
            create: (_) => CommerceStore(s.backend, s.auth),
          ),
          ChangeNotifierProvider(create: (_) => ChatStore(s.backend, s.auth)),
          ChangeNotifierProvider(
            create: (_) => ThemeController(persist: false),
          ),
        ],
        // The launcher is mounted exactly as in app.dart: in a Stack above the
        // Navigator, through MaterialApp's builder.
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => Stack(
            children: [
              child ?? const SizedBox.shrink(),
              AssistantLauncher(router: router),
            ],
          ),
        ),
      ),
    );
    await t.pump(const Duration(milliseconds: 300));
    expect(t.takeException(), isNull);

    await t.tap(find.text('Ask'));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Ask MT Alchemy'), findsOneWidget);
    expect(t.takeException(), isNull);

    await t.tap(find.text('Which courses can I add?'));
    for (var i = 0; i < 20; i++) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(t.takeException(), isNull);

    await t.tap(find.byTooltip('Close'));
    await t.pump(const Duration(milliseconds: 300));
    expect(
      find.text('Ask MT Alchemy'),
      findsNothing,
      reason: 'the panel should close',
    );
    expect(find.text('Ask'), findsOneWidget);
  });
}
