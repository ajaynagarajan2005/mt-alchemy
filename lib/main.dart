import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/backend.dart';
import 'data/models/people.dart';
import 'firebase_options.dart';
import 'state/admin_store.dart';
import 'state/auth_store.dart';
import 'state/cart_store.dart';
import 'state/catalog_store.dart';
import 'state/commerce_store.dart';
import 'state/learning_store.dart';
import 'state/notification_store.dart';
import 'state/org_store.dart';
import 'state/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Clean URLs on the web (/store instead of /#/store).
  usePathUrlStrategy();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(AppProviders(backend: Backend.live(), child: const MtAlchemyApp()));
}

/// Every store, wired to one [Backend]. Tests build this with fakes.
class AppProviders extends StatelessWidget {
  const AppProviders({super.key, required this.backend, required this.child});

  final Backend backend;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: backend),
        ChangeNotifierProvider(create: (_) => AuthStore(backend)),
        ChangeNotifierProxyProvider<AuthStore, CatalogStore>(
          create: (_) => CatalogStore(backend),
          update: (_, auth, catalog) =>
              catalog!..setStaff(auth.currentUser?.role.isStaff ?? false),
        ),
        ChangeNotifierProvider(
          create: (c) => CartStore(
            backend,
            c.read<AuthStore>(),
            c.read<CatalogStore>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (c) => LearningStore(backend, c.read<AuthStore>()),
        ),
        ChangeNotifierProvider(
          create: (c) => CommerceStore(backend, c.read<AuthStore>()),
        ),
        ChangeNotifierProvider(
          create: (c) => OrgStore(backend, c.read<AuthStore>()),
        ),
        ChangeNotifierProvider(
          create: (c) => NotificationStore(backend, c.read<AuthStore>()),
        ),
        ChangeNotifierProvider(
          create: (c) => AdminStore(backend, c.read<AuthStore>()),
        ),
        ChangeNotifierProvider(create: (_) => ThemeController()),
      ],
      child: child,
    );
  }
}
