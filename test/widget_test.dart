import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'helpers/test_helpers.dart';

/// Smoke test: verifies the shared test infrastructure works correctly. This is an example
/// of how the mocks can be used!
void main() {
  tearDown(() => Get.reset());

  group('Test infrastructure smoke tests', () {
    test('MockAuthController can be registered and found via GetX', () {
      final controller = MockAuthController();
      Get.put<MockAuthController>(controller);

      expect(Get.find<MockAuthController>(), isNotNull);
    });

    test('MockAuthController defaults to logged-out state', () {
      final controller = MockAuthController();

      expect(controller.isLogged, false);
      expect(controller.currentUser, isNull);
      expect(controller.currentRole, isNull);
    });

    test('MockAuthController can switch to teacher persona', () {
      final controller = MockAuthController();
      controller.setUser(mockTeacher);

      expect(controller.isLogged, true);
      expect(controller.currentUser!.name, 'Prof. García');
      expect(controller.currentUser!.role.name, 'teacher');
    });

    test('MockAuthController can switch to student persona', () {
      final controller = MockAuthController();
      controller.setUser(mockStudent);

      expect(controller.isLogged, true);
      expect(controller.currentUser!.name, 'María López');
      expect(controller.currentUser!.role.name, 'student');
    });

    test('MockCourseController can hold course fixtures', () {
      final controller = MockCourseController();
      controller.courses.assignAll(mockCourses());

      expect(controller.courses.length, 2);
      expect(controller.courses[0].name, 'Desarrollo Móvil');
    });

    test('MockGroupController can hold category fixtures', () {
      final controller = MockGroupController();
      controller.categories.assign(mockCategory());

      expect(controller.categories.length, 1);
      expect(controller.categories[0].groupCount, 2);
      expect(controller.categories[0].memberCount, 3);
    });

    test('isAUri matcher works', () {
      expect(Uri.parse('https://example.com'), isAUri);
      expect('not a uri', isNot(isAUri));
    });

    test('MockHttpClient can be instantiated', () {
      final client = MockHttpClient();
      expect(client, isNotNull);
    });

    testWidgets('pumpApp wraps widget in GetMaterialApp', (tester) async {
      await tester.pumpWidget(pumpApp(
        const Text('Hello PeerAssess'),
      ));

      expect(find.text('Hello PeerAssess'), findsOneWidget);
    });
  });
}
