import 'package:loggy/loggy.dart';

import '../../../../../core/cache/cache_keys.dart';
import '../../../../../core/cache/i_cache_service.dart';
import '../../../domain/models/group.dart';
import '../../../domain/models/group_category.dart';
import '../i_group_source.dart';

class CacheGroupSource implements IGroupSource {
  final IGroupSource _remote;
  final ICacheService _cache;

  CacheGroupSource(this._remote, this._cache);

  // — Cached reads —

  @override
  Future<List<GroupCategory>> getCategoriesByCourse(String courseId) async {
    final key = CacheKeys.groupCategories(courseId);
    final cached = await _cache.getList(key, GroupCategory.fromJson);
    if (cached != null) {
      logInfo('CacheGroupSource: hit — $key');
      return cached;
    }
    logInfo('CacheGroupSource: miss — $key, fetching remote');
    final categories = await _remote.getCategoriesByCourse(courseId);
    await _cache.setList(key, categories, (c) => c.toJson());
    return categories;
  }

  @override
  Future<List<Group>> getGroupsByCategory(String categoryId) async {
    final key = CacheKeys.groups(categoryId);
    final cached = await _cache.getList(key, Group.fromJson);
    if (cached != null) {
      logInfo('CacheGroupSource: hit — $key');
      return cached;
    }
    logInfo('CacheGroupSource: miss — $key, fetching remote');
    final groups = await _remote.getGroupsByCategory(categoryId);
    await _cache.setList(key, groups, (g) => g.toJson());
    return groups;
  }

  // — Write (remote + invalidate related keys) —

  @override
  Future<GroupCategory> importCategoryFromCsv(
      String courseId, String csvContent) async {
    final category = await _remote.importCategoryFromCsv(courseId, csvContent);
    await _cache.invalidate(CacheKeys.groupCategories(courseId));
    await _cache.invalidate(CacheKeys.groups(category.id));
    logInfo('CacheGroupSource: invalidated group cache for course $courseId');
    return category;
  }
}
