import '../../../assessment/domain/models/assessment.dart';
import '../../domain/models/activity_overview.dart';
import '../../domain/models/group_detail.dart';
import '../../domain/models/member_result.dart';
import '../../domain/models/student_evolution.dart';
import '../../domain/repositories/i_analytics_repository.dart';
import '../datasources/i_analytics_source.dart';

/// Concrete analytics repository. Pure delegator — all aggregation logic
/// lives in [IAnalyticsSource] implementations.
class AnalyticsRepository implements IAnalyticsRepository {
  late IAnalyticsSource source;

  AnalyticsRepository(this.source);

  @override
  Future<List<Assessment>> getCourseAssessments(String courseId) async =>
      await source.getCourseAssessments(courseId);

  @override
  Future<ActivityOverview> getActivityOverview(String assessmentId) async =>
      await source.getActivityOverview(assessmentId);

  @override
  Future<GroupDetail> getGroupDetail(
          String assessmentId, String groupId) async =>
      await source.getGroupDetail(assessmentId, groupId);

  @override
  Future<StudentEvolution> getStudentEvolution(
          String courseId, String studentId) async =>
      await source.getStudentEvolution(courseId, studentId);

  @override
  Future<List<Assessment>> getMyAssessmentsWithResults(String studentId) async =>
      await source.getMyAssessmentsWithResults(studentId);

  @override
  Future<MemberResult?> getMyResultForAssessment(
          String studentId, String assessmentId) async =>
      await source.getMyResultForAssessment(studentId, assessmentId);
}
