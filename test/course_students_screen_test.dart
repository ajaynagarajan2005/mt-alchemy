import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mt_alchemy/data/mock/courses.dart';
import 'package:mt_alchemy/data/models/people.dart';
import 'package:mt_alchemy/screens/portal/trainer/course_students_screen.dart';
import 'package:mt_alchemy/state/admin_store.dart';
import 'package:mt_alchemy/state/catalog_store.dart';
import 'package:mt_alchemy/theme/app_theme.dart';
import 'package:provider/provider.dart';

import 'helpers/fake_backend.dart';

void main() {
  testWidgets('students screen lays out with enrolled people', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final course = courses.first;
    final s = await tester.runAsync(
      () => FakeSession.signedIn(
        uid: 'u-admin',
        name: 'Admin',
        email: 'admin@example.com',
        role: UserRole.superAdmin,
      ),
    );
    await tester.runAsync(() async {
      await s!.db.collection('enrolments').doc('a').set({
        'userId': 'a',
        'userName': 'Paid Person',
        'userEmail': 'paid@example.com',
        'courseId': course.id,
        'orderId': 'o1',
        'source': 'purchase',
        'amountPaid': 149.0,
        'completedModuleIds': ['x'],
      });
      await s.db.collection('enrolments').doc('b').set({
        'userId': 'b',
        'userName': 'Free Person',
        'userEmail': 'free@example.com',
        'courseId': course.id,
        'source': 'granted',
      });
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: s!.auth),
          ChangeNotifierProvider(create: (_) => CatalogStore(s.backend)),
          ChangeNotifierProvider(create: (_) => AdminStore(s.backend, s.auth)),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: CourseStudentsScreen(courseId: course.id),
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump();
    }

    expect(tester.takeException(), isNull);
    expect(find.text('Paid Person'), findsOneWidget);
    expect(find.text('Paid £149.00'), findsOneWidget);
    expect(find.text('Free access'), findsWidgets);
  });
}
