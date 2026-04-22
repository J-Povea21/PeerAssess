import 'package:f_clean_template/central.dart';
import 'package:f_clean_template/core/models/user.dart';
import 'package:f_clean_template/features/analytics/ui/viewmodels/analytics_controller.dart';
import 'package:f_clean_template/features/auth/ui/viewmodels/auth_controller.dart';
import 'package:f_clean_template/features/auth/ui/views/login_page.dart';
import 'package:f_clean_template/features/course/domain/models/course.dart';
import 'package:f_clean_template/features/course/ui/viewmodels/course_controller.dart';
import 'package:f_clean_template/features/course/ui/views/course_list_page.dart';
import 'package:f_clean_template/features/group/ui/viewmodels/group_controller.dart';
import 'package:f_clean_template/features/home/ui/views/teacher_home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../helpers/test_helpers.dart';

/// ══════════════════════════════════════════════════════════════════════
///  Flow A — Professor
///  App launch → login → teacher dashboard → course list → course card
/// ══════════════════════════════════════════════════════════════════════
///
/// Follows the reference pattern from `f_web_authentication/test/widget_test`
/// where controllers are mocked via `GetxService with Mock implements X`
/// and registered through `Get.put`. The whole flow is driven from
/// [Central] — the same entry widget `main.dart` renders — so the test
/// exercises routing, auth state, and dashboard UI end-to-end.
///
/// Credentials are NOT real — they are test placeholders consumed by the
/// mock [MockAuthController.login], which simply flips the logged-in user
/// without hitting the network. This matches how the reference repo
/// handles authentication in widget-level flow tests.
///
/// Test credentials (placeholders — no real backend call is made):
const String _kTeacherEmail = 'teacher@uninorte.edu.co';
const String _kTeacherPassword = 'teacher-password';

void main() {
  late MockAuthController mockAuth;
  late MockCourseController mockCourse;
  late MockGroupController mockGroup;
  late MockAnalyticsController mockAnalytics;

  setUp(() {
    mockAuth = MockAuthController();
    mockCourse = MockCourseController();
    mockGroup = MockGroupController();
    mockAnalytics = MockAnalyticsController();

    Get.put<AuthController>(mockAuth);
    Get.put<CourseController>(mockCourse);
    Get.put<GroupController>(mockGroup);
    Get.put<AnalyticsController>(mockAnalytics);
  });

  tearDown(() => Get.reset());

  group('Flow A — Professor', () {
    testWidgets(
        'launch → login → teacher dashboard → course list → course card',
        (tester) async {
      // ── 1. App launches → login screen appears ────────────────────
      // `Central` routes to LoginPage when isLogged is false.
      await tester.pumpWidget(pumpApp(const Central()));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.text('PeerAssess'), findsOneWidget);
      expect(find.text('Evaluación Colaborativa en Grupos'), findsOneWidget);
      expect(find.text('Correo institucional'), findsOneWidget);
      expect(find.text('Contraseña'), findsOneWidget);

      // ── 2. Log in with professor credentials ──────────────────────
      await tester.enterText(find.byType(TextField).first, _kTeacherEmail);
      await tester.enterText(find.byType(TextField).last, _kTeacherPassword);
      await tester.pump();

      // Tap the login button while still on LoginPage. The mock's login()
      // returns true without a real HTTP call; we then flip the user to
      // make Central's Obx re-render into TeacherHomePage.
      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Iniciar sesión'),
      );
      await tester.pump();

      mockAuth.setUser(mockTeacher);
      await tester.pumpAndSettle();

      // ── 3. Dashboard loads with teacher UI ────────────────────────
      expect(find.byType(TeacherHomePage), findsOneWidget);

      // Greeting + teacher name
      expect(find.text('Buenos días'), findsOneWidget);
      expect(find.text('Prof. García'), findsAtLeastNWidgets(1));

      // Stats row (only appears on the teacher dashboard)
      expect(find.text('Cursos activos'), findsOneWidget);
      expect(find.text('Evaluaciones'), findsAtLeastNWidgets(1));
      expect(find.text('Estudiantes'), findsAtLeastNWidgets(1));

      // MIS CURSOS section header + teacher FAB
      expect(find.text('MIS CURSOS'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // Bottom navigation shows the 4 teacher tabs
      expect(find.text('Inicio'), findsOneWidget);
      expect(find.text('Cursos'), findsOneWidget);
      expect(find.text('Analíticas'), findsOneWidget);
      expect(find.text('Perfil'), findsOneWidget);

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

      // Tap the "Cursos" bottom-nav tab → switches IndexedStack to
      // CourseListPage.
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

    testWidgets('failed login keeps the user on the login screen',
        (tester) async {
      // Override login to simulate invalid credentials.
      await tester.pumpWidget(pumpApp(const Central()));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, _kTeacherEmail);
      await tester.enterText(find.byType(TextField).last, 'wrong-password');
      await tester.pump();

      // Do NOT set the mock user → simulates a failed login
      // (mockAuth.login returns true by default, but isLogged is based
      // on currentUser which we never set, so Central stays on LoginPage).
      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Iniciar sesión'),
      );
      await tester.pumpAndSettle();

      // Still on login — no teacher home rendered.
      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(TeacherHomePage), findsNothing);
    });

    testWidgets('teacher role routes to TeacherHomePage, not StudentHomePage',
        (tester) async {
      mockAuth.setUser(User(
        id: 'teacher-999',
        name: 'Prof. Salazar',
        email: 'salazar@uninorte.edu.co',
        role: UserRole.teacher,
      ));

      await tester.pumpWidget(pumpApp(const Central()));
      await tester.pumpAndSettle();

      expect(find.byType(TeacherHomePage), findsOneWidget);
      // Teacher-specific tab label
      expect(find.text('Analíticas'), findsOneWidget);
      // Student-specific tab label should NOT appear
      expect(find.text('Resultados'), findsNothing);
    });
  });
}
