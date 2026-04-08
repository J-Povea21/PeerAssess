import 'package:f_clean_template/features/auth/ui/viewmodels/auth_controller.dart';
import 'package:f_clean_template/features/profile/ui/views/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../helpers/test_helpers.dart';

void main() {
  late MockAuthController mockAuth;

  setUp(() {
    mockAuth = MockAuthController();
    Get.put<AuthController>(mockAuth);
  });

  tearDown(() => Get.reset());

  group('ProfilePage — teacher', () {
    setUp(() => mockAuth.setUser(mockTeacher));

    testWidgets('displays teacher name and email', (tester) async {
      await tester.pumpWidget(pumpApp(const ProfilePage()));
      await tester.pump();

      expect(find.text('Prof. García'), findsOneWidget);
      expect(find.text('garcia@uninorte.edu.co'), findsOneWidget);
    });

    testWidgets('shows Profesor role badge', (tester) async {
      await tester.pumpWidget(pumpApp(const ProfilePage()));
      await tester.pump();

      expect(find.text('Profesor'), findsOneWidget);
    });

    testWidgets('displays user initials in avatar', (tester) async {
      await tester.pumpWidget(pumpApp(const ProfilePage()));
      await tester.pump();

      // mockTeacher name is "Prof. García" → initials "PG"
      expect(find.text('PG'), findsOneWidget);
    });

    testWidgets('shows logout button', (tester) async {
      await tester.pumpWidget(pumpApp(const ProfilePage()));
      await tester.pump();

      expect(find.text('Cerrar sesión'), findsOneWidget);
      expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
    });

    testWidgets('tapping logout triggers controller.logout', (tester) async {
      await tester.pumpWidget(pumpApp(const ProfilePage()));
      await tester.pump();

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();

      // After logout the currentUser is null
      expect(mockAuth.currentUser, isNull);
    });
  });

  group('ProfilePage — student', () {
    setUp(() => mockAuth.setUser(mockStudent));

    testWidgets('displays student name and email', (tester) async {
      await tester.pumpWidget(pumpApp(const ProfilePage()));
      await tester.pump();

      expect(find.text('María López'), findsOneWidget);
      expect(find.text('mlopez@uninorte.edu.co'), findsOneWidget);
    });

    testWidgets('shows Estudiante role badge', (tester) async {
      await tester.pumpWidget(pumpApp(const ProfilePage()));
      await tester.pump();

      expect(find.text('Estudiante'), findsOneWidget);
    });
  });
}
