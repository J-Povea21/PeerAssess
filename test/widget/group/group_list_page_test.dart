import 'package:f_clean_template/features/group/ui/views/group_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../helpers/test_helpers.dart';

void main() {
  tearDown(() => Get.reset());

  group('GroupListPage', () {
    testWidgets('shows category name in app bar', (tester) async {
      final category = mockCategory();

      await tester.pumpWidget(pumpApp(GroupListPage(category: category)));
      await tester.pump();

      expect(find.text('Sprint 1'), findsOneWidget);
    });

    testWidgets('shows summary bar with group and member counts',
        (tester) async {
      final category = mockCategory();

      await tester.pumpWidget(pumpApp(GroupListPage(category: category)));
      await tester.pump();

      expect(find.text('2'), findsOneWidget); // group count
      expect(find.text('Grupos'), findsOneWidget);
      expect(find.text('3'), findsOneWidget); // member count
      expect(find.text('Miembros'), findsOneWidget);
    });

    testWidgets('renders group cards with member counts', (tester) async {
      final category = mockCategory();

      await tester.pumpWidget(pumpApp(GroupListPage(category: category)));
      await tester.pump();

      expect(find.text('Group 1'), findsOneWidget);
      expect(find.text('2 miembros'), findsOneWidget);
      expect(find.text('Group 2'), findsOneWidget);
      expect(find.text('1 miembros'), findsOneWidget);
    });

    testWidgets('shows member initials avatars on group cards',
        (tester) async {
      final category = mockCategory();

      await tester.pumpWidget(pumpApp(GroupListPage(category: category)));
      await tester.pump();

      // Group 1: ML, CR — Group 2: AT
      expect(find.text('ML'), findsOneWidget);
      expect(find.text('CR'), findsOneWidget);
      expect(find.text('AT'), findsOneWidget);
    });
  });
}
