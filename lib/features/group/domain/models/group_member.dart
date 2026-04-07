class GroupMember {
  final String id;
  final String firstName;
  final String lastName;
  final String email;

  GroupMember({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  String get fullName => '$firstName $lastName';

  String get initials {
    final first = firstName.isNotEmpty ? firstName[0] : '';
    final last = lastName.isNotEmpty ? lastName[0] : '';
    return '$first$last'.toUpperCase();
  }
}
