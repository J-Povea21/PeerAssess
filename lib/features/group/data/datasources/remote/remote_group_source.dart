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
///   Users:             _id, name, mail, role
///   Courses:           _id, nrc, name, semester, teacherID, accessCode
///   CourseEnrollments:  _id, courseID, studentID, joinedAt
///   GroupCategories:   _id, courseID, name, importedAt
///   Groups:            _id, categoryID, name
///   GroupMembers:      _id, groupID, studentID
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

  /// Cache of all users, loaded once per session.
  Map<String, Map<String, dynamic>>? _usersCache;

  /// Loads all users from the Users table into a cache keyed by _id.
  Future<Map<String, Map<String, dynamic>>> _getAllUsers() async {
    if (_usersCache != null) return _usersCache!;
    final allUsers = await _db.read('Users');
    _usersCache = {
      for (final u in allUsers)
        if (u['_id'] != null) u['_id'].toString(): u
    };
    loggy.info('RemoteGroupSource: Cached ${_usersCache!.length} users');
    return _usersCache!;
  }

  /// Reads GroupMembers for a group, then looks up each student in Users cache.
  Future<List<GroupMember>> _getMembersByGroup(String groupId) async {
    final records =
        await _db.read('GroupMembers', {'groupID': groupId});
    final usersMap = await _getAllUsers();
    final members = <GroupMember>[];

    for (final r in records) {
      final studentId = r['studentID']?.toString() ?? '';
      final user = usersMap[studentId];
      if (user != null) {
        final name = user['name']?.toString() ?? '';
        final parts = name.split(' ');
        members.add(GroupMember(
          id: studentId,
          firstName: parts.isNotEmpty ? parts.first : '',
          lastName: parts.length > 1 ? parts.sublist(1).join(' ') : '',
          email: user['mail']?.toString() ?? '',
        ));
      } else {
        members.add(GroupMember(
          id: studentId,
          firstName: 'Estudiante',
          lastName: studentId,
          email: '',
        ));
      }
    }

    return members;
  }

  @override
  Future<GroupCategory> importCategoryFromCsv(
      String courseId, String csvContent) async {
    // Parse CSV locally
    final parsed = _parseBrightspaceCsv(csvContent);
    final categoryName = parsed.categoryName;
    final groupMap = parsed.groups;

    // Invalidate users cache since we may create new users
    _usersCache = null;

    // 1. Ensure all students exist in Users table and collect their IDs
    //    Also enroll them in the course
    final emailToUserId = <String, String>{};
    final allStudents = <GroupMember>{};
    for (final members in groupMap.values) {
      allStudents.addAll(members);
    }

    for (final student in allStudents) {
      final userId = await _ensureUserExists(student);
      emailToUserId[student.email] = userId;
      await _ensureEnrollment(courseId, userId);
    }

    // 2. Insert category
    final categoryId = _generateId();
    await _db.insert('GroupCategories', [
      {
        '_id': categoryId,
        'courseID': courseId,
        'name': categoryName,
        'importedAt': DateTime.now().toIso8601String(),
      }
    ]);

    // 3. Insert groups and members
    final groups = <Group>[];
    for (final entry in groupMap.entries) {
      final groupId = _generateId();
      await _db.insert('Groups', [
        {'_id': groupId, 'categoryID': categoryId, 'name': entry.key}
      ]);

      // Insert GroupMembers referencing the Users._id
      final memberRecords = entry.value
          .map((m) => {
                '_id': _generateId(),
                'groupID': groupId,
                'studentID': emailToUserId[m.email] ?? m.id,
              })
          .toList();

      if (memberRecords.isNotEmpty) {
        await _db.insert('GroupMembers', memberRecords);
      }

      // Update member IDs to the actual user IDs for the return value
      final resolvedMembers = entry.value
          .map((m) => GroupMember(
                id: emailToUserId[m.email] ?? m.id,
                firstName: m.firstName,
                lastName: m.lastName,
                email: m.email,
              ))
          .toList();

      groups.add(Group(
        id: groupId,
        name: entry.key,
        categoryId: categoryId,
        members: resolvedMembers,
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

  /// Checks if a user with this email exists in Users.
  /// If not, creates a new student user. Returns the user's _id.
  Future<String> _ensureUserExists(GroupMember student) async {
    // Look up by email (Roble Users table uses 'mail')
    final existing = await _db.read('Users', {'mail': student.email});
    if (existing.isNotEmpty) {
      return existing.first['_id']?.toString() ?? '';
    }

    // Create new student user
    final userId = _generateId();
    await _db.insert('Users', [
      {
        '_id': userId,
        'name': '${student.firstName} ${student.lastName}'.trim(),
        'mail': student.email,
        'role': 'STUDENT',
      }
    ]);
    loggy.info('RemoteGroupSource: Created user $userId for ${student.email}');
    return userId;
  }

  /// Ensures the student is enrolled in the course.
  Future<void> _ensureEnrollment(String courseId, String userId) async {
    final existing = await _db.read('CourseEnrollments', {
      'courseID': courseId,
      'studentID': userId,
    });
    if (existing.isNotEmpty) return;

    await _db.insert('CourseEnrollments', [
      {
        '_id': _generateId(),
        'courseID': courseId,
        'studentID': userId,
        'joinedAt': DateTime.now().toIso8601String(),
      }
    ]);
    loggy.info('RemoteGroupSource: Enrolled $userId in course $courseId');
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
