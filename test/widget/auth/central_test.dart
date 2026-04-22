import 'package:f_clean_template/central.dart';
import 'package:f_clean_template/features/analytics/ui/viewmodels/analytics_controller.dart';
import 'package:f_clean_template/features/auth/ui/viewmodels/auth_controller.dart';
import 'package:f_clean_template/features/course/ui/viewmodels/course_controller.dart';
import 'package:f_clean_template/features/group/ui/viewmodels/group_controller.dart';
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

  group('Central', () {
    testWidgets('shows SplashPage when restoring session', (tester) async {
      mockAuth.isRestoringSession.value = true;

      await tester.pumpWidget(pumpApp(const Central()));
      await tester.pump();

      // SplashPage shows the app name
      expect(find.text('PeerAssess'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows LoginPage when no session', (tester) async {
      mockAuth.isRestoringSession.value = false;
      // No user set → isLogged is false

      await tester.pumpWidget(pumpApp(const Central()));
      await tester.pump();

      expect(find.text('Iniciar sesión'), findsOneWidget);
    });

    testWidgets('routes to TeacherHomePage for teacher role',
        (tester) async {
      mockAuth.isRestoringSession.value = false;
      mockAuth.setUser(mockTeacher);

      await tester.pumpWidget(pumpApp(const Central()));
      await tester.pump();

      // TeacherHomePage has bottom nav with 'Analíticas'
      expect(find.text('Analíticas'), findsOneWidget);
      expect(find.text('Inicio'), findsOneWidget);
    });

    testWidgets('routes to StudentHomePage for student role',
        (tester) async {
      mockAuth.isRestoringSession.value = false;
      mockAuth.setUser(mockStudent);

      await tester.pumpWidget(pumpApp(const Central()));
      await tester.pump();

      // StudentHomePage has bottom nav with 'Resultados'
      expect(find.text('Resultados'), findsOneWidget);
      expect(find.text('Inicio'), findsOneWidget);
    });
  });
}
