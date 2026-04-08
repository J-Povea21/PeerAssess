import 'package:f_clean_template/features/course/ui/views/members_page.dart';
import 'package:f_clean_template/features/group/ui/viewmodels/group_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../helpers/test_helpers.dart';

void main() {
  late MockGroupController mockGroup;

  setUp(() {
    mockGroup = MockGroupController();
    Get.put<GroupController>(mockGroup);
  });

  tearDown(() => Get.reset());

  group('MembersPage', () {
    testWidgets('shows empty state when no members', (tester) async {
      await tester.pumpWidget(pumpApp(const MembersPage(courseId: 'c-1')));
      await tester.pumpAndSettle();

      expect(find.text('No hay miembros aún'), findsOneWidget);
      expect(find.text('Los miembros aparecerán al importar un CSV'),
          findsOneWidget);
    });

    testWidgets('shows loading spinner', (tester) async {
      mockGroup.isLoading.value = true;

      await tester.pumpWidget(pumpApp(const MembersPage(courseId: 'c-1')));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows member list with names and emails', (tester) async {
      mockGroup.categories.assignAll([mockCategory()]);

      await tester.pumpWidget(pumpApp(const MembersPage(courseId: 'c-1')));
      await tester.pumpAndSettle();

      expect(find.text('María López'), findsOneWidget);
      expect(find.text('mlopez@uninorte.edu.co'), findsOneWidget);
      expect(find.text('Carlos Ruiz'), findsOneWidget);
      expect(find.text('cruiz@uninorte.edu.co'), findsOneWidget);
      expect(find.text('Ana Torres'), findsOneWidget);
      expect(find.text('atorres@uninorte.edu.co'), findsOneWidget);
    });

    testWidgets('shows total member count', (tester) async {
      mockGroup.categories.assignAll([mockCategory()]);

      await tester.pumpWidget(pumpApp(const MembersPage(courseId: 'c-1')));
      await tester.pumpAndSettle();

      expect(find.text('3 miembros en total'), findsOneWidget);
    });
  });
}
