import '../../../../core/models/user.dart';

abstract class IAuthSource {
  Future<User?> login(String email, String password);

  Future<void> logout();

  Future<User?> getCurrentUser();
}
