import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../data/models/people.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/checkout/checkout_screen.dart';
import '../screens/checkout/success_screen.dart';
import '../screens/contact/contact_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/placeholder_screen.dart';
import '../screens/store/product_screen.dart';
import '../screens/store/store_screen.dart';
import '../state/auth_store.dart';
import '../widgets/layout/app_shell.dart';
import 'routes.dart';

/// Home route for each role once signed in.
String portalHomeFor(UserRole role) => switch (role) {
  UserRole.individual => Routes.portalMe,
  UserRole.employer => Routes.employer,
  UserRole.trainer => Routes.admin,
};

GoRouter createRouter(AuthStore auth) {
  Page<void> page(GoRouterState state, Widget child) =>
      NoTransitionPage(key: state.pageKey, child: child);

  GoRoute stub(
    String path,
    String title, {
    List<RouteBase> routes = const [],
  }) => GoRoute(
    path: path,
    pageBuilder: (context, state) =>
        page(state, PlaceholderScreen(title: title)),
    routes: routes,
  );

  return GoRouter(
    initialLocation: Routes.home,
    refreshListenable: auth,
    redirect: (context, state) {
      final path = state.uri.path;
      final user = auth.currentUser;
      final needsAuth =
          path.startsWith(Routes.portal) || path.startsWith('/learn');

      if (needsAuth && user == null) {
        return Uri(
          path: Routes.login,
          queryParameters: {'from': state.uri.toString()},
        ).toString();
      }
      if (user == null) return null;

      // Signed-in users have no use for the sign in or register screens.
      if (path == Routes.login || path == Routes.register) {
        return portalHomeFor(user.role);
      }

      final home = portalHomeFor(user.role);
      if (path == Routes.portal) return home;

      // Keep each role inside its own portal.
      final roleAllowed = switch (user.role) {
        UserRole.individual => path.startsWith(Routes.portalMe),
        UserRole.employer => path.startsWith(Routes.employer),
        UserRole.trainer => path.startsWith(Routes.admin),
      };
      if (path.startsWith(Routes.portal) && !roleAllowed) return home;
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: Routes.home,
            pageBuilder: (context, state) => page(state, const HomeScreen()),
          ),
          stub(Routes.about, 'About'),
          stub(Routes.services, 'Services', routes: [stub(':slug', 'Service')]),
          stub(
            Routes.upskilling,
            'Upskilling',
            routes: [stub(':courseId', 'Course')],
          ),
          stub('/learn/:courseId', 'Course player'),
          GoRoute(
            path: Routes.store,
            pageBuilder: (context, state) => page(state, const StoreScreen()),
            routes: [
              GoRoute(
                path: ':productId',
                pageBuilder: (context, state) => page(
                  state,
                  ProductScreen(
                    key: ValueKey(state.pathParameters['productId']),
                    productId: state.pathParameters['productId']!,
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: Routes.cart,
            pageBuilder: (context, state) => page(state, const CartScreen()),
          ),
          GoRoute(
            path: Routes.checkout,
            pageBuilder: (context, state) =>
                page(state, const CheckoutScreen()),
            routes: [
              GoRoute(
                path: 'success',
                pageBuilder: (context, state) =>
                    page(state, const SuccessScreen()),
              ),
            ],
          ),
          stub(Routes.insights, 'Insights', routes: [stub(':slug', 'Article')]),
          GoRoute(
            path: Routes.contact,
            pageBuilder: (context, state) => page(state, const ContactScreen()),
          ),
          GoRoute(
            path: Routes.login,
            pageBuilder: (context, state) => page(
              state,
              LoginScreen(from: state.uri.queryParameters['from']),
            ),
          ),
          GoRoute(
            path: Routes.register,
            pageBuilder: (context, state) => page(
              state,
              RegisterScreen(
                key: ValueKey(state.uri.queryParameters['type']),
                initialType: state.uri.queryParameters['type'] == 'organisation'
                    ? AccountType.organisation
                    : AccountType.individual,
              ),
            ),
          ),
          // /portal itself always redirects to the role home.
          stub(Routes.portal, 'Portal'),
          stub(Routes.portalMe, 'My learning'),
          stub(
            Routes.employer,
            'Employer portal',
            routes: [
              stub('employees', 'Employees'),
              stub('assign', 'Assign a course'),
              stub('progress', 'Team progress'),
            ],
          ),
          stub(Routes.admin, 'Trainer and admin'),
        ],
      ),
    ],
  );
}
