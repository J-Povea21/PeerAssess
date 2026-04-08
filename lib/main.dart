import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:loggy/loggy.dart';

import 'central.dart';
import 'core/app_theme.dart';
import 'core/config/app_config.dart';
import 'core/network/authenticated_client.dart';
import 'core/network/roble_db_client.dart';
import 'core/services/session_service.dart';

import 'features/auth/data/datasources/i_auth_source.dart';
import 'features/auth/data/datasources/remote/remote_auth_source.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/domain/repositories/i_auth_repository.dart';
import 'features/auth/ui/viewmodels/auth_controller.dart';
import 'features/auth/ui/views/login_page.dart';

import 'features/course/data/datasources/i_course_source.dart';
import 'features/course/data/datasources/remote/remote_course_source.dart';
import 'features/course/data/repositories/course_repository.dart';
import 'features/course/domain/repositories/i_course_repository.dart';
import 'features/course/ui/viewmodels/course_controller.dart';

import 'features/group/data/datasources/i_group_source.dart';
import 'features/group/data/datasources/remote/remote_group_source.dart';
import 'features/group/data/repositories/group_repository.dart';
import 'features/group/domain/repositories/i_group_repository.dart';
import 'features/group/ui/viewmodels/group_controller.dart';

import 'features/assessment/data/datasources/i_assessment_source.dart';
import 'features/assessment/data/datasources/i_evaluation_source.dart';
import 'features/assessment/data/datasources/remote/remote_assessment_source.dart';
import 'features/assessment/data/datasources/remote/remote_evaluation_source.dart';
import 'features/assessment/data/repositories/assessment_repository.dart';
import 'features/assessment/data/repositories/evaluation_repository.dart';
import 'features/assessment/domain/repositories/i_assessment_repository.dart';
import 'features/assessment/domain/repositories/i_evaluation_repository.dart';
import 'features/assessment/ui/viewmodels/assessment_controller.dart';
import 'features/assessment/ui/viewmodels/evaluation_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Loggy.initLoggy(logPrinter: const PrettyPrinter(showColors: true));

  assert(
    AppConfig.robleToken.isNotEmpty,
    'ROBLE_TOKEN is not set. Run with: flutter run --dart-define=ROBLE_TOKEN=<value>',
  );

  // Core
  final sessionService = SessionService();
  await sessionService.load();
  Get.put(sessionService);
  Get.put<http.Client>(AuthenticatedClient(
    http.Client(),
    sessionService,
    onSessionExpired: () async => Get.offAll(() => const LoginPage()),
  ));

  // Roble Database Client (uses AuthenticatedClient for auto Bearer token)
  final robleDb = RobleDbClient(Get.find<http.Client>());
  Get.put(robleDb);

  // Auth
  Get.put<IAuthSource>(RemoteAuthSource(Get.find(), Get.find()));
  Get.put<IAuthRepository>(AuthRepository(Get.find()));
  Get.put(AuthController(Get.find()));

  // Course (remote — persisted in Roble)
  Get.put<ICourseSource>(RemoteCourseSource(robleDb, sessionService));
  Get.put<ICourseRepository>(CourseRepository(Get.find<ICourseSource>()));
  Get.put(CourseController(Get.find()));

  // Group (remote — persisted in Roble)
  Get.put<IGroupSource>(RemoteGroupSource(robleDb));
  Get.put<IGroupRepository>(GroupRepository(Get.find()));
  Get.put(GroupController(Get.find()));

  // Assessment
  Get.put<IAssessmentSource>(RemoteAssessmentSource(robleDb));
  Get.put<IAssessmentRepository>(AssessmentRepository(Get.find()));

  // Evaluation
  Get.put<IEvaluationSource>(
      RemoteEvaluationSource(robleDb, sessionService));
  Get.put<IEvaluationRepository>(EvaluationRepository(Get.find()));

  // Assessment & Evaluation controllers
  Get.put(AssessmentController(Get.find()));
  Get.put(EvaluationController(Get.find()));

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
