import 'package:get/get.dart';
import 'package:loggy/loggy.dart';

import '../../domain/models/user.dart';
import '../../domain/repositories/i_auth_repository.dart';

class AuthController extends GetxController {
  late IAuthRepository repository;
  final Rx<User?> _currentUser = Rx<User?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isTeacherSelected = true.obs;

  AuthController(this.repository);

  User? get currentUser => _currentUser.value;
  bool get isLogged => _currentUser.value != null;
  UserRole? get currentRole => _currentUser.value?.role;

  Future<bool> login(String email, String password) async {
    logInfo("AuthController: Attempting login for $email");
    isLoading.value = true;

    final user = await repository.login(email, password);
    if (user != null) {
      _currentUser.value = user;
      logInfo("AuthController: Login successful - ${user.name} (${user.role})");
      isLoading.value = false;
      return true;
    }

    logWarning("AuthController: Login failed for $email");
    isLoading.value = false;
    return false;
  }

  Future<void> logout() async {
    logInfo("AuthController: Logging out");
    await repository.logout();
    _currentUser.value = null;
  }
}
