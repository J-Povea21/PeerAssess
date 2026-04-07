import '../../domain/models/group.dart';
import '../../domain/models/group_category.dart';
import '../../domain/repositories/i_group_repository.dart';
import '../datasources/i_group_source.dart';

class GroupRepository implements IGroupRepository {
  final IGroupSource source;

  GroupRepository(this.source);

  @override
  Future<List<GroupCategory>> getCategoriesByCourse(String courseId) async =>
      await source.getCategoriesByCourse(courseId);

  @override
  Future<GroupCategory> importCategoryFromCsv(
          String courseId, String csvContent) async =>
      await source.importCategoryFromCsv(courseId, csvContent);

  @override
  Future<List<Group>> getGroupsByCategory(String categoryId) async =>
      await source.getGroupsByCategory(categoryId);
}
