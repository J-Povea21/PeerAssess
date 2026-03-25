enum UserRole { teacher, student }

class User {
  User({
    this.id,
    required this.name,
    required this.email,
    this.password,
    required this.role,
    this.avatarUrl,
  });

  String? id;
  String name;
  String email;
  String? password;
  UserRole role;
  String? avatarUrl;

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json["id"] ?? json["_id"],
        name: json["name"] ?? "---",
        email: json["email"] ?? "---",
        password: json["password"],
        avatarUrl: json["avatarUrl"],
        role: _parseRole(json["role"]),
      );

  static UserRole _parseRole(dynamic role) {
    switch (role?.toString().toUpperCase()) {
      case 'TEACHER':
        return UserRole.teacher;
      default:
        return UserRole.student;
    }
  }

  Map<String, dynamic> toJson() => {
        "id": id ?? "0",
        "name": name,
        "email": email,
        if (password != null) "password": password,
        "avatarUrl": avatarUrl,
        "role": role == UserRole.teacher ? "TEACHER" : "STUDENT",
      };

  Map<String, dynamic> toJsonNoId() => {
        "name": name,
        "email": email,
        if (password != null) "password": password,
        "role": role == UserRole.teacher ? "TEACHER" : "STUDENT",
      };

  @override
  String toString() {
    return '[User]{id: $id, name: $name, email: $email, role: $role}';
  }
}
