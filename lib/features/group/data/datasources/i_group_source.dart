import '../../domain/models/group.dart';
import '../../domain/models/group_category.dart';

abstract class IGroupSource {
  Future<List<GroupCategory>> getCategoriesByCourse(String courseId);

  Future<GroupCategory> importCategoryFromCsv(
      String courseId, String csvContent);

  Future<List<Group>> getGroupsByCategory(String categoryId);
}
