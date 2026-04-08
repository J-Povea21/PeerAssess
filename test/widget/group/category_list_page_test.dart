import 'package:f_clean_template/features/group/ui/viewmodels/group_controller.dart';
import 'package:f_clean_template/features/group/ui/views/category_list_page.dart';
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

  group('CategoryListPage', () {
    testWidgets('shows empty state when no categories', (tester) async {
      await tester
          .pumpWidget(pumpApp(const CategoryListPage(courseId: 'c-1')));
      await tester.pumpAndSettle();

      expect(find.text('No hay categorías aún'), findsOneWidget);
      expect(find.text('Importa un archivo CSV para crear categorías'),
          findsOneWidget);
    });

    testWidgets('shows import CSV button in empty state', (tester) async {
      await tester
          .pumpWidget(pumpApp(const CategoryListPage(courseId: 'c-1')));
      await tester.pumpAndSettle();

      expect(
          find.widgetWithText(ElevatedButton, 'Importar CSV'), findsOneWidget);
    });

    testWidgets('shows loading spinner', (tester) async {
      mockGroup.isLoading.value = true;

      await tester
          .pumpWidget(pumpApp(const CategoryListPage(courseId: 'c-1')));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders category cards with group and member counts',
        (tester) async {
      mockGroup.categories.assignAll([mockCategory()]);

      await tester
          .pumpWidget(pumpApp(const CategoryListPage(courseId: 'c-1')));
      await tester.pumpAndSettle();

      expect(find.text('Sprint 1'), findsOneWidget);
      // 2 groups, 3 members total
      expect(find.text('2 grupos | 3 miembros'), findsOneWidget);
    });

    testWidgets('shows FAB when categories exist', (tester) async {
      mockGroup.categories.assignAll([mockCategory()]);

      await tester
          .pumpWidget(pumpApp(const CategoryListPage(courseId: 'c-1')));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Importar CSV'), findsOneWidget);
    });
  });
}
