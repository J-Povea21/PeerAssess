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

  factory GroupCategory.fromJson(Map<String, dynamic> json) => GroupCategory(
        id: json['id'] as String,
        name: json['name'] as String,
        courseId: json['courseId'] as String,
        groups: (json['groups'] as List<dynamic>)
            .map((g) => Group.fromJson(g as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'courseId': courseId,
        'groups': groups.map((g) => g.toJson()).toList(),
      };

  int get groupCount => groups.length;

  int get memberCount =>
      groups.fold<int>(0, (sum, g) => sum + g.members.length);

  @override
  String toString() => 'GroupCategory{id: $id, name: $name, groups: ${groups.length}}';
}
