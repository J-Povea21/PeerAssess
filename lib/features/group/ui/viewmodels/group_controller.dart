import 'package:get/get.dart';
import 'package:loggy/loggy.dart';

import '../../../course/ui/viewmodels/course_controller.dart';
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

    try {
      // 🔥 SOLO cargar datos sin modificar estructura
      categories.value =
          await repository.getCategoriesByCourse(courseId);

    } catch (e) {
      logWarning('GroupController: Failed to load categories — $e');
      categories.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<GroupCategory?> importCsv(String courseId, String csvContent) async {
    logInfo('GroupController: Importing CSV for course $courseId');
    isImporting.value = true;

    try {
      final category =
          await repository.importCategoryFromCsv(courseId, csvContent);

      // recargar datos
      await loadCategories(courseId);

      // refrescar cursos
      Get.find<CourseController>().refreshCourses();

      return category;
    } catch (e) {
      logWarning('GroupController: CSV import failed — $e');
      return null;
    } finally {
      isImporting.value = false;
    }
  }

  Future<void> loadGroups(String categoryId) async {
    logInfo('GroupController: Loading groups for category $categoryId');

    isLoading.value = true;

    try {
      // 🔥 SIN copyWith
      selectedGroups.value =
          await repository.getGroupsByCategory(categoryId);

    } catch (e) {
      logWarning('GroupController: Failed to load groups — $e');
      selectedGroups.clear();
    } finally {
      isLoading.value = false;
    }
  }
}