import 'package:f_clean_template/central.dart';
import 'package:f_clean_template/core/models/user.dart';
import 'package:f_clean_template/features/analytics/ui/viewmodels/analytics_controller.dart';
import 'package:f_clean_template/features/auth/ui/viewmodels/auth_controller.dart';
import 'package:f_clean_template/features/auth/ui/views/login_page.dart';
import 'package:f_clean_template/features/course/domain/models/course.dart';
import 'package:f_clean_template/features/course/ui/viewmodels/course_controller.dart';
import 'package:f_clean_template/features/course/ui/views/course_list_page.dart';
import 'package:f_clean_template/features/group/ui/viewmodels/group_controller.dart';
import 'package:f_clean_template/features/home/ui/views/student_home_page.dart';
import 'package:f_clean_template/features/reflection/ui/viewmodels/reflection_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../helpers/test_helpers.dart';

/// ══════════════════════════════════════════════════════════════════════
///  Flow B — Student
///  App launch → login → student dashboard → course list → course card
/// ══════════════════════════════════════════════════════════════════════
///
/// Same pattern as [professor_login_flow_test.dart] — mirrors the
/// reference repo (`f_web_authentication/test/widget_test/login_page_test`)
/// in how it mocks controllers, and mirrors `level3_fullstack_test.dart`
/// in how it walks the full UI flow starting from [Central].
///
/// Test credentials (placeholders — no real backend call is made):
const String _kStudentEmail = 'student@uninorte.edu.co';
const String _kStudentPassword = 'student-password';

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

  group('Flow B — Student', () {
    testWidgets(
        'launch → login → student dashboard → course list → course card',
        (tester) async {
      // ── 1. App launches → login screen appears ────────────────────
      await tester.pumpWidget(pumpApp(const Central()));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.text('PeerAssess'), findsOneWidget);
      expect(find.text('Correo institucional'), findsOneWidget);
      expect(find.text('Contraseña'), findsOneWidget);

      // ── 2. Log in with student credentials ────────────────────────
      await tester.enterText(find.byType(TextField).first, _kStudentEmail);
      await tester.enterText(find.byType(TextField).last, _kStudentPassword);
      await tester.pump();

      // Tap the login button while still on LoginPage. The mock's login()
      // returns true without a real HTTP call; we then flip the user so
      // Central's Obx re-renders into StudentHomePage.
      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Iniciar sesión'),
      );
      await tester.pump();

      mockAuth.setUser(mockStudent);
      await tester.pumpAndSettle();

      // ── 3. Dashboard loads with student UI ────────────────────────
      expect(find.byType(StudentHomePage), findsOneWidget);

      // Student greeting + name
      expect(find.text('Hola'), findsOneWidget);
      expect(find.text('María López'), findsAtLeastNWidgets(1));

      // MIS CURSOS section header
      expect(find.text('MIS CURSOS'), findsOneWidget);

      // RESULTADOS RECIENTES with empty state
      expect(find.text('RESULTADOS RECIENTES'), findsOneWidget);

      // Bottom navigation shows the 4 student tabs
      expect(find.text('Inicio'), findsOneWidget);
      expect(find.text('Cursos'), findsOneWidget);
      expect(find.text('Resultados'), findsOneWidget);
      expect(find.text('Perfil'), findsOneWidget);

      // Student-specific: "Analíticas" tab must NOT be present
      expect(find.text('Analíticas'), findsNothing);

      // ── 4. Seed a course and navigate to the course list tab ──────
      mockCourse.courses.assignAll(<Course>[
        Course(
          id: 'course-001',
          name: 'Desarrollo Móvil',
          semester: '2026-1',
          studentCount: 25,
          status: CourseStatus.active,
          categoryCount: 2,
          evaluationCount: 1,
          teacherName: 'Prof. García',
          enrollmentCode: 'ABC123',
        ),
      ]);

      // Tap the "Cursos" bottom-nav tab → CourseListPage.
      await tester.tap(find.text('Cursos'));
      await tester.pumpAndSettle();

      expect(find.byType(CourseListPage), findsOneWidget);
      expect(find.text('Mis Cursos'), findsOneWidget);

      // ── 5. A course card is visible ───────────────────────────────
      expect(find.text('Desarrollo Móvil'), findsAtLeastNWidgets(1));
      expect(
        find.text('2026-1 | 25 estudiantes | 2 categorías | 1 evaluaciones'),
        findsOneWidget,
      );
    });

    testWidgets('empty course list shows student-specific empty state',
        (tester) async {
      mockAuth.setUser(mockStudent);

      await tester.pumpWidget(pumpApp(const Central()));
      await tester.pumpAndSettle();

      expect(find.byType(StudentHomePage), findsOneWidget);

      // Jump to the Cursos tab with no courses seeded.
      await tester.tap(find.text('Cursos'));
      await tester.pumpAndSettle();

      expect(
        find.text('No estás inscrito en ningún curso'),
        findsOneWidget,
      );
    });

    testWidgets('student role routes to StudentHomePage, not TeacherHomePage',
        (tester) async {
      mockAuth.setUser(User(
        id: 'student-999',
        name: 'Carlos Ruiz',
        email: 'cruiz@uninorte.edu.co',
        role: UserRole.student,
      ));

      await tester.pumpWidget(pumpApp(const Central()));
      await tester.pumpAndSettle();

      expect(find.byType(StudentHomePage), findsOneWidget);
      // Student-specific label
      expect(find.text('Resultados'), findsOneWidget);
      // Teacher-specific label must not appear
      expect(find.text('Analíticas'), findsNothing);
    });
  });
}
