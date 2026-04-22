import 'package:f_clean_template/features/group/domain/models/group.dart';
import 'package:f_clean_template/features/group/domain/models/group_member.dart';
import 'package:f_clean_template/features/group/ui/views/group_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../helpers/test_helpers.dart';

void main() {
  tearDown(() => Get.reset());

  final group = Group(
    id: 'grp-001',
    name: 'Group 1',
    categoryId: 'cat-001',
    members: [
      GroupMember(
          id: 'gm-001',
          firstName: 'María',
          lastName: 'López',
          email: 'mlopez@uninorte.edu.co'),
      GroupMember(
          id: 'gm-002',
          firstName: 'Carlos',
          lastName: 'Ruiz',
          email: 'cruiz@uninorte.edu.co'),
    ],
  );

  group_('GroupDetailPage', () {
    testWidgets('shows group name in app bar', (tester) async {
      await tester.pumpWidget(pumpApp(GroupDetailPage(group: group)));
      await tester.pump();

      // Group name in app bar + header card
      expect(find.text('Group 1'), findsNWidgets(2));
    });

    testWidgets('shows header card with member count', (tester) async {
      await tester.pumpWidget(pumpApp(GroupDetailPage(group: group)));
      await tester.pump();

      expect(find.text('2 miembros'), findsOneWidget);
    });

    testWidgets('shows member list with full names and emails',
        (tester) async {
      await tester.pumpWidget(pumpApp(GroupDetailPage(group: group)));
      await tester.pump();

      expect(find.text('María López'), findsOneWidget);
      expect(find.text('mlopez@uninorte.edu.co'), findsOneWidget);
      expect(find.text('Carlos Ruiz'), findsOneWidget);
      expect(find.text('cruiz@uninorte.edu.co'), findsOneWidget);
    });

    testWidgets('shows member initials in avatars', (tester) async {
      await tester.pumpWidget(pumpApp(GroupDetailPage(group: group)));
      await tester.pump();

      expect(find.text('ML'), findsOneWidget);
      expect(find.text('CR'), findsOneWidget);
    });
  });
}

// Dart doesn't allow a local variable named `group` inside group(), so
// we use a wrapper that delegates to flutter_test's group().
void group_(String description, void Function() body) => group(description, body);
