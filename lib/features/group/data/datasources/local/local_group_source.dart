import '../../datasources/i_group_source.dart';
import '../../../domain/models/group.dart';
import '../../../domain/models/group_category.dart';
import '../../../domain/models/group_member.dart';

class LocalGroupSource implements IGroupSource {
  /// courseId → list of categories
  final Map<String, List<GroupCategory>> _store = {};

  /// categoryId → category (flat lookup)
  final Map<String, GroupCategory> _categoryIndex = {};

  int _nextCategoryId = 1;

  LocalGroupSource();

  @override
  Future<List<GroupCategory>> getCategoriesByCourse(String courseId) {
    return Future.value(_store[courseId] ?? []);
  }

  @override
  Future<GroupCategory> importCategoryFromCsv(
      String courseId, String csvContent) {
    final category = _parseBrightspaceCsv(courseId, csvContent);

    _store.putIfAbsent(courseId, () => []);
    _store[courseId]!.add(category);
    _categoryIndex[category.id] = category;

    return Future.value(category);
  }

  @override
  Future<List<Group>> getGroupsByCategory(String categoryId) {
    final category = _categoryIndex[categoryId];
    return Future.value(category?.groups ?? []);
  }

  /// Parses Brightspace CSV export format.
  ///
  /// Expected columns:
  /// 0: Group Category Name
  /// 1: Group Name
  /// 2: Group Code
  /// 3: Username
  /// 4: OrgDefinedId
  /// 5: First Name
  /// 6: Last Name
  /// 7: Email Address
  /// 8: Group Enrollment Date
  GroupCategory _parseBrightspaceCsv(String courseId, String csvContent) {
    final lines = csvContent
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.length < 2) {
      throw FormatException('CSV must have at least a header and one data row');
    }

    // Skip header row
    final dataLines = lines.sublist(1);

    // Parse into a map: groupName → List<GroupMember>
    final Map<String, List<GroupMember>> groupMap = {};
    String? categoryName;

    for (final line in dataLines) {
      final cols = _parseCsvLine(line);
      if (cols.length < 8) continue;

      categoryName ??= cols[0];
      final groupName = cols[1];
      final orgId = cols[4];
      final firstName = _titleCase(cols[5]);
      final lastName = _titleCase(cols[6]);
      final email = cols[7];

      groupMap.putIfAbsent(groupName, () => []);
      groupMap[groupName]!.add(GroupMember(
        id: orgId,
        firstName: firstName,
        lastName: lastName,
        email: email,
      ));
    }

    categoryName ??= 'Categoría importada';

    final categoryId = 'cat_${_nextCategoryId++}';

    // Build Group objects
    int groupIndex = 1;
    final groups = groupMap.entries.map((entry) {
      return Group(
        id: '${categoryId}_g${groupIndex++}',
        name: entry.key,
        categoryId: categoryId,
        members: entry.value,
      );
    }).toList();

    // Sort groups by name
    groups.sort((a, b) => _naturalCompare(a.name, b.name));

    return GroupCategory(
      id: categoryId,
      name: categoryName,
      courseId: courseId,
      groups: groups,
    );
  }

  /// Simple CSV line parser that handles basic comma separation.
  /// Brightspace exports don't typically quote fields.
  List<String> _parseCsvLine(String line) {
    return line.split(',').map((s) => s.trim()).toList();
  }

  /// Converts "JOHN DOE" to "John Doe"
  String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Natural sort so "Group 2" comes before "Group 10"
  int _naturalCompare(String a, String b) {
    final regExp = RegExp(r'(\d+)');
    final aMatch = regExp.firstMatch(a);
    final bMatch = regExp.firstMatch(b);
    if (aMatch != null && bMatch != null) {
      final aNum = int.tryParse(aMatch.group(0)!) ?? 0;
      final bNum = int.tryParse(bMatch.group(0)!) ?? 0;
      return aNum.compareTo(bNum);
    }
    return a.compareTo(b);
  }
}
