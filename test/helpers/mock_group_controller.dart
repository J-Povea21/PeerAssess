import 'package:f_clean_template/features/group/domain/models/group.dart';
import 'package:f_clean_template/features/group/domain/models/group_category.dart';
import 'package:f_clean_template/features/group/ui/viewmodels/group_controller.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';

/// Mock [GroupController] for Level 1 widget tests.
class MockGroupController extends GetxService
    with Mock
    implements GroupController {
  @override
  final RxList<GroupCategory> categories = <GroupCategory>[].obs;

  @override
  final RxList<Group> selectedGroups = <Group>[].obs;

  @override
  final RxBool isLoading = false.obs;

  @override
  final RxBool isImporting = false.obs;

  @override
  Future<void> loadCategories(String courseId) async {}

  @override
  Future<GroupCategory?> importCsv(String courseId, String csvContent) async {
    return null;
  }

  @override
  Future<void> loadGroups(String categoryId) async {}

  @override
  void onInit() {}
}
