import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../data/models/people.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/contact/contact_screen.dart';
import '../screens/about/about_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/insights/article_screen.dart';
import '../screens/insights/insights_screen.dart';
import '../screens/services/service_detail_screen.dart';
import '../screens/services/services_screen.dart';
import '../screens/placeholder_screen.dart';
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
          GoRoute(
            path: Routes.about,
            pageBuilder: (context, state) => page(state, const AboutScreen()),
          ),
          GoRoute(
            path: Routes.services,
            pageBuilder: (context, state) =>
                page(state, const ServicesScreen()),
            routes: [
              GoRoute(
                path: ':slug',
                pageBuilder: (context, state) => page(
                  state,
                  ServiceDetailScreen(slug: state.pathParameters['slug']!),
                ),
              ),
            ],
          ),
          stub(
            Routes.upskilling,
            'Upskilling',
            routes: [stub(':courseId', 'Course')],
          ),
          stub('/learn/:courseId', 'Course player'),
          stub(Routes.store, 'Store', routes: [stub(':productId', 'Product')]),
          stub(Routes.cart, 'Cart'),
          stub(
            Routes.checkout,
            'Checkout',
            routes: [stub('success', 'Order confirmed')],
          ),
          GoRoute(
            path: Routes.insights,
            pageBuilder: (context, state) =>
                page(state, const InsightsScreen()),
            routes: [
              GoRoute(
                path: ':slug',
                pageBuilder: (context, state) => page(
                  state,
                  ArticleScreen(slug: state.pathParameters['slug']!),
                ),
              ),
            ],
          ),
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
