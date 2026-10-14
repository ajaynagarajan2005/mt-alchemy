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
import '../screens/certificate/certificate_generation_screen.dart';
import '../screens/certificate/certificate_screen.dart';
import '../screens/organisations/organisations_screen.dart';
import '../screens/portal/course_catalogue_screen.dart';
import '../screens/portal/employer_reports_screen.dart';
import '../screens/portal/learner/learner_screens.dart';
import '../screens/portal/super/catalog_admin_screens.dart';
import '../screens/portal/super/super_screens.dart';
import '../screens/portal/trainer/course_editor_screen.dart';
import '../screens/portal/trainer/course_students_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/insights/article_screen.dart';
import '../screens/insights/insights_screen.dart';
import '../screens/learn/player_screen.dart';
import '../screens/services/service_detail_screen.dart';
import '../screens/tour/tour_screen.dart';
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

  GoRoute portalPage(String path, Widget Function(GoRouterState) build) =>
      GoRoute(
        path: path,
        pageBuilder: (context, state) => page(state, build(state)),
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
            path: '/learn/:courseId/certificate',
            pageBuilder: (context, state) => page(
              state,
              CertificateGenerationScreen(
                key: ValueKey('gen-${state.pathParameters['courseId']}'),
                courseId: state.pathParameters['courseId']!,
              ),
            ),
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
            path: Routes.tour,
            pageBuilder: (context, state) => page(state, const TourScreen()),
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
      // Every portal page is a flat sibling route. Nested child routes would
      // stack a second page under the first, and Flutter does not lay out
      // the page underneath.
      ShellRoute(
        builder: (context, state, child) => PortalShell(child: child),
        routes: [
          // /portal itself always redirects to the role home.
          stub(Routes.portal, 'Portal'),
          // Learner
          portalPage(Routes.portalMe, (_) => const IndividualScreen()),
          portalPage(Routes.myCourses, (_) => const CourseCatalogueScreen()),
          portalPage(Routes.myOrders, (_) => const MyOrdersScreen()),
          portalPage(Routes.myDownloads, (_) => const MyDownloadsScreen()),
          portalPage(
            Routes.myCertificates,
            (_) => const MyCertificatesScreen(),
          ),
          portalPage(Routes.myProfile, (_) => const MyProfileScreen()),
          // Employer
          portalPage(Routes.employer, (_) => const EmployerOverviewScreen()),
          portalPage(Routes.employerEmployees, (_) => const EmployeesScreen()),
          portalPage(Routes.employerAssign, (_) => const AssignScreen()),
          portalPage(Routes.employerProgress, (_) => const ProgressScreen()),
          portalPage(
            Routes.employerCourses,
            (_) => const CourseCatalogueScreen(),
          ),
          portalPage(
            Routes.employerReports,
            (_) => const EmployerReportsScreen(),
          ),
          // Trainer (the course editor and students are also used by admins)
          portalPage(Routes.admin, (_) => const AdminScreen()),
          portalPage(
            '/portal/admin/courses/:courseId',
            (state) => CourseEditorScreen(
              key: ValueKey(state.pathParameters['courseId']),
              courseId: state.pathParameters['courseId']!,
            ),
          ),
          portalPage(
            '/portal/admin/courses/:courseId/students',
            (state) => CourseStudentsScreen(
              key: ValueKey(state.pathParameters['courseId']),
              courseId: state.pathParameters['courseId']!,
            ),
          ),
          // Super admin
          portalPage(Routes.superAdmin, (_) => const SuperDashboardScreen()),
          portalPage(Routes.superUsers, (_) => const UsersScreen()),
          portalPage(
            Routes.superCourses,
            (_) => const AdminScreen(showWelcome: false),
          ),
          portalPage(Routes.superProducts, (_) => const ProductsAdminScreen()),
          portalPage(
            '/portal/super/products/:productId',
            (state) => ProductEditorScreen(
              key: ValueKey(state.pathParameters['productId']),
              productId: state.pathParameters['productId']!,
            ),
          ),
          portalPage(Routes.superOrders, (_) => const OrdersAdminScreen()),
          portalPage(Routes.superEnquiries, (_) => const EnquiriesScreen()),
          portalPage(Routes.superContent, (_) => const ContentAdminScreen()),
        ],
      ),
    ],
  );
}
