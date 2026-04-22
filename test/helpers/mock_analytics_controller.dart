import 'package:f_clean_template/features/analytics/domain/models/activity_overview.dart';
import 'package:f_clean_template/features/analytics/domain/models/group_detail.dart';
import 'package:f_clean_template/features/analytics/domain/models/member_result.dart';
import 'package:f_clean_template/features/analytics/domain/models/student_evolution.dart';
import 'package:f_clean_template/features/analytics/ui/viewmodels/analytics_controller.dart';
import 'package:f_clean_template/features/assessment/domain/models/assessment.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';

class MockAnalyticsController extends GetxService
    with Mock
    implements AnalyticsController {
  @override
  final RxList<Assessment> teacherAssessments = <Assessment>[].obs;

  @override
  final Rx<String?> selectedAssessmentId = Rx<String?>(null);

  @override
  final Rx<ActivityOverview?> activityOverview = Rx<ActivityOverview?>(null);

  @override
  final Rx<GroupDetail?> groupDetail = Rx<GroupDetail?>(null);

  @override
  final Rx<StudentEvolution?> studentEvolution = Rx<StudentEvolution?>(null);

  @override
  final RxBool isLoadingAssessments = false.obs;

  @override
  final RxBool isLoadingOverview = false.obs;

  @override
  final RxBool isLoadingGroup = false.obs;

  @override
  final RxBool isLoadingEvolution = false.obs;

  @override
  final RxList<Assessment> myAssessments = <Assessment>[].obs;

  @override
  final Rx<String?> selectedMyAssessmentId = Rx<String?>(null);

  @override
  final Rx<MemberResult?> myResult = Rx<MemberResult?>(null);

  @override
  final RxBool isLoadingMyAssessments = false.obs;

  @override
  final RxBool isLoadingMyResult = false.obs;

  @override
  Future<void> loadTeacherAssessments(String teacherId) async {}

  @override
  Future<void> selectAssessment(String assessmentId) async {}

  @override
  Future<void> selectGroup(String groupId) async {}

  @override
  Future<void> loadStudentEvolution(
      String courseId, String studentId) async {}

  @override
  Future<void> loadMyAssessments(String studentId) async {}

  @override
  Future<void> selectMyAssessment(
      String studentId, String assessmentId) async {}

  @override
  void onInit() {}
}
