/// Every path in the app. Use these instead of string literals.
abstract final class Routes {
  static const home = '/';
  static const about = '/about';
  static const services = '/services';
  static String service(String slug) => '/services/$slug';
  static const upskilling = '/upskilling';
  static String course(String id) => '/upskilling/$id';
  static String learn(String id) => '/learn/$id';
  static const store = '/store';
  static String product(String id) => '/store/$id';
  static const cart = '/cart';
  static const checkout = '/checkout';
  static const checkoutSuccess = '/checkout/success';
  static const insights = '/insights';
  static String article(String slug) => '/insights/$slug';
  static const contact = '/contact';
  static const login = '/login';
  static const register = '/register';

  static const portal = '/portal';
  static const portalMe = '/portal/me';
  static const employer = '/portal/employer';
  static const employerEmployees = '/portal/employer/employees';
  static const employerAssign = '/portal/employer/assign';
  static const employerProgress = '/portal/employer/progress';
  static const admin = '/portal/admin';
}

class NavLink {
  const NavLink(this.label, this.path);
  final String label;
  final String path;
}

/// Primary navigation (Home is reached via the wordmark).
const primaryNav = [
  NavLink('About', Routes.about),
  NavLink('Services', Routes.services),
  NavLink('Upskilling', Routes.upskilling),
  NavLink('Store', Routes.store),
  NavLink('Insights', Routes.insights),
  NavLink('Contact', Routes.contact),
];
