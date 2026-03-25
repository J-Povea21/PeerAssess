import '../models/group.dart';
import '../models/group_category.dart';

abstract class IGroupRepository {
  Future<List<GroupCategory>> getCategoriesByCourse(String courseId);

  Future<GroupCategory> importCategoryFromCsv(
      String courseId, String csvContent);

  Future<List<Group>> getGroupsByCategory(String categoryId);
}
