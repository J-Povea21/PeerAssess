import '../../../../core/models/user.dart';

abstract class IAuthRepository {
  Future<User?> login(String email, String password);

  Future<void> logout();

  Future<User?> getCurrentUser();
}
