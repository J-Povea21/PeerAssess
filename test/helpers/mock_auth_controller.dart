import 'package:f_clean_template/core/models/user.dart';
import 'package:f_clean_template/features/auth/ui/viewmodels/auth_controller.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';

/// Mock [AuthController] for Level 1 widget tests.
///
/// Extends [GetxService] + [Mock] so GetX lifecycle works in tests.
/// Override observable fields directly — call [setUser] to switch personas.
class MockAuthController extends GetxService
    with Mock
    implements AuthController {
  final Rx<User?> _currentUser = Rx<User?>(null);

  @override
  final RxBool isLoading = false.obs;

  @override
  final RxBool isRestoringSession = false.obs;

  @override
  final RxBool isTeacherSelected = true.obs;

  @override
  User? get currentUser => _currentUser.value;

  @override
  bool get isLogged => _currentUser.value != null;

  @override
  UserRole? get currentRole => _currentUser.value?.role;

  /// Set the mock user. Use [mockTeacher] or [mockStudent] from test_helpers.
  void setUser(User? user) {
    _currentUser.value = user;
  }

  @override
  Future<bool> login(String email, String password) async {
    return true;
  }

  @override
  Future<void> logout() async {
    _currentUser.value = null;
  }

  @override
  void onInit() {
    // No-op: skip real session restoration in tests.
  }
}
