import 'package:f_clean_template/features/assessment/domain/models/assessment.dart';
import 'package:f_clean_template/features/assessment/domain/models/criteria.dart';
import 'package:f_clean_template/features/assessment/ui/viewmodels/evaluation_controller.dart';
import 'package:f_clean_template/features/assessment/ui/views/evaluation_form_page.dart';
import 'package:f_clean_template/features/auth/ui/viewmodels/auth_controller.dart';
import 'package:f_clean_template/features/group/domain/models/group_member.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../helpers/test_helpers.dart';

/// ══════════════════════════════════════════════════════════════════════
///  Flow — Student submits a peer evaluation
///  EvaluationFormPage → select scores for each peer & criterion → Enviar
///  → EvaluationController.submitAllEvaluations called → success snackbar
/// ══════════════════════════════════════════════════════════════════════
///
/// The real entry-point flow (AssessmentListPage → _startEvaluation) pulls
/// peers/criteria from RobleDbClient over the network. To keep this test
/// hermetic, we pump EvaluationFormPage directly with seeded data — the
/// business logic under test (scoring, navigation between peers, submit)
/// lives entirely on this page.
void main() {
  late MockAuthController mockAuth;
  late MockEvaluationController mockEvaluation;

  // Seeded assessment + criteria + peers for the form.
  final Assessment seededAssessment = Assessment(
    id: 'assess-001',
    categoryId: 'cat-001',
    title: 'Evaluación Sprint 1',
    visibility: 'public',
    timeWindowMinutes: 60,
    // No deadline → no countdown timer side-effects in tests.
  );

  final List<Criteria> seededCriteria = [
    Criteria(id: 'crit-001', name: 'Puntualidad', weight: 1.0),
    Criteria(id: 'crit-002', name: 'Contribuciones', weight: 1.0),
  ];

  final List<GroupMember> seededPeers = [
    GroupMember(
      id: 'peer-001',
      firstName: 'Carlos',
      lastName: 'Ruiz',
      email: 'cruiz@uninorte.edu.co',
    ),
    GroupMember(
      id: 'peer-002',
      firstName: 'Ana',
      lastName: 'Torres',
      email: 'atorres@uninorte.edu.co',
    ),
  ];

  setUp(() {
    mockAuth = MockAuthController();
    mockEvaluation = MockEvaluationController();

    // Student is logged in.
    mockAuth.setUser(mockStudent);
    // Seed pending evaluations on the controller so the rest of the UI
    // would also reflect a pending state if queried.
    mockEvaluation.setPendingAssessments([seededAssessment]);

    Get.put<AuthController>(mockAuth);
    Get.put<EvaluationController>(mockEvaluation);
  });

  tearDown(() => Get.reset());

  group('Flow — Student submit peer evaluation', () {
    testWidgets(
        'fill scores for every peer & criterion → submit → controller called',
        (tester) async {
      // ── 1. Pump EvaluationFormPage directly ───────────────────────
      await tester.pumpWidget(pumpApp(EvaluationFormPage(
        assessment: seededAssessment,
        peers: seededPeers,
        criteria: seededCriteria,
        evaluatorId: mockStudent.id ?? 'student-001',
      )));
      await tester.pumpAndSettle();

      // AppBar shows the first peer's name
      expect(find.text('Evaluar a Carlos Ruiz'), findsOneWidget);

      // Both criteria cards are rendered for the current peer
      expect(find.text('Puntualidad'), findsOneWidget);
      expect(find.text('Contribuciones'), findsOneWidget);

      // ── 2. Score the first peer on both criteria (score = 5) ──────
      // Each criterion card renders score buttons [2, 3, 4, 5]. We tap
      // every "5" found — one per criterion card.
      await _tapEveryScore(tester, '5');

      // "Siguiente" becomes enabled only when all criteria for the current
      // peer are scored.
      final nextBtn = find.widgetWithText(FilledButton, 'Siguiente');
      expect(nextBtn, findsOneWidget);
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      // ── 3. Now on second peer ─────────────────────────────────────
      expect(find.text('Evaluar a Ana Torres'), findsOneWidget);

      // Score the second peer on both criteria (score = 4).
      await _tapEveryScore(tester, '4');

      // ── 4. Wire the submit callback and tap "Enviar" ──────────────
      bool submitWasCalled = false;
      mockEvaluation.onSubmitCalled = () {
        submitWasCalled = true;
      };
      mockEvaluation.submitReturns = true;

      final submitBtn = find.widgetWithText(FilledButton, 'Enviar');
      expect(submitBtn, findsOneWidget);
      await tester.tap(submitBtn);
      // Pump once so the async _submit kicks off; then settle animations.
      await tester.pump();
      await tester.pumpAndSettle();

      // ── 5. Assert submitAllEvaluations was invoked on the mock ────
      expect(submitWasCalled, isTrue,
          reason:
              'EvaluationController.submitAllEvaluations should be called');

      // ── 6. Success snackbar is shown ──────────────────────────────
      expect(
        find.text('Evaluaciones enviadas correctamente'),
        findsOneWidget,
      );
    });

    testWidgets('"Siguiente" is disabled until the current peer is complete',
        (tester) async {
      await tester.pumpWidget(pumpApp(EvaluationFormPage(
        assessment: seededAssessment,
        peers: seededPeers,
        criteria: seededCriteria,
        evaluatorId: mockStudent.id ?? 'student-001',
      )));
      await tester.pumpAndSettle();

      // No scores picked yet → "Siguiente" is rendered but disabled.
      final nextBtn = find.widgetWithText(FilledButton, 'Siguiente');
      expect(nextBtn, findsOneWidget);
      final FilledButton btn = tester.widget(nextBtn);
      expect(btn.onPressed, isNull);
    });

    testWidgets('failed submission shows error snackbar and stays on form',
        (tester) async {
      await tester.pumpWidget(pumpApp(EvaluationFormPage(
        assessment: seededAssessment,
        peers: seededPeers,
        criteria: seededCriteria,
        evaluatorId: mockStudent.id ?? 'student-001',
      )));
      await tester.pumpAndSettle();

      // Score both criteria on peer 1
      await _tapEveryScore(tester, '5');
      await tester.tap(find.widgetWithText(FilledButton, 'Siguiente'));
      await tester.pumpAndSettle();

      // Score both criteria on peer 2
      await _tapEveryScore(tester, '3');

      // Configure the mock to fail
      mockEvaluation.submitReturns = false;

      await tester.tap(find.widgetWithText(FilledButton, 'Enviar'));
      await tester.pump();
      await tester.pumpAndSettle();

      // Error snackbar is shown and the form is still on screen.
      expect(find.text('Error al enviar las evaluaciones'), findsOneWidget);
      expect(find.byType(EvaluationFormPage), findsOneWidget);
    });
  });
}

/// Taps every score button with the given [scoreLabel] on the current peer's
/// evaluation form.
///
/// The form renders one GestureDetector per score (per criterion card). We
/// target the GestureDetector ancestor of each score Text so the hit-test
/// lands on the tap-handler directly — tapping the Text itself sometimes
/// misses because its bounding box is narrower than the 48x48 circle.
Future<void> _tapEveryScore(WidgetTester tester, String scoreLabel) async {
  // Snapshot the current set of score Texts before tapping. Each tap
  // triggers setState → rebuild, so we capture once and iterate by index.
  final count = find.text(scoreLabel).evaluate().length;
  for (int i = 0; i < count; i++) {
    // After the first tap, the same GestureDetector is still present but
    // we re-resolve the finder each loop to account for rebuilds.
    final target = find
        .ancestor(
          of: find.text(scoreLabel),
          matching: find.byType(GestureDetector),
        )
        .at(i);
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target, warnIfMissed: false);
    await tester.pump();
  }
}
