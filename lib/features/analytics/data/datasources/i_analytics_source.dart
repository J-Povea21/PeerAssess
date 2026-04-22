import '../../../assessment/domain/models/assessment.dart';
import '../../domain/models/activity_overview.dart';
import '../../domain/models/group_detail.dart';
import '../../domain/models/member_result.dart';
import '../../domain/models/student_evolution.dart';

/// Data-source contract for analytics reads. Mirrors [IAnalyticsRepository];
/// the repository delegates 1-to-1 to whichever implementation is registered
/// (today: [RemoteAnalyticsSource]).
abstract class IAnalyticsSource {
  Future<List<Assessment>> getCourseAssessments(String courseId);

  Future<ActivityOverview> getActivityOverview(String assessmentId);

  Future<GroupDetail> getGroupDetail(String assessmentId, String groupId);

  Future<StudentEvolution> getStudentEvolution(
      String courseId, String studentId);

  Future<List<Assessment>> getMyAssessmentsWithResults(String studentId);

  Future<MemberResult?> getMyResultForAssessment(
      String studentId, String assessmentId);
}
