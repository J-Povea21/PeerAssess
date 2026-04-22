import 'package:f_clean_template/features/auth/ui/viewmodels/auth_controller.dart';
import 'package:f_clean_template/features/course/ui/viewmodels/course_controller.dart';
import 'package:f_clean_template/features/group/ui/viewmodels/group_controller.dart';
import 'package:f_clean_template/features/group/ui/views/category_list_page.dart';
import 'package:f_clean_template/features/group/ui/views/import_csv_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../helpers/test_helpers.dart';

/// ══════════════════════════════════════════════════════════════════════
///  Flow — Teacher imports a CSV category file
///  CategoryListPage → "Importar CSV" button → ImportCsvPage opens
/// ══════════════════════════════════════════════════════════════════════
///
/// Verifies role-gating (teacher sees the entry point, student does not)
/// and that the ImportCsvPage renders its key UI elements.
///
/// Follows the same mocked-GetX pattern as professor_login_flow_test.dart.
void main() {
  late MockAuthController mockAuth;
  late MockCourseController mockCourse;
  late MockGroupController mockGroup;

  const String testCourseId = 'course-001';

  setUp(() {
    mockAuth = MockAuthController();
    mockCourse = MockCourseController();
    mockGroup = MockGroupController();

    Get.put<AuthController>(mockAuth);
    Get.put<CourseController>(mockCourse);
    Get.put<GroupController>(mockGroup);
  });

  tearDown(() => Get.reset());

  group('Flow — Teacher import CSV', () {
    testWidgets(
        'teacher with empty category list sees "Importar CSV" button',
        (tester) async {
      mockAuth.setUser(mockTeacher);
      // Empty categories → empty state with "Importar CSV" call-to-action.
      mockGroup.categories.clear();

      await tester.pumpWidget(
        pumpApp(const CategoryListPage(courseId: testCourseId)),
      );
      await tester.pumpAndSettle();

      // Empty-state text
      expect(find.text('No hay categorías aún'), findsOneWidget);
      expect(
        find.text('Importa un archivo CSV para crear categorías'),
        findsOneWidget,
      );

      // Teacher-only call-to-action
      expect(find.text('Importar CSV'), findsOneWidget);
    });

    testWidgets(
        'student with empty category list does NOT see "Importar CSV" button',
        (tester) async {
      mockAuth.setUser(mockStudent);
      mockGroup.categories.clear();

      await tester.pumpWidget(
        pumpApp(const CategoryListPage(courseId: testCourseId)),
      );
      await tester.pumpAndSettle();

      // Student sees a different empty-state hint
      expect(find.text('No hay categorías aún'), findsOneWidget);
      expect(
        find.text('El profesor aún no ha creado categorías'),
        findsOneWidget,
      );

      // No "Importar CSV" button for students
      expect(find.text('Importar CSV'), findsNothing);
      expect(
        find.widgetWithText(ElevatedButton, 'Importar CSV'),
        findsNothing,
      );
    });

    testWidgets('teacher with categories sees the FAB "Importar CSV"',
        (tester) async {
      mockAuth.setUser(mockTeacher);
      mockGroup.categories.assignAll([mockCategory()]);

      await tester.pumpWidget(
        pumpApp(const CategoryListPage(courseId: testCourseId)),
      );
      await tester.pumpAndSettle();

      // Category card is rendered
      expect(find.text('Sprint 1'), findsOneWidget);

      // Teacher FAB (extended) with label "Importar CSV"
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Importar CSV'), findsOneWidget);
    });

    testWidgets('student with categories does NOT see the FAB "Importar CSV"',
        (tester) async {
      mockAuth.setUser(mockStudent);
      mockGroup.categories.assignAll([mockCategory()]);

      await tester.pumpWidget(
        pumpApp(const CategoryListPage(courseId: testCourseId)),
      );
      await tester.pumpAndSettle();

      // No FAB for students
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.text('Importar CSV'), findsNothing);
    });

    testWidgets('tapping "Importar CSV" opens ImportCsvPage with expected UI',
        (tester) async {
      mockAuth.setUser(mockTeacher);
      mockGroup.categories.clear();

      await tester.pumpWidget(
        pumpApp(const CategoryListPage(courseId: testCourseId)),
      );
      await tester.pumpAndSettle();

      // Tap the empty-state button (ElevatedButton.icon wraps the label
      // in an internal widget so we target the label text directly).
      await tester.tap(find.text('Importar CSV'));
      await tester.pumpAndSettle();

      // ImportCsvPage is rendered
      expect(find.byType(ImportCsvPage), findsOneWidget);

      // Key UI elements on ImportCsvPage
      // AppBar title
      expect(find.widgetWithText(AppBar, 'Importar CSV'), findsOneWidget);
      // File-selector prompt text (empty state)
      expect(find.text('Seleccionar archivo CSV'), findsOneWidget);
      // Supported format hint
      expect(
        find.text('Formato: Brightspace Group Export (.csv)'),
        findsOneWidget,
      );
      // Upload icon is shown while no file is picked
      expect(find.byIcon(Icons.upload_file), findsWidgets);
    });
  });
}
