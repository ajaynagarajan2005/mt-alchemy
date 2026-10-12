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
  static const organisations = '/organisations';
  static const assessment = '/eq-assessment';
  static String certificate(String code) => '/certificates/$code';

  static const portal = '/portal';
  static const portalMe = '/portal/me';
  static const myOrders = '/portal/me/orders';
  static const myDownloads = '/portal/me/downloads';
  static const myCertificates = '/portal/me/certificates';
  static const myProfile = '/portal/me/profile';
  static const employer = '/portal/employer';
  static const employerEmployees = '/portal/employer/employees';
  static const employerAssign = '/portal/employer/assign';
  static const employerProgress = '/portal/employer/progress';
  static const employerReports = '/portal/employer/reports';

  /// Trainer portal: course authoring.
  static const admin = '/portal/admin';
  static String editCourse(String id) => '/portal/admin/courses/$id';

  /// Super admin portal.
  static const superAdmin = '/portal/super';
  static const superUsers = '/portal/super/users';
  static const superProducts = '/portal/super/products';
  static String editProduct(String id) => '/portal/super/products/$id';
  static const superOrders = '/portal/super/orders';
  static const superEnquiries = '/portal/super/enquiries';
  static const superContent = '/portal/super/content';
  static const superCourses = '/portal/super/courses';
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
