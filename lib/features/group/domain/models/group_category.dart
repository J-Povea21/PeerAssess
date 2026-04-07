import 'group.dart';

class GroupCategory {
  final String id;
  final String name;
  final String courseId;
  final List<Group> groups;

  GroupCategory({
    required this.id,
    required this.name,
    required this.courseId,
    required this.groups,
  });

  int get groupCount => groups.length;

  int get memberCount =>
      groups.fold<int>(0, (sum, g) => sum + g.members.length);
}
