import 'package:f_clean_template/features/auth/ui/viewmodels/auth_controller.dart';
import 'package:f_clean_template/features/course/ui/viewmodels/course_controller.dart';
import 'package:f_clean_template/features/course/ui/views/course_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../helpers/test_helpers.dart';

void main() {
  late MockAuthController mockAuth;
  late MockCourseController mockCourse;

  setUp(() {
    mockAuth = MockAuthController();
    mockCourse = MockCourseController();
    Get.put<AuthController>(mockAuth);
    Get.put<CourseController>(mockCourse);
  });

  tearDown(() => Get.reset());

  group('CourseListPage — teacher', () {
    setUp(() => mockAuth.setUser(mockTeacher));

    testWidgets('shows empty state when no courses', (tester) async {
      await tester.pumpWidget(pumpApp(const CourseListPage()));
      await tester.pump();

      expect(find.text('No tienes cursos creados'), findsOneWidget);
    });

    testWidgets('shows FAB for teacher', (tester) async {
      await tester.pumpWidget(pumpApp(const CourseListPage()));
      await tester.pump();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('renders course cards', (tester) async {
      mockCourse.courses.assignAll(mockCourses());

      await tester.pumpWidget(pumpApp(const CourseListPage()));
      await tester.pump();

      expect(find.text('Desarrollo Móvil'), findsOneWidget);
      expect(find.text('Ingeniería de Software'), findsOneWidget);
    });

    testWidgets('shows loading spinner', (tester) async {
      mockCourse.isLoading.value = true;

      await tester.pumpWidget(pumpApp(const CourseListPage()));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows semester and student count on cards', (tester) async {
      mockCourse.courses.assignAll(mockCourses());

      await tester.pumpWidget(pumpApp(const CourseListPage()));
      await tester.pump();

      expect(
          find.text('2026-1 | 25 estudiantes | 2 categorías | 1 evaluaciones'),
          findsOneWidget);
      expect(
          find.text('2026-1 | 30 estudiantes | 1 categorías | 0 evaluaciones'),
          findsOneWidget);
    });
  });

  group('CourseListPage — student', () {
    setUp(() => mockAuth.setUser(mockStudent));

    testWidgets('shows student empty state text', (tester) async {
      await tester.pumpWidget(pumpApp(const CourseListPage()));
      await tester.pump();

      expect(
          find.text('No estás inscrito en ningún curso'), findsOneWidget);
    });

    testWidgets('hides FAB for student', (tester) async {
      await tester.pumpWidget(pumpApp(const CourseListPage()));
      await tester.pump();

      expect(find.byType(FloatingActionButton), findsNothing);
    });
  });
}
