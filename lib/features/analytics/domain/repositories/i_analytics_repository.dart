import '../../../assessment/domain/models/assessment.dart';
import '../models/activity_overview.dart';
import '../models/group_detail.dart';
import '../models/member_result.dart';
import '../models/student_evolution.dart';

/// Read-only repository that serves *derived* analytics data.
///
/// Everything here is computed on the fly from the existing persisted tables
/// (Assessments, Evaluations, CriteriaScores, Groups, GroupMembers, Criteria).
/// No analytics rows are stored — the repository just aggregates.
abstract class IAnalyticsRepository {
  // ─── Teacher side ────────────────────────────────────────────────────────

  /// All assessments created in [courseId] (active + closed). Used to
  /// populate the activity dropdown on the teacher analytics page.
  Future<List<Assessment>> getCourseAssessments(String courseId);

  /// Top-level aggregate (group averages, activity std-dev, anomalies) for
  /// one assessment. Used by the main teacher analytics screen.
  Future<ActivityOverview> getActivityOverview(String assessmentId);

  /// Full per-member breakdown for one group inside one assessment — powers
  /// the "Grupo X - Resultados" drill-down.
  Future<GroupDetail> getGroupDetail(String assessmentId, String groupId);

  /// Time-series of a student's performance across every assessment in
  /// [courseId] — powers the evolution screen.
  Future<StudentEvolution> getStudentEvolution(
      String courseId, String studentId);

  // ─── Student side ────────────────────────────────────────────────────────

  /// Assessments for which [studentId]'s group already has submitted
  /// evaluations — i.e. assessments the student can currently view their
  /// result for. Used to populate the dropdown on the student results page.
  Future<List<Assessment>> getMyAssessmentsWithResults(String studentId);

  /// [studentId]'s own aggregated result for a given [assessmentId].
  /// Returns null if the student isn't in a group of that assessment or
  /// nobody has evaluated them yet.
  Future<MemberResult?> getMyResultForAssessment(
      String studentId, String assessmentId);
}
