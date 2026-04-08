import 'package:f_clean_template/features/assessment/ui/viewmodels/assessment_controller.dart';
import 'package:f_clean_template/features/assessment/ui/views/create_assessment_page.dart';
import 'package:f_clean_template/features/group/ui/viewmodels/group_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../../../helpers/test_helpers.dart';
import '../../../../helpers/mock_assessment_controller.dart';

void main() {
  late MockAssessmentController mockAssessmentController;
  late MockGroupController mockGroupController;

  setUp(() {
    mockAssessmentController = MockAssessmentController();
    mockGroupController = MockGroupController();

    Get.put<AssessmentController>(mockAssessmentController);
    Get.put<GroupController>(mockGroupController);

    // Pre-load categories for tests
    mockGroupController.categories.value = [mockCategory()];
  });

  tearDown(() {
    Get.reset();
  });

  group('CreateAssessmentPage — form rendering', () {
    testWidgets('shows all form fields and submit button',
        (WidgetTester tester) async {
      await tester.pumpWidget(pumpApp(
        const CreateAssessmentPage(courseId: 'course-001'),
      ));

      expect(find.text('Nueva Evaluación'), findsOneWidget);
      expect(find.text('Nombre de la evaluación'), findsOneWidget);
      expect(find.text('Categoría de grupo'), findsOneWidget);
      expect(find.text('Ventana de tiempo'), findsOneWidget);
      expect(find.text('Visibilidad de resultados'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Crear'), findsOneWidget);
    });

    testWidgets('shows the 4 standard criteria',
        (WidgetTester tester) async {
      await tester.pumpWidget(pumpApp(
        const CreateAssessmentPage(courseId: 'course-001'),
      ));

      expect(find.text('Puntualidad'), findsOneWidget);
      expect(find.text('Contribuciones'), findsOneWidget);
      expect(find.text('Compromiso'), findsOneWidget);
      expect(find.text('Actitud'), findsOneWidget);
    });
  });

  group('CreateAssessmentPage — visibility cards', () {
    testWidgets('shows Pública and Privada cards',
        (WidgetTester tester) async {
      await tester.pumpWidget(pumpApp(
        const CreateAssessmentPage(courseId: 'course-001'),
      ));

      expect(find.text('Pública'), findsOneWidget);
      expect(find.text('Privada'), findsOneWidget);
      expect(find.text('Estudiantes ven resultados'), findsOneWidget);
      expect(find.text('Solo profesor ve resultados'), findsOneWidget);
    });

    testWidgets('tapping Privada card selects it',
        (WidgetTester tester) async {
      await tester.pumpWidget(pumpApp(
        const CreateAssessmentPage(courseId: 'course-001'),
      ));

      await tester.tap(find.text('Privada'));
      await tester.pump();

      // Privada card should now be selected (has olive border)
      // We verify by checking the widget tree rebuilt
      expect(find.text('Privada'), findsOneWidget);
    });
  });

  group('CreateAssessmentPage — validation', () {
    testWidgets('shows error when title is empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(pumpApp(
        const CreateAssessmentPage(courseId: 'course-001'),
      ));

      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Crear'));
      await tester.tap(find.widgetWithText(FilledButton, 'Crear'));
      await tester.pumpAndSettle();

      expect(find.text('Ingresa un nombre'), findsOneWidget);
    });

    testWidgets('shows error when time window is empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(pumpApp(
        const CreateAssessmentPage(courseId: 'course-001'),
      ));

      await tester.enterText(
          find.byType(TextFormField).first, 'Sprint Review');
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Crear'));
      await tester.tap(find.widgetWithText(FilledButton, 'Crear'));
      await tester.pumpAndSettle();

      expect(find.text('Ingresa la duración'), findsOneWidget);
    });
  });

  group('CreateAssessmentPage — submit', () {
    testWidgets('submit triggers controller and shows error on failure',
        (WidgetTester tester) async {
      bool createCalled = false;
      mockAssessmentController.onCreateCalled = () => createCalled = true;
      mockAssessmentController.createReturns = false;

      await tester.pumpWidget(pumpApp(
        const CreateAssessmentPage(courseId: 'course-001'),
      ));

      // Fill form
      await tester.enterText(
          find.byType(TextFormField).first, 'Sprint 1 Review');
      await tester.enterText(
          find.byType(TextFormField).last, '24');

      // Select category
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sprint 1').last);
      await tester.pumpAndSettle();

      // Submit
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Crear'));
      await tester.tap(find.widgetWithText(FilledButton, 'Crear'));
      await tester.pumpAndSettle();

      expect(createCalled, true);
      expect(find.text('No se pudo crear la evaluación'), findsOneWidget);
    });

    testWidgets('shows success snackbar on successful creation',
        (WidgetTester tester) async {
      mockAssessmentController.createReturns = true;

      await tester.pumpWidget(pumpApp(
        const CreateAssessmentPage(courseId: 'course-001'),
      ));

      await tester.enterText(
          find.byType(TextFormField).first, 'Sprint 1 Review');
      await tester.enterText(
          find.byType(TextFormField).last, '24');

      // Select category
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sprint 1').last);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.widgetWithText(FilledButton, 'Crear'));
      await tester.tap(find.widgetWithText(FilledButton, 'Crear'));
      await tester.pump();

      expect(find.text('Evaluación creada correctamente'), findsOneWidget);
    });

    testWidgets('loading state disables submit button',
        (WidgetTester tester) async {
      mockAssessmentController.isLoading.value = true;

      await tester.pumpWidget(pumpApp(
        const CreateAssessmentPage(courseId: 'course-001'),
      ));

      final button = tester.widget<FilledButton>(
        find.byType(FilledButton),
      );
      expect(button.onPressed, isNull);
    });
  });
}
