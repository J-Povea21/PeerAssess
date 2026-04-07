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
}
