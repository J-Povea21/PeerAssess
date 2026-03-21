import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loggy/loggy.dart';

import 'central.dart';
import 'core/app_theme.dart';

import 'features/auth/data/datasources/i_auth_source.dart';
import 'features/auth/data/datasources/local/local_auth_source.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/domain/repositories/i_auth_repository.dart';
import 'features/auth/ui/viewmodels/auth_controller.dart';

import 'features/course/data/datasources/i_course_source.dart';
import 'features/course/data/datasources/local/local_course_source.dart';
import 'features/course/data/repositories/course_repository.dart';
import 'features/course/domain/repositories/i_course_repository.dart';
import 'features/course/ui/viewmodels/course_controller.dart';

void main() {
  Loggy.initLoggy(logPrinter: const PrettyPrinter(showColors: true));

  // Auth
  Get.put<IAuthSource>(LocalAuthSource());
  Get.put<IAuthRepository>(AuthRepository(Get.find()));
  Get.put(AuthController(Get.find()));

  // Course
  Get.put<ICourseSource>(LocalCourseSource());
  Get.put<ICourseRepository>(CourseRepository(Get.find()));
  Get.lazyPut(() => CourseController(Get.find()));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'PeerAssess',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      home: const Central(),
    );
  }
}
