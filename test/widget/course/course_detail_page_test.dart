import 'package:f_clean_template/features/auth/ui/viewmodels/auth_controller.dart';
import 'package:f_clean_template/features/course/ui/viewmodels/course_controller.dart';
import 'package:f_clean_template/features/course/ui/views/course_detail_page.dart';
import 'package:f_clean_template/features/group/ui/viewmodels/group_controller.dart';
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

  group('CourseDetailPage', () {
    testWidgets('renders 4 tabs: Info, Categorías, Evaluaciones, Miembros',
        (tester) async {
      final course = mockCourses().first;
      mockCourse.courses.assignAll(mockCourses());

      await tester.pumpWidget(pumpApp(CourseDetailPage(course: course)));
      await tester.pump();

      expect(find.text('Info'), findsOneWidget);
      // "Categorías" appears in both tab label and stats card
      expect(find.byType(Tab), findsNWidgets(4));
      expect(find.text('Miembros'), findsOneWidget);
    });

    testWidgets('shows enrollment code on Info tab', (tester) async {
      final course = mockCourses().first; // enrollmentCode: 'ABC123'
      mockCourse.courses.assignAll(mockCourses());

      await tester.pumpWidget(pumpApp(CourseDetailPage(course: course)));
      await tester.pump();

      expect(find.text('ABC123'), findsOneWidget);
      expect(find.text('Código de inscripción'), findsOneWidget);
    });

    testWidgets('shows stats cards with correct values', (tester) async {
      final course = mockCourses().first;
      mockCourse.courses.assignAll(mockCourses());

      await tester.pumpWidget(pumpApp(CourseDetailPage(course: course)));
      await tester.pump();

      // studentCount=25, categoryCount=2, evaluationCount=1
      expect(find.text('25'), findsOneWidget);
      expect(find.text('Estudiantes'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Categorías'), findsNWidgets(2)); // tab + stat
      expect(find.text('1'), findsOneWidget);
      expect(find.text('Evaluaciones'), findsNWidgets(2)); // tab + stat
    });

    testWidgets('shows course name in app bar', (tester) async {
      final course = mockCourses().first;
      mockCourse.courses.assignAll(mockCourses());

      await tester.pumpWidget(pumpApp(CourseDetailPage(course: course)));
      await tester.pump();

      // Course name appears in AppBar and in the info card
      expect(find.text('Desarrollo Móvil'), findsNWidgets(2));
    });

  });
}
