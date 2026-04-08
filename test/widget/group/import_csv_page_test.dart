import 'package:f_clean_template/features/group/ui/viewmodels/group_controller.dart';
import 'package:f_clean_template/features/group/ui/views/import_csv_page.dart';
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

  group('ImportCsvPage', () {
    testWidgets('shows app bar with Importar CSV title', (tester) async {
      await tester
          .pumpWidget(pumpApp(const ImportCsvPage(courseId: 'c-1')));
      await tester.pump();

      expect(find.text('Importar CSV'), findsOneWidget);
    });

    testWidgets('shows file picker area', (tester) async {
      await tester
          .pumpWidget(pumpApp(const ImportCsvPage(courseId: 'c-1')));
      await tester.pump();

      expect(find.text('Seleccionar archivo CSV'), findsOneWidget);
      expect(find.text('Formato: Brightspace Group Export (.csv)'),
          findsOneWidget);
    });

    testWidgets('shows upload icon before file selection', (tester) async {
      await tester
          .pumpWidget(pumpApp(const ImportCsvPage(courseId: 'c-1')));
      await tester.pump();

      expect(find.byIcon(Icons.upload_file), findsOneWidget);
    });

    testWidgets('import button hidden before file selection',
        (tester) async {
      await tester
          .pumpWidget(pumpApp(const ImportCsvPage(courseId: 'c-1')));
      await tester.pump();

      // No import button visible since no CSV loaded
      expect(find.widgetWithText(ElevatedButton, 'Importar categoría'),
          findsNothing);
    });
  });
}
