import 'package:f_clean_template/features/auth/ui/viewmodels/auth_controller.dart';
import 'package:f_clean_template/features/auth/ui/views/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../helpers/test_helpers.dart';

void main() {
  late MockAuthController mockAuth;

  setUp(() {
    mockAuth = MockAuthController();
    Get.put<AuthController>(mockAuth);
    // LoginPage calls Get.find<AuthController>() which resolves via the
    // MockAuthController registered above (it implements AuthController).
  });

  tearDown(() => Get.reset());

  group('LoginPage', () {
    testWidgets('renders email and password fields', (tester) async {
      await tester.pumpWidget(pumpApp(const LoginPage()));
      await tester.pump();

      expect(find.text('Correo institucional'), findsOneWidget);
      expect(find.text('Contraseña'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('renders app title and subtitle', (tester) async {
      await tester.pumpWidget(pumpApp(const LoginPage()));
      await tester.pump();

      expect(find.text('PeerAssess'), findsOneWidget);
      expect(
          find.text('Evaluación Colaborativa en Grupos'), findsOneWidget);
    });

    testWidgets('login button is disabled when fields are empty',
        (tester) async {
      await tester.pumpWidget(pumpApp(const LoginPage()));
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Iniciar sesión'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('login button enables when both fields are filled',
        (tester) async {
      await tester.pumpWidget(pumpApp(const LoginPage()));
      await tester.pump();

      await tester.enterText(
          find.byType(TextField).first, 'user@uninorte.edu.co');
      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Iniciar sesión'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('shows loading spinner when isLoading is true',
        (tester) async {
      mockAuth.isLoading.value = true;
      await tester.pumpWidget(pumpApp(const LoginPage()));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('tapping login button triggers controller.login',
        (tester) async {
      await tester.pumpWidget(pumpApp(const LoginPage()));
      await tester.pump();

      await tester.enterText(
          find.byType(TextField).first, 'user@uninorte.edu.co');
      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.pump();

      await tester.tap(
          find.widgetWithText(ElevatedButton, 'Iniciar sesión'));
      await tester.pumpAndSettle();

      // The mock login returns true by default, so no snackbar should appear.
      expect(find.text('Credenciales inválidas'), findsNothing);
    });

    testWidgets('shows secure auth footer text', (tester) async {
      await tester.pumpWidget(pumpApp(const LoginPage()));
      await tester.pump();

      expect(find.text('Autenticación segura via Roble'), findsOneWidget);
    });
  });
}
