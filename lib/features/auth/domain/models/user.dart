enum UserRole { teacher, student }

class User {
  User({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
  });

  String? id;
  String name;
  String email;
  String password;
  UserRole role;

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json["_id"],
        name: json["name"] ?? "---",
        email: json["email"] ?? "---",
        password: json["password"] ?? "",
        role: json["role"] == "teacher" ? UserRole.teacher : UserRole.student,
      );

  Map<String, dynamic> toJson() => {
        "_id": id ?? "0",
        "name": name,
        "email": email,
        "password": password,
        "role": role == UserRole.teacher ? "teacher" : "student",
      };

  Map<String, dynamic> toJsonNoId() => {
        "name": name,
        "email": email,
        "password": password,
        "role": role == UserRole.teacher ? "teacher" : "student",
      };

  @override
  String toString() {
    return '[User]{id: $id, name: $name, email: $email, role: $role}';
  }
}
