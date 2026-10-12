import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../data/models/people.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/checkout/checkout_screen.dart';
import '../screens/checkout/success_screen.dart';
import '../screens/contact/contact_screen.dart';
import '../screens/about/about_screen.dart';
import '../screens/assessment/assessment_screen.dart';
import '../screens/certificate/certificate_screen.dart';
import '../screens/organisations/organisations_screen.dart';
import '../screens/portal/course_catalogue_screen.dart';
import '../screens/portal/employer_reports_screen.dart';
import '../screens/portal/learner/learner_screens.dart';
import '../screens/portal/super/catalog_admin_screens.dart';
import '../screens/portal/super/super_screens.dart';
import '../screens/portal/trainer/course_editor_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/insights/article_screen.dart';
import '../screens/insights/insights_screen.dart';
import '../screens/learn/player_screen.dart';
import '../screens/services/service_detail_screen.dart';
import '../screens/services/services_screen.dart';
import '../screens/placeholder_screen.dart';
import '../screens/portal/admin_screen.dart';
import '../screens/portal/assign_screen.dart';
import '../screens/portal/employees_screen.dart';
import '../screens/portal/employer_overview_screen.dart';
import '../screens/portal/individual_screen.dart';
import '../screens/portal/progress_screen.dart';
import '../screens/store/product_screen.dart';
import '../screens/store/store_screen.dart';
import '../screens/upskilling/course_detail_screen.dart';
import '../screens/upskilling/upskilling_screen.dart';
import '../state/auth_store.dart';
import '../widgets/layout/app_shell.dart';
import '../widgets/layout/portal_shell.dart';
import '../theme/motion.dart';
import 'routes.dart';

/// Home route for each role once signed in.
String portalHomeFor(UserRole role) => switch (role) {
  UserRole.individual => Routes.portalMe,
  UserRole.employer => Routes.employer,
  UserRole.trainer => Routes.admin,
  UserRole.superAdmin => Routes.superAdmin,
};

GoRouter createRouter(AuthStore auth) {
  // Pages fade in with a slight lift; reduced motion gets an instant swap.
  Page<void> page(GoRouterState state, Widget child) => CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: Motion.medium,
    reverseTransitionDuration: Motion.fast,
    transitionsBuilder: (context, animation, _, child) {
      if (Motion.reduced(context)) return child;
      final curved = CurvedAnimation(parent: animation, curve: Motion.ease);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.015),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );

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

      // Until Firebase restores the session, hold protected pages rather
      // than bouncing a signed-in user to the login screen.
      if (!auth.ready) return null;

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
        // Super admins also use the trainer course editor.
        UserRole.superAdmin =>
          path.startsWith(Routes.superAdmin) || path.startsWith(Routes.admin),
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
          GoRoute(
            path: Routes.upskilling,
            pageBuilder: (context, state) =>
                page(state, const UpskillingScreen()),
            routes: [
              GoRoute(
                path: ':courseId',
                pageBuilder: (context, state) => page(
                  state,
                  CourseDetailScreen(
                    courseId: state.pathParameters['courseId']!,
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/learn/:courseId',
            pageBuilder: (context, state) => page(
              state,
              PlayerScreen(
                key: ValueKey(state.pathParameters['courseId']),
                courseId: state.pathParameters['courseId']!,
              ),
            ),
          ),
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
            path: Routes.organisations,
            pageBuilder: (context, state) =>
                page(state, const OrganisationsScreen()),
          ),
          GoRoute(
            path: Routes.assessment,
            pageBuilder: (context, state) =>
                page(state, const AssessmentScreen()),
          ),
          GoRoute(
            path: '/certificates/:code',
            pageBuilder: (context, state) => page(
              state,
              CertificateScreen(code: state.pathParameters['code']!),
            ),
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
        ],
      ),
      // Signed-in portals share their own shell (second Scaffold + AppBar).
      ShellRoute(
        builder: (context, state, child) => PortalShell(child: child),
        routes: [
          // /portal itself always redirects to the role home.
          stub(Routes.portal, 'Portal'),
          GoRoute(
            path: Routes.portalMe,
            pageBuilder: (context, state) =>
                page(state, const IndividualScreen()),
            routes: [
              GoRoute(
                path: 'courses',
                pageBuilder: (context, state) =>
                    page(state, const CourseCatalogueScreen()),
              ),
              GoRoute(
                path: 'orders',
                pageBuilder: (context, state) =>
                    page(state, const MyOrdersScreen()),
              ),
              GoRoute(
                path: 'downloads',
                pageBuilder: (context, state) =>
                    page(state, const MyDownloadsScreen()),
              ),
              GoRoute(
                path: 'certificates',
                pageBuilder: (context, state) =>
                    page(state, const MyCertificatesScreen()),
              ),
              GoRoute(
                path: 'profile',
                pageBuilder: (context, state) =>
                    page(state, const MyProfileScreen()),
              ),
            ],
          ),
          GoRoute(
            path: Routes.employer,
            pageBuilder: (context, state) =>
                page(state, const EmployerOverviewScreen()),
            routes: [
              GoRoute(
                path: 'employees',
                pageBuilder: (context, state) =>
                    page(state, const EmployeesScreen()),
              ),
              GoRoute(
                path: 'assign',
                pageBuilder: (context, state) =>
                    page(state, const AssignScreen()),
              ),
              GoRoute(
                path: 'progress',
                pageBuilder: (context, state) =>
                    page(state, const ProgressScreen()),
              ),
              GoRoute(
                path: 'courses',
                pageBuilder: (context, state) =>
                    page(state, const CourseCatalogueScreen()),
              ),
              GoRoute(
                path: 'reports',
                pageBuilder: (context, state) =>
                    page(state, const EmployerReportsScreen()),
              ),
            ],
          ),
          GoRoute(
            path: Routes.admin,
            pageBuilder: (context, state) => page(state, const AdminScreen()),
            routes: [
              GoRoute(
                path: 'courses/:courseId',
                pageBuilder: (context, state) => page(
                  state,
                  CourseEditorScreen(
                    key: ValueKey(state.pathParameters['courseId']),
                    courseId: state.pathParameters['courseId']!,
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: Routes.superAdmin,
            pageBuilder: (context, state) =>
                page(state, const SuperDashboardScreen()),
            routes: [
              GoRoute(
                path: 'users',
                pageBuilder: (context, state) =>
                    page(state, const UsersScreen()),
              ),
              GoRoute(
                path: 'courses',
                pageBuilder: (context, state) =>
                    page(state, const AdminScreen(showWelcome: false)),
              ),
              GoRoute(
                path: 'products',
                pageBuilder: (context, state) =>
                    page(state, const ProductsAdminScreen()),
                routes: [
                  GoRoute(
                    path: ':productId',
                    pageBuilder: (context, state) => page(
                      state,
                      ProductEditorScreen(
                        key: ValueKey(state.pathParameters['productId']),
                        productId: state.pathParameters['productId']!,
                      ),
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'orders',
                pageBuilder: (context, state) =>
                    page(state, const OrdersAdminScreen()),
              ),
              GoRoute(
                path: 'enquiries',
                pageBuilder: (context, state) =>
                    page(state, const EnquiriesScreen()),
              ),
              GoRoute(
                path: 'content',
                pageBuilder: (context, state) =>
                    page(state, const ContentAdminScreen()),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
