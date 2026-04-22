import 'package:f_clean_template/features/auth/ui/viewmodels/auth_controller.dart';
import 'package:f_clean_template/features/course/ui/viewmodels/course_controller.dart';
import 'package:f_clean_template/features/group/ui/viewmodels/group_controller.dart';
import 'package:f_clean_template/features/home/ui/views/teacher_home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../helpers/test_helpers.dart';

void main() {
  late MockAuthController mockAuth;
  late MockCourseController mockCourse;
  late MockGroupController mockGroup;

  setUp(() {
    mockAuth = MockAuthController();
    mockAuth.setUser(mockTeacher);
    mockCourse = MockCourseController();
    mockGroup = MockGroupController();
    Get.put<AuthController>(mockAuth);
    Get.put<CourseController>(mockCourse);
    Get.put<GroupController>(mockGroup);
  });

  tearDown(() => Get.reset());

  group('TeacherHomePage', () {
    testWidgets('renders 4 bottom navigation tabs', (tester) async {
      await tester.pumpWidget(pumpApp(const TeacherHomePage()));
      await tester.pumpAndSettle();

      expect(find.text('Inicio'), findsOneWidget);
      expect(find.text('Cursos'), findsOneWidget);
      expect(find.text('Analíticas'), findsOneWidget);
      expect(find.text('Perfil'), findsOneWidget);
    });

    testWidgets('shows teacher name on dashboard', (tester) async {
      await tester.pumpWidget(pumpApp(const TeacherHomePage()));
      await tester.pumpAndSettle();

      expect(find.text('Prof. García'), findsAtLeastNWidgets(1));
      expect(find.text('Buenos días'), findsOneWidget);
    });

    testWidgets('shows stats cards with course data', (tester) async {
      mockCourse.courses.assignAll(mockCourses());

      await tester.pumpWidget(pumpApp(const TeacherHomePage()));
      await tester.pumpAndSettle();

      expect(find.text('Cursos activos'), findsOneWidget);
      expect(find.text('Evaluaciones'), findsAtLeastNWidgets(1));
      expect(find.text('Estudiantes'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows empty course state', (tester) async {
      await tester.pumpWidget(pumpApp(const TeacherHomePage()));
      await tester.pumpAndSettle();

      expect(find.text('Crea tu primer curso con el botón +'),
          findsAtLeastNWidgets(1));
    });

    testWidgets('shows MIS CURSOS section header', (tester) async {
      await tester.pumpWidget(pumpApp(const TeacherHomePage()));
      await tester.pumpAndSettle();

      expect(find.text('MIS CURSOS'), findsOneWidget);
    });

    testWidgets('shows FAB on dashboard tab', (tester) async {
      await tester.pumpWidget(pumpApp(const TeacherHomePage()));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('renders course cards when courses exist', (tester) async {
      mockCourse.courses.assignAll(mockCourses());

      await tester.pumpWidget(pumpApp(const TeacherHomePage()));
      await tester.pumpAndSettle();

      expect(find.text('Desarrollo Móvil'), findsAtLeastNWidgets(1));
      expect(
          find.text('Ingeniería de Software'), findsAtLeastNWidgets(1));
    });
  });
}
