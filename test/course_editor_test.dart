import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mt_alchemy/data/mock/courses.dart';
import 'package:mt_alchemy/data/models/people.dart';
import 'package:mt_alchemy/screens/portal/trainer/course_editor_screen.dart';
import 'package:mt_alchemy/state/catalog_store.dart';
import 'package:mt_alchemy/theme/app_theme.dart';
import 'package:provider/provider.dart';

import 'helpers/fake_backend.dart';

void main() {
  for (final id in ['ei-foundations', 'new']) {
    testWidgets('course editor lays out for "$id"', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final s = await tester.runAsync(
        () => FakeSession.signedIn(role: UserRole.superAdmin),
      );
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: s!.auth),
            ChangeNotifierProvider(create: (_) => CatalogStore(s.backend)),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: SingleChildScrollView(
                child: CourseEditorScreen(
                  courseId: id == 'new' ? 'new' : courses.first.id,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);
    });
  }
}
