import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mt_alchemy/data/models/people.dart';
import 'package:mt_alchemy/state/notification_store.dart';
import 'package:mt_alchemy/state/theme_controller.dart';
import 'package:provider/provider.dart';
import 'package:mt_alchemy/widgets/layout/portal_shell.dart';

import 'helpers/fake_backend.dart';

void main() {
  testWidgets('portal pages scroll when content is taller than the screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final s = await tester.runAsync(
      () => FakeSession.signedIn(role: UserRole.individual),
    );
    final router = GoRouter(
      initialLocation: '/portal/me',
      routes: [
        ShellRoute(
          builder: (context, state, child) => PortalShell(child: child),
          routes: [
            GoRoute(
              path: '/portal/me',
              builder: (context, state) => Column(
                children: [
                  for (var i = 0; i < 60; i++)
                    SizedBox(height: 80, child: Text('Row $i')),
                ],
              ),
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: s!.auth),
          ChangeNotifierProvider(
            create: (_) => NotificationStore(s.backend, s.auth),
          ),
          ChangeNotifierProvider(create: (_) => ThemeController()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    // Let the AuthStore inside AppProviders load the profile.
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump();
    }

    expect(find.text('Row 0'), findsOneWidget);
    expect(find.text('Row 40').hitTestable(), findsNothing);
    await tester.drag(find.text('Row 5'), const Offset(0, -2500));
    await tester.pumpAndSettle();
    expect(find.text('Row 40').hitTestable(), findsOneWidget);
  });
}
