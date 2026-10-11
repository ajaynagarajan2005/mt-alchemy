import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'state/auth_store.dart';
import 'state/cart_store.dart';
import 'state/learning_store.dart';
import 'state/org_store.dart';

void main() {
  // Clean URLs on the web (/store instead of /#/store).
  usePathUrlStrategy();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthStore()),
        ChangeNotifierProvider(create: (_) => CartStore()),
        ChangeNotifierProvider(create: (_) => LearningStore()),
        ChangeNotifierProvider(create: (_) => OrgStore()),
      ],
      child: const MtAlchemyApp(),
    ),
  );
}
