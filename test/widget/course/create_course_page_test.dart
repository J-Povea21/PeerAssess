import 'package:f_clean_template/features/auth/ui/viewmodels/auth_controller.dart';
import 'package:f_clean_template/features/course/ui/viewmodels/course_controller.dart';
import 'package:f_clean_template/features/course/ui/views/create_course_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../helpers/test_helpers.dart';

void main() {
  late MockAuthController mockAuth;
  late MockCourseController mockCourse;

  setUp(() {
    mockAuth = MockAuthController();
    mockAuth.setUser(mockTeacher);
    mockCourse = MockCourseController();
    Get.put<AuthController>(mockAuth);
    Get.put<CourseController>(mockCourse);
  });

  tearDown(() => Get.reset());

  group('CreateCoursePage', () {
    testWidgets('renders course name field', (tester) async {
      await tester.pumpWidget(pumpApp(const CreateCoursePage()));
      await tester.pump();

      expect(find.text('Nombre del curso'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('renders semester dropdown', (tester) async {
      await tester.pumpWidget(pumpApp(const CreateCoursePage()));
      await tester.pump();

      expect(find.text('Semestre'), findsOneWidget);
      expect(find.text('2026-10'), findsOneWidget); // default selected
    });

    testWidgets('renders create button', (tester) async {
      await tester.pumpWidget(pumpApp(const CreateCoursePage()));
      await tester.pump();

      expect(
          find.widgetWithText(ElevatedButton, 'Crear curso'), findsOneWidget);
    });

    testWidgets('shows app bar with Crear curso title', (tester) async {
      await tester.pumpWidget(pumpApp(const CreateCoursePage()));
      await tester.pump();

      expect(find.text('Crear curso'), findsNWidgets(2)); // appBar + button
    });

    testWidgets('shows hint text in name field', (tester) async {
      await tester.pumpWidget(pumpApp(const CreateCoursePage()));
      await tester.pump();

      expect(find.text('Ej: Desarrollo Móvil'), findsOneWidget);
    });
  });
}
