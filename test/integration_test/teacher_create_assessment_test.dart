import 'package:f_clean_template/features/analytics/ui/viewmodels/analytics_controller.dart';
import 'package:f_clean_template/features/assessment/domain/models/assessment.dart';
import 'package:f_clean_template/features/assessment/ui/viewmodels/assessment_controller.dart';
import 'package:f_clean_template/features/assessment/ui/viewmodels/evaluation_controller.dart';
import 'package:f_clean_template/features/assessment/ui/views/create_assessment_page.dart';
import 'package:f_clean_template/features/auth/ui/viewmodels/auth_controller.dart';
import 'package:f_clean_template/features/course/domain/models/course.dart';
import 'package:f_clean_template/features/course/ui/viewmodels/course_controller.dart';
import 'package:f_clean_template/features/course/ui/views/course_detail_page.dart';
import 'package:f_clean_template/features/group/ui/viewmodels/group_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../helpers/test_helpers.dart';

/// ══════════════════════════════════════════════════════════════════════
///  Flow — Teacher creates an assessment
///  CourseDetailPage → Evaluaciones tab → FAB → CreateAssessmentPage →
///  fill form → submit → AssessmentController.createAssessment called
/// ══════════════════════════════════════════════════════════════════════
///
/// Follows the same mocked-GetX pattern as professor_login_flow_test.dart.
/// Starts pre-authenticated as a teacher and pumps CourseDetailPage
/// directly so the test focuses on the create-assessment flow rather
/// than login + tab routing (already covered elsewhere).
void main() {
  late MockAuthController mockAuth;
  late MockCourseController mockCourse;
  late MockGroupController mockGroup;
  late MockAnalyticsController mockAnalytics;
  late MockAssessmentController mockAssessment;
  late MockEvaluationController mockEvaluation;

  final Course testCourse = mockCourses().first;

  setUp(() {
    mockAuth = MockAuthController();
    mockCourse = MockCourseController();
    mockGroup = MockGroupController();
    mockAnalytics = MockAnalyticsController();
    mockAssessment = MockAssessmentController();
    mockEvaluation = MockEvaluationController();

    // Seed: teacher is logged in and has a course.
    mockAuth.setUser(mockTeacher);
    mockCourse.courses.assignAll(<Course>[testCourse]);
    // Seed a category so the create-assessment dropdown can pick one.
    mockGroup.categories.assignAll([mockCategory()]);

    Get.put<AuthController>(mockAuth);
    Get.put<CourseController>(mockCourse);
    Get.put<GroupController>(mockGroup);
    Get.put<AnalyticsController>(mockAnalytics);
    Get.put<AssessmentController>(mockAssessment);
    Get.put<EvaluationController>(mockEvaluation);
  });

  tearDown(() => Get.reset());

  group('Flow — Teacher create assessment', () {
    testWidgets(
        'open Evaluaciones tab → FAB → fill form → createAssessment called',
        (tester) async {
      // ── 1. Pump CourseDetailPage for the seeded course ────────────
      await tester.pumpWidget(pumpApp(CourseDetailPage(course: testCourse)));
      await tester.pumpAndSettle();

      // Tabs rendered by CourseDetailPage. There may be additional
      // "Evaluaciones" labels elsewhere (e.g. the Info tab stats card), so
      // we target the TabBar descendant specifically.
      final evaluacionesTab = find.descendant(
        of: find.byType(TabBar),
        matching: find.text('Evaluaciones'),
      );
      expect(evaluacionesTab, findsOneWidget);

      // ── 2. Switch to the Evaluaciones tab ─────────────────────────
      await tester.tap(evaluacionesTab);
      await tester.pumpAndSettle();

      // Teacher-only FAB is visible on the assessments tab
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // ── 3. Tap the FAB → CreateAssessmentPage opens ───────────────
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.byType(CreateAssessmentPage), findsOneWidget);
      expect(find.text('Nueva Evaluación'), findsOneWidget);

      // ── 4. Fill form fields ───────────────────────────────────────
      // Title (first text field on the form)
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Sprint 3 Evaluación'),
        'Evaluación de prueba',
      );

      // Pick a category from the dropdown
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      // Tap the first category option (seeded via mockCategory())
      await tester.tap(find.text('Sprint 1').last);
      await tester.pumpAndSettle();

      // Time window
      await tester.enterText(
        find.widgetWithText(TextFormField, '60'),
        '45',
      );

      // Visibility — tap "Privada" then "Pública" to exercise the toggle;
      // leave on Pública (default), but tap it explicitly to confirm tap works.
      await tester.tap(find.text('Privada'));
      await tester.pump();
      await tester.tap(find.text('Pública'));
      await tester.pump();

      // ── 5. Wire the create callback and submit ────────────────────
      bool createWasCalled = false;
      mockAssessment.onCreateCalled = () {
        createWasCalled = true;
      };
      mockAssessment.createReturns = true;

      // Scroll to the submit button if needed, then tap it.
      final submitButton = find.widgetWithText(FilledButton, 'Crear');
      await tester.ensureVisible(submitButton);
      await tester.pumpAndSettle();
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // ── 6. Assert createAssessment was invoked ────────────────────
      expect(createWasCalled, isTrue,
          reason: 'AssessmentController.createAssessment should be called');

      // ── 7. After success, the create page pops back to the detail ─
      expect(find.byType(CreateAssessmentPage), findsNothing);
      expect(find.byType(CourseDetailPage), findsOneWidget);
    });

    testWidgets('FAB is hidden for students on the Evaluaciones tab',
        (tester) async {
      // Switch to a student persona
      mockAuth.setUser(mockStudent);

      await tester.pumpWidget(pumpApp(CourseDetailPage(course: testCourse)));
      await tester.pumpAndSettle();

      await tester.tap(find.descendant(
        of: find.byType(TabBar),
        matching: find.text('Evaluaciones'),
      ));
      await tester.pumpAndSettle();

      // Students must NOT see the create-assessment FAB
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('seeded assessment card renders its title in the list',
        (tester) async {
      mockAssessment.setAssessments([
        Assessment(
          categoryId: 'cat-001',
          title: 'Sprint 1 Review',
          visibility: 'public',
          timeWindowMinutes: 60,
        ),
      ]);

      await tester.pumpWidget(pumpApp(CourseDetailPage(course: testCourse)));
      await tester.pumpAndSettle();

      await tester.tap(find.descendant(
        of: find.byType(TabBar),
        matching: find.text('Evaluaciones'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Sprint 1 Review'), findsOneWidget);
      expect(find.text('No hay evaluaciones'), findsNothing);
    });

    testWidgets('createReturns=false shows error — does not pop back',
        (tester) async {
      mockAssessment.createReturns = false;
      mockGroup.categories.assignAll([mockCategory()]);

      await tester.pumpWidget(pumpApp(CourseDetailPage(course: testCourse)));
      await tester.pumpAndSettle();

      await tester.tap(find.descendant(
        of: find.byType(TabBar),
        matching: find.text('Evaluaciones'),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Sprint 3 Evaluación'),
        'Error test',
      );

      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sprint 1').last);
      await tester.pumpAndSettle();

      final submitButton = find.widgetWithText(FilledButton, 'Crear');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // On failure the page stays open — no pop back to CourseDetailPage.
      expect(find.byType(CreateAssessmentPage), findsOneWidget);
    });

    testWidgets('empty title triggers validator — createAssessment not called',
        (tester) async {
      bool createWasCalled = false;
      mockAssessment.onCreateCalled = () => createWasCalled = true;

      await tester.pumpWidget(pumpApp(CourseDetailPage(course: testCourse)));
      await tester.pumpAndSettle();

      await tester.tap(find.descendant(
        of: find.byType(TabBar),
        matching: find.text('Evaluaciones'),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Leave title empty — tap submit immediately.
      final submitButton = find.widgetWithText(FilledButton, 'Crear');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Validator fires — createAssessment must NOT be called.
      expect(createWasCalled, isFalse);
      expect(find.byType(CreateAssessmentPage), findsOneWidget);
    });
  });
}
