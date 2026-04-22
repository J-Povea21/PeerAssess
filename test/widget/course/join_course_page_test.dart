import 'package:f_clean_template/features/course/ui/viewmodels/course_controller.dart';
import 'package:f_clean_template/features/enrollment/ui/views/join_course_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../helpers/test_helpers.dart';

void main() {
  late MockCourseController mockCourse;

  setUp(() {
    mockCourse = MockCourseController();
    Get.put<CourseController>(mockCourse);
  });

  tearDown(() => Get.reset());

  group('JoinCoursePage', () {
    testWidgets('renders code input field', (tester) async {
      await tester.pumpWidget(pumpApp(const JoinCoursePage()));
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('ABC123'), findsOneWidget); // hint text
    });

    testWidgets('renders title and subtitle', (tester) async {
      await tester.pumpWidget(pumpApp(const JoinCoursePage()));
      await tester.pump();

      expect(find.text('Ingresa el código del curso'), findsOneWidget);
      expect(find.text('Pide el código a tu profesor'), findsOneWidget);
    });

    testWidgets('renders join button', (tester) async {
      await tester.pumpWidget(pumpApp(const JoinCoursePage()));
      await tester.pump();

      expect(find.widgetWithText(ElevatedButton, 'Unirse al curso'),
          findsOneWidget);
    });

    testWidgets('shows app bar with correct title', (tester) async {
      await tester.pumpWidget(pumpApp(const JoinCoursePage()));
      await tester.pump();

      expect(find.text('Unirse a un curso'), findsOneWidget);
    });

    testWidgets('shows error snackbar when join returns null',
        (tester) async {
      // Default mock joinCourse returns null → error case
      await tester.pumpWidget(pumpApp(const JoinCoursePage()));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'INVALID');
      await tester.pump();

      await tester.tap(
          find.widgetWithText(ElevatedButton, 'Unirse al curso'));
      await tester.pumpAndSettle();

      expect(find.text('No se encontró un curso con ese código'),
          findsOneWidget);
    });
  });
}
