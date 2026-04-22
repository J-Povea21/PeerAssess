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

  factory GroupMember.fromJson(Map<String, dynamic> json) => GroupMember(
        id: json['id'] as String,
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
        email: json['email'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
      };

  String get fullName => '$firstName $lastName';

  String get initials {
    final first = firstName.isNotEmpty ? firstName[0] : '';
    final last = lastName.isNotEmpty ? lastName[0] : '';
    return '$first$last'.toUpperCase();
  }

  @override
  String toString() => 'GroupMember{id: $id, fullName: $fullName}';
}
