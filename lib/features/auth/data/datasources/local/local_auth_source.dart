import '../../../domain/models/user.dart';
import '../i_auth_source.dart';

class LocalAuthSource implements IAuthSource {
  User? _currentUser;

  final List<User> _users = [
    User(
      id: '1',
      name: 'Prof. Ospina',
      email: 'vospina@uninorte.edu.co',
      password: '1234',
      role: UserRole.teacher,
    ),
    User(
      id: '2',
      name: 'María García',
      email: 'mgarcia@uninorte.edu.co',
      password: '1234',
      role: UserRole.student,
    ),
  ];

  LocalAuthSource();

  @override
  Future<User?> login(String email, String password) {
    final user = _users.cast<User?>().firstWhere(
          (u) => u!.email == email && u.password == password,
          orElse: () => null,
        );
    _currentUser = user;
    return Future.value(user);
  }

  @override
  Future<void> logout() {
    _currentUser = null;
    return Future.value();
  }

  @override
  Future<User?> getCurrentUser() {
    return Future.value(_currentUser);
  }
}
