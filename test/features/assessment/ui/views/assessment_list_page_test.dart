import 'package:f_clean_template/features/assessment/domain/models/assessment.dart';
import 'package:f_clean_template/features/assessment/ui/viewmodels/assessment_controller.dart';
import 'package:f_clean_template/features/assessment/ui/viewmodels/evaluation_controller.dart';
import 'package:f_clean_template/features/assessment/ui/views/assessment_list_page.dart';
import 'package:f_clean_template/features/auth/ui/viewmodels/auth_controller.dart';
import 'package:f_clean_template/features/group/ui/viewmodels/group_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../../../helpers/test_helpers.dart';
import '../../../../helpers/mock_assessment_controller.dart';
import '../../../../helpers/mock_evaluation_controller.dart';

void main() {
  late MockAssessmentController mockAssessmentController;
  late MockAuthController mockAuthController;

  setUp(() {
    mockAssessmentController = MockAssessmentController();
    mockAuthController = MockAuthController();

    Get.put<AssessmentController>(mockAssessmentController);
    Get.put<AuthController>(mockAuthController);
    Get.put<GroupController>(MockGroupController());
    Get.put<EvaluationController>(MockEvaluationController());
  });

  tearDown(() {
    Get.reset();
  });

  group('AssessmentListPage — empty state', () {
    testWidgets('shows empty message when no assessments',
        (WidgetTester tester) async {
      mockAuthController.setUser(mockTeacher);

      await tester.pumpWidget(pumpApp(
        const AssessmentListPage(
          courseId: 'course-001',
          categoryId: 'cat-001',
        ),
      ));

      expect(find.text('No hay evaluaciones'), findsOneWidget);
    });
  });

  group('AssessmentListPage — list rendering', () {
    testWidgets('shows assessment cards with title and status',
        (WidgetTester tester) async {
      mockAuthController.setUser(mockTeacher);
      mockAssessmentController.setAssessments([
        Assessment(
          id: 'a-001',
          categoryId: 'cat-001',
          title: 'Sprint 1 Review',
          visibility: 'public',
          timeWindowMinutes: 60,
          status: 'active',
          deadline: DateTime.now().add(const Duration(days: 1)),
        ),
        Assessment(
          id: 'a-002',
          categoryId: 'cat-001',
          title: 'Sprint 2 Review',
          visibility: 'private',
          timeWindowMinutes: 120,
          deadline: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ]);

      await tester.pumpWidget(pumpApp(
        const AssessmentListPage(
          courseId: 'course-001',
          categoryId: 'cat-001',
        ),
      ));

      expect(find.text('Sprint 1 Review'), findsOneWidget);
      expect(find.text('Sprint 2 Review'), findsOneWidget);
      expect(find.text('Activa'), findsOneWidget);
      expect(find.text('Cerrada'), findsOneWidget);
    });

    testWidgets('shows visibility info on cards',
        (WidgetTester tester) async {
      mockAuthController.setUser(mockTeacher);
      mockAssessmentController.setAssessments([
        Assessment(
          id: 'a-001',
          categoryId: 'cat-001',
          title: 'Public Assessment',
          visibility: 'public',
          timeWindowMinutes: 60,
        ),
      ]);

      await tester.pumpWidget(pumpApp(
        const AssessmentListPage(
          courseId: 'course-001',
          categoryId: 'cat-001',
        ),
      ));

      expect(find.text('Pública'), findsOneWidget);
    });
  });

  group('AssessmentListPage — loading state', () {
    testWidgets('shows loading indicator when isLoading is true',
        (WidgetTester tester) async {
      mockAuthController.setUser(mockTeacher);
      mockAssessmentController.isLoading.value = true;

      await tester.pumpWidget(pumpApp(
        const AssessmentListPage(
          courseId: 'course-001',
          categoryId: 'cat-001',
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('AssessmentListPage — FAB visibility', () {
    testWidgets('shows FAB for teacher', (WidgetTester tester) async {
      mockAuthController.setUser(mockTeacher);

      await tester.pumpWidget(pumpApp(
        const AssessmentListPage(
          courseId: 'course-001',
          categoryId: 'cat-001',
        ),
      ));

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('hides FAB for student', (WidgetTester tester) async {
      mockAuthController.setUser(mockStudent);

      await tester.pumpWidget(pumpApp(
        const AssessmentListPage(
          courseId: 'course-001',
          categoryId: 'cat-001',
        ),
      ));

      expect(find.byType(FloatingActionButton), findsNothing);
    });
  });
}
