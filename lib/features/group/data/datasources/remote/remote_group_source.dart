import 'dart:math';

import 'package:loggy/loggy.dart';

import '../../../../../core/network/roble_db_client.dart';
import '../../../domain/models/group.dart';
import '../../../domain/models/group_category.dart';
import '../../../domain/models/group_member.dart';
import '../i_group_source.dart';

/// Remote group source backed by Roble database.
///
/// Roble table schemas:
///   GroupCategories: _id, courseID, name, importedAt
///   Groups:          _id, categoryID, name
///   GroupMembers:    _id, groupID, studentID
class RemoteGroupSource with UiLoggy implements IGroupSource {
  final RobleDbClient _db;

  RemoteGroupSource(this._db);

  String _generateId() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(12, (_) => chars[random.nextInt(chars.length)]).join();
  }

  @override
  Future<List<GroupCategory>> getCategoriesByCourse(String courseId) async {
    final records =
        await _db.read('GroupCategories', {'courseID': courseId});
    final categories = <GroupCategory>[];

    for (final record in records) {
      final catId = record['_id']?.toString() ?? '';
      final groups = await getGroupsByCategory(catId);
      categories.add(GroupCategory(
        id: catId,
        name: record['name']?.toString() ?? '',
        courseId: courseId,
        groups: groups,
      ));
    }

    return categories;
  }

  @override
  Future<List<Group>> getGroupsByCategory(String categoryId) async {
    final records =
        await _db.read('Groups', {'categoryID': categoryId});
    final groups = <Group>[];

    for (final record in records) {
      final groupId = record['_id']?.toString() ?? '';
      final members = await _getMembersByGroup(groupId);
      groups.add(Group(
        id: groupId,
        name: record['name']?.toString() ?? '',
        categoryId: categoryId,
        members: members,
      ));
    }

    groups.sort((a, b) => _naturalCompare(a.name, b.name));
    return groups;
  }

  Future<List<GroupMember>> _getMembersByGroup(String groupId) async {
    final records =
        await _db.read('GroupMembers', {'groupID': groupId});
    return records
        .map((r) => GroupMember(
              id: r['_id']?.toString() ?? r['studentID']?.toString() ?? '',
              firstName: r['firstName']?.toString() ?? '',
              lastName: r['lastName']?.toString() ?? '',
              email: r['email']?.toString() ?? '',
            ))
        .toList();
  }

  @override
  Future<GroupCategory> importCategoryFromCsv(
      String courseId, String csvContent) async {
    // Parse CSV locally
    final parsed = _parseBrightspaceCsv(csvContent);
    final categoryName = parsed.categoryName;
    final groupMap = parsed.groups;

    // 1. Insert category into Roble
    final categoryId = _generateId();
    await _db.insert('GroupCategories', [
      {
        '_id': categoryId,
        'courseID': courseId,
        'name': categoryName,
        'importedAt': DateTime.now().toIso8601String(),
      }
    ]);

    // 2. Insert groups and members
    final groups = <Group>[];
    for (final entry in groupMap.entries) {
      final groupId = _generateId();
      await _db.insert('Groups', [
        {'_id': groupId, 'categoryID': categoryId, 'name': entry.key}
      ]);

      // Insert all members for this group
      final memberRecords = entry.value
          .map((m) => {
                '_id': _generateId(),
                'groupID': groupId,
                'studentID': m.id,
              })
          .toList();

      if (memberRecords.isNotEmpty) {
        await _db.insert('GroupMembers', memberRecords);
      }

      groups.add(Group(
        id: groupId,
        name: entry.key,
        categoryId: categoryId,
        members: entry.value,
      ));
    }

    groups.sort((a, b) => _naturalCompare(a.name, b.name));

    return GroupCategory(
      id: categoryId,
      name: categoryName,
      courseId: courseId,
      groups: groups,
    );
  }

  // ── CSV Parsing ──

  _ParsedCsv _parseBrightspaceCsv(String csvContent) {
    final lines = csvContent
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.length < 2) {
      throw FormatException(
          'CSV must have at least a header and one data row');
    }

    final dataLines = lines.sublist(1);
    final Map<String, List<GroupMember>> groupMap = {};
    String? categoryName;

    for (final line in dataLines) {
      final cols = line.split(',').map((s) => s.trim()).toList();
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

    return _ParsedCsv(
      categoryName: categoryName ?? 'Categoría importada',
      groups: groupMap,
    );
  }

  String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

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

class _ParsedCsv {
  final String categoryName;
  final Map<String, List<GroupMember>> groups;

  _ParsedCsv({required this.categoryName, required this.groups});
}
