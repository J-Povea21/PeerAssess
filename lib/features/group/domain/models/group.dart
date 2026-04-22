import 'group_member.dart';

class Group {
  final String id;
  final String name;
  final String categoryId;
  final List<GroupMember> members;

  Group({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.members,
  });

  factory Group.fromJson(Map<String, dynamic> json) => Group(
        id: json['id'] as String,
        name: json['name'] as String,
        categoryId: json['categoryId'] as String,
        members: (json['members'] as List<dynamic>)
            .map((m) => GroupMember.fromJson(m as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'categoryId': categoryId,
        'members': members.map((m) => m.toJson()).toList(),
      };

  @override
  String toString() => 'Group{id: $id, name: $name, members: ${members.length}}';
}
