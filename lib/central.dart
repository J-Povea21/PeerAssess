import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/models/user.dart';
import 'features/auth/ui/viewmodels/auth_controller.dart';
import 'features/auth/ui/views/login_page.dart';
import 'features/auth/ui/views/splash_page.dart';
import 'features/home/ui/views/student_home_page.dart';
import 'features/home/ui/views/teacher_home_page.dart';

class Central extends StatelessWidget {
  const Central({super.key});

  @override
  Widget build(BuildContext context) {
    AuthController authController = Get.find();
    return Obx(() {
      if (authController.isLoading.value) {
        return const SplashPage();
      }
      if (!authController.isLogged) {
        return const LoginPage();
      }
      if (authController.currentRole == UserRole.teacher) {
        return const TeacherHomePage();
      }
      return const StudentHomePage();
    });
  }
}
