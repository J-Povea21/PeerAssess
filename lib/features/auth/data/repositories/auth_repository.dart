import '../../domain/models/user.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../datasources/i_auth_source.dart';

class AuthRepository implements IAuthRepository {
  late IAuthSource authSource;

  AuthRepository(this.authSource);

  @override
  Future<User?> login(String email, String password) async =>
      await authSource.login(email, password);

  @override
  Future<void> logout() async => await authSource.logout();

  @override
  Future<User?> getCurrentUser() async => await authSource.getCurrentUser();
}
