// Writes the app's seed catalogue (lib/data/mock) to tools/seed/seed.json so
// the Node seed script loads exactly what the app shows offline.
// Run: dart run tools/export_seed.dart
import 'dart:convert';
import 'dart:io';

import 'package:mt_alchemy/data/mock/articles.dart';
import 'package:mt_alchemy/data/mock/courses.dart';
import 'package:mt_alchemy/data/mock/demo_accounts.dart';
import 'package:mt_alchemy/data/mock/founders.dart';
import 'package:mt_alchemy/data/mock/products.dart';
import 'package:mt_alchemy/data/models/product.dart';

void main() {
  final seed = {
    'courses': {for (final c in courses) c.id: c.toMap()},
    'products': {for (final p in products) p.id: p.toMap()},
    'productCategories': {
      for (final c in ProductCategory.values) c.name: {'label': c.label},
    },
    'articles': {for (final a in articles) a.slug: a.toMap()},
    'founders': {for (final f in founders) f.id: f.toMap()},
    'impactStories': {for (final t in testimonials) t.id: t.toMap()},
    'organization': {'id': demoOrganisation.id, ...demoOrganisation.toMap()},
    'users': [
      for (final u in demoUsers) {'key': u.id, ...u.toMap()},
    ],
    'employees': {for (final e in demoEmployees) e.id: e.toMap()},
    'password': demoPassword,
  };
  File('tools/seed/seed.json')
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(seed));
  stdout.writeln('Wrote tools/seed/seed.json');
}
