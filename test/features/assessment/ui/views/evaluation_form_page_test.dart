import 'package:f_clean_template/features/assessment/domain/models/assessment.dart';
import 'package:f_clean_template/features/assessment/domain/models/criteria.dart';
import 'package:f_clean_template/features/assessment/ui/viewmodels/evaluation_controller.dart';
import 'package:f_clean_template/features/assessment/ui/views/evaluation_form_page.dart';
import 'package:f_clean_template/features/group/domain/models/group_member.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../../../helpers/test_helpers.dart';
import '../../../../helpers/mock_evaluation_controller.dart';

void main() {
  late MockEvaluationController mockEvaluationController;

  final testAssessment = Assessment(
    id: 'a-001',
    categoryId: 'cat-001',
    title: 'Sprint 1 Review',
    visibility: 'public',
    timeWindowMinutes: 60,
    status: 'active',
  );

  final testPeers = [
    GroupMember(
        id: 'gm-002',
        firstName: 'Carlos',
        lastName: 'Ruiz',
        email: 'cruiz@uninorte.edu.co'),
    GroupMember(
        id: 'gm-003',
        firstName: 'Ana',
        lastName: 'Torres',
        email: 'atorres@uninorte.edu.co'),
  ];

  // Use only 2 criteria in tests that need score selection,
  // so all score buttons fit on screen without scrolling.
  final shortCriteria = [
    Criteria(id: 'c-001', assessmentId: 'a-001', name: 'Puntualidad', weight: 1.0),
    Criteria(id: 'c-002', assessmentId: 'a-001', name: 'Contribuciones', weight: 1.0),
  ];

  final fullCriteria = [
    Criteria(id: 'c-001', assessmentId: 'a-001', name: 'Puntualidad', weight: 1.0),
    Criteria(id: 'c-002', assessmentId: 'a-001', name: 'Contribuciones', weight: 1.0),
    Criteria(id: 'c-003', assessmentId: 'a-001', name: 'Compromiso', weight: 1.0),
    Criteria(id: 'c-004', assessmentId: 'a-001', name: 'Actitud', weight: 1.0),
  ];

  setUp(() {
    mockEvaluationController = MockEvaluationController();
    Get.put<EvaluationController>(mockEvaluationController);
  });

  tearDown(() {
    Get.reset();
  });

  group('EvaluationFormPage — peer display', () {
    testWidgets('shows first peer name, progress, and criteria',
        (WidgetTester tester) async {
      await tester.pumpWidget(pumpApp(
        EvaluationFormPage(
          assessment: testAssessment,
          peers: testPeers,
          criteria: fullCriteria,
          evaluatorId: 'student-001',
        ),
      ));

      // AppBar title
      expect(find.text('Evaluar a Carlos Ruiz'), findsOneWidget);
      // Peer avatar name
      expect(find.text('Carlos Ruiz'), findsOneWidget);
      // Progress
      expect(find.text('Compañero 1 de 2'), findsOneWidget);
      // First criteria always visible
      expect(find.text('Puntualidad'), findsOneWidget);
      expect(find.text('Asistencia y puntualidad a sesiones'), findsOneWidget);
    });

    testWidgets('shows all criteria when scrolled',
        (WidgetTester tester) async {
      await tester.pumpWidget(pumpApp(
        EvaluationFormPage(
          assessment: testAssessment,
          peers: testPeers,
          criteria: fullCriteria,
          evaluatorId: 'student-001',
        ),
      ));

      // Scroll down to reveal all criteria
      await tester.scrollUntilVisible(find.text('Actitud'), 200);
      expect(find.text('Actitud'), findsOneWidget);
    });
  });

  group('EvaluationFormPage — score selection', () {
    testWidgets('selecting a score shows description label',
        (WidgetTester tester) async {
      await tester.pumpWidget(pumpApp(
        EvaluationFormPage(
          assessment: testAssessment,
          peers: testPeers,
          criteria: shortCriteria,
          evaluatorId: 'student-001',
        ),
      ));

      // Tap score "5" on the first criteria
      await tester.tap(find.text('5').first);
      await tester.pump();

      expect(find.text('Excelente'), findsOneWidget);
    });
  });

  group('EvaluationFormPage — peer navigation', () {
    testWidgets('Siguiente button navigates to next peer',
        (WidgetTester tester) async {
      await tester.pumpWidget(pumpApp(
        EvaluationFormPage(
          assessment: testAssessment,
          peers: testPeers,
          criteria: shortCriteria,
          evaluatorId: 'student-001',
        ),
      ));

      // Select score for first criteria
      await tester.tap(find.text('4').at(0));
      await tester.pump();

      // Scroll to second criteria and select score
      await tester.ensureVisible(find.text('4').at(1));
      await tester.pump();
      await tester.tap(find.text('4').at(1));
      await tester.pump();

      // Tap Siguiente
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Siguiente'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Siguiente'));
      await tester.pump();

      expect(find.text('Evaluar a Ana Torres'), findsOneWidget);
      expect(find.text('Compañero 2 de 2'), findsOneWidget);
    });

    testWidgets('Anterior button goes back to previous peer',
        (WidgetTester tester) async {
      await tester.pumpWidget(pumpApp(
        EvaluationFormPage(
          assessment: testAssessment,
          peers: testPeers,
          criteria: shortCriteria,
          evaluatorId: 'student-001',
        ),
      ));

      // Select score for first criteria
      await tester.tap(find.text('4').at(0));
      await tester.pump();

      // Scroll to second criteria and select score
      await tester.ensureVisible(find.text('4').at(1));
      await tester.pump();
      await tester.tap(find.text('4').at(1));
      await tester.pump();

      // Navigate to peer 2
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Siguiente'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Siguiente'));
      await tester.pump();

      expect(find.text('Compañero 2 de 2'), findsOneWidget);

      // Go back
      await tester.tap(find.widgetWithText(OutlinedButton, 'Anterior'));
      await tester.pump();

      expect(find.text('Compañero 1 de 2'), findsOneWidget);
    });

    testWidgets('Siguiente is disabled when scores incomplete',
        (WidgetTester tester) async {
      await tester.pumpWidget(pumpApp(
        EvaluationFormPage(
          assessment: testAssessment,
          peers: testPeers,
          criteria: shortCriteria,
          evaluatorId: 'student-001',
        ),
      ));

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Siguiente'),
      );
      expect(button.onPressed, isNull);
    });
  });

  group('EvaluationFormPage — submit', () {
    testWidgets('last peer shows Enviar and triggers controller',
        (WidgetTester tester) async {
      bool submitCalled = false;
      mockEvaluationController.onSubmitCalled = () => submitCalled = true;
      mockEvaluationController.submitReturns = false;

      final singlePeer = [testPeers.first];

      await tester.pumpWidget(pumpApp(
        EvaluationFormPage(
          assessment: testAssessment,
          peers: singlePeer,
          criteria: shortCriteria,
          evaluatorId: 'student-001',
        ),
      ));

      // Select all scores
      await tester.tap(find.text('5').at(0));
      await tester.pump();

      await tester.ensureVisible(find.text('5').at(1));
      await tester.pump();
      await tester.tap(find.text('5').at(1));
      await tester.pump();

      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Enviar'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Enviar'));
      await tester.pumpAndSettle();

      expect(submitCalled, true);
    });

    testWidgets('loading state disables Enviar button',
        (WidgetTester tester) async {
      mockEvaluationController.isLoading.value = true;

      final singlePeer = [testPeers.first];

      await tester.pumpWidget(pumpApp(
        EvaluationFormPage(
          assessment: testAssessment,
          peers: singlePeer,
          criteria: shortCriteria,
          evaluatorId: 'student-001',
        ),
      ));

      final button = tester.widget<FilledButton>(
        find.byType(FilledButton),
      );
      expect(button.onPressed, isNull);
    });
  });
}
