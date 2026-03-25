import 'package:get/get.dart';
import 'package:loggy/loggy.dart';

import '../../domain/models/group.dart';
import '../../domain/models/group_category.dart';
import '../../domain/repositories/i_group_repository.dart';

class GroupController extends GetxController {
  final IGroupRepository repository;

  final RxList<GroupCategory> categories = <GroupCategory>[].obs;
  final RxList<Group> selectedGroups = <Group>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isImporting = false.obs;

  GroupController(this.repository);

  Future<void> loadCategories(String courseId) async {
    logInfo('GroupController: Loading categories for course $courseId');
    isLoading.value = true;
    categories.value = await repository.getCategoriesByCourse(courseId);
    isLoading.value = false;
  }

  Future<GroupCategory?> importCsv(String courseId, String csvContent) async {
    logInfo('GroupController: Importing CSV for course $courseId');
    isImporting.value = true;
    try {
      final category =
          await repository.importCategoryFromCsv(courseId, csvContent);
      // Refresh the categories list
      await loadCategories(courseId);
      isImporting.value = false;
      return category;
    } catch (e) {
      logWarning('GroupController: CSV import failed — $e');
      isImporting.value = false;
      return null;
    }
  }

  Future<void> loadGroups(String categoryId) async {
    logInfo('GroupController: Loading groups for category $categoryId');
    isLoading.value = true;
    selectedGroups.value = await repository.getGroupsByCategory(categoryId);
    isLoading.value = false;
  }
}
