import 'package:f_clean_template/features/analytics/ui/viewmodels/analytics_controller.dart';
import 'package:f_clean_template/features/auth/ui/viewmodels/auth_controller.dart';
import 'package:f_clean_template/features/course/ui/viewmodels/course_controller.dart';
import 'package:f_clean_template/features/group/ui/viewmodels/group_controller.dart';
import 'package:f_clean_template/features/home/ui/views/student_home_page.dart';
import 'package:f_clean_template/features/reflection/ui/viewmodels/reflection_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../helpers/test_helpers.dart';

void main() {
  late MockAuthController mockAuth;
  late MockCourseController mockCourse;
  late MockGroupController mockGroup;
  late MockAnalyticsController mockAnalytics;
  late MockReflectionController mockReflection;

  setUp(() {
    mockAuth = MockAuthController();
    mockAuth.setUser(mockStudent);
    mockCourse = MockCourseController();
    mockGroup = MockGroupController();
    mockAnalytics = MockAnalyticsController();
    mockReflection = MockReflectionController();
    Get.put<AuthController>(mockAuth);
    Get.put<CourseController>(mockCourse);
    Get.put<GroupController>(mockGroup);
    Get.put<AnalyticsController>(mockAnalytics);
    Get.put<ReflectionController>(mockReflection);
  });

  tearDown(() => Get.reset());

  group('StudentHomePage', () {
    testWidgets('renders 4 bottom navigation tabs', (tester) async {
      await tester.pumpWidget(pumpApp(const StudentHomePage()));
      await tester.pumpAndSettle();

      expect(find.text('Inicio'), findsOneWidget);
      expect(find.text('Cursos'), findsOneWidget);
      expect(find.text('Resultados'), findsOneWidget);
      expect(find.text('Perfil'), findsOneWidget);
    });

    testWidgets('shows student name on dashboard', (tester) async {
      await tester.pumpWidget(pumpApp(const StudentHomePage()));
      await tester.pumpAndSettle();

      expect(find.text('María López'), findsAtLeastNWidgets(1));
      expect(find.text('Hola'), findsOneWidget);
    });

    testWidgets('shows empty course state', (tester) async {
      await tester.pumpWidget(pumpApp(const StudentHomePage()));
      await tester.pumpAndSettle();

      expect(find.text('No estás inscrito en ningún curso'),
          findsAtLeastNWidgets(1));
    });

    testWidgets('shows pending evaluation banner when applicable',
        (tester) async {
      mockCourse.courses.assignAll([mockCourseWithPending()]);

      await tester.pumpWidget(pumpApp(const StudentHomePage()));
      await tester.pumpAndSettle();

      expect(find.text('Evaluación pendiente'), findsOneWidget);
    });

    testWidgets('shows MIS CURSOS section header', (tester) async {
      await tester.pumpWidget(pumpApp(const StudentHomePage()));
      await tester.pumpAndSettle();

      expect(find.text('MIS CURSOS'), findsOneWidget);
    });

    testWidgets('shows FAB on dashboard tab', (tester) async {
      await tester.pumpWidget(pumpApp(const StudentHomePage()));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('renders course cards when courses exist', (tester) async {
      mockCourse.courses.assignAll(mockCourses());

      await tester.pumpWidget(pumpApp(const StudentHomePage()));
      await tester.pumpAndSettle();

      expect(find.text('Desarrollo Móvil'), findsAtLeastNWidgets(1));
    });
  });
}
