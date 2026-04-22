import 'package:f_clean_template/features/auth/ui/views/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../helpers/test_helpers.dart';

void main() {
  setUp(() {});

  tearDown(() => Get.reset());

  group('SplashPage', () {
    testWidgets('shows app name', (tester) async {
      await tester.pumpWidget(pumpApp(const SplashPage()));
      await tester.pump();

      expect(find.text('PeerAssess'), findsOneWidget);
    });

    testWidgets('shows loading indicator', (tester) async {
      await tester.pumpWidget(pumpApp(const SplashPage()));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
