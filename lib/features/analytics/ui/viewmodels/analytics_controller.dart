import 'package:get/get.dart';
import 'package:loggy/loggy.dart';

import '../../../assessment/domain/models/assessment.dart';
import '../../../course/domain/repositories/i_course_repository.dart';
import '../../domain/models/activity_overview.dart';
import '../../domain/models/group_detail.dart';
import '../../domain/models/member_result.dart';
import '../../domain/models/student_evolution.dart';
import '../../domain/repositories/i_analytics_repository.dart';

/// Holds selection + derived state for the three teacher analytics views
/// (activity overview, group detail, student evolution) and the student
/// results view.
///
/// All four views share one controller because their selections cascade:
/// picking an activity on the analytics screen should carry into the group
/// drill-down without re-asking the user.
class AnalyticsController extends GetxController {
  final IAnalyticsRepository _analyticsRepo;
  final ICourseRepository _courseRepo;

  AnalyticsController(this._analyticsRepo, this._courseRepo);

  // ─── Teacher: activity picker ──────────────────────────────────────────

  /// Flat list of every assessment across every course the teacher owns.
  /// Ordered most-recent-first so the dropdown opens onto the latest work.
  final RxList<Assessment> teacherAssessments = <Assessment>[].obs;

  /// assessmentId → courseName, used to label dropdown entries as
  /// "Course Name - Assessment Title".
  final RxMap<String, String> courseNameByAssessment =
      <String, String>{}.obs;

  /// assessmentId → courseId, needed when navigating from a group member
  /// to that student's cross-course evolution screen.
  final RxMap<String, String> courseIdByAssessment = <String, String>{}.obs;

  /// Currently selected activity on the teacher analytics page.
  final Rx<String?> selectedAssessmentId = Rx<String?>(null);

  // ─── Teacher: derived aggregates ───────────────────────────────────────

  final Rx<ActivityOverview?> activityOverview = Rx<ActivityOverview?>(null);
  final Rx<GroupDetail?> groupDetail = Rx<GroupDetail?>(null);
  final Rx<StudentEvolution?> studentEvolution = Rx<StudentEvolution?>(null);

  final RxBool isLoadingAssessments = false.obs;
  final RxBool isLoadingOverview = false.obs;
  final RxBool isLoadingGroup = false.obs;
  final RxBool isLoadingEvolution = false.obs;

  // ─── Student: own results ──────────────────────────────────────────────

  final RxList<Assessment> myAssessments = <Assessment>[].obs;
  final Rx<String?> selectedMyAssessmentId = Rx<String?>(null);
  final Rx<MemberResult?> myResult = Rx<MemberResult?>(null);
  final RxBool isLoadingMyAssessments = false.obs;
  final RxBool isLoadingMyResult = false.obs;

  // ──────────────────────────────────────────────────────────────────────
  // Teacher actions
  // ──────────────────────────────────────────────────────────────────────

  /// Loads every assessment in every course owned by [teacherId], sorted
  /// most-recent-first. Auto-selects the latest and fetches its overview.
  Future<void> loadTeacherAssessments(String teacherId) async {
    logInfo('AnalyticsController: loadTeacherAssessments teacher=$teacherId');
    isLoadingAssessments.value = true;
    try {
      final courses = await _courseRepo.getCoursesByTeacher(teacherId);
      final all = <Assessment>[];
      final courseNames = <String, String>{};
      final courseIds = <String, String>{};

      for (final c in courses) {
        if (c.id == null) continue;
        final assessments =
            await _analyticsRepo.getCourseAssessments(c.id!);
        for (final a in assessments) {
          if (a.id == null) continue;
          all.add(a);
          courseNames[a.id!] = c.name;
          courseIds[a.id!] = c.id!;
        }
      }

      // Most recent first. getCourseAssessments already sorts oldest→newest;
      // we just reverse for teacher display.
      //
      // Use assignAll rather than `.value = ...` — if the right-hand side
      // happens to be a const/unmodifiable list (some data-source paths
      // return `const []`), `.value =` stores the unmodifiable reference,
      // and a later `.clear()` throws.
      teacherAssessments.assignAll(all.reversed.toList());
      courseNameByAssessment.value = courseNames;
      courseIdByAssessment.value = courseIds;

      if (teacherAssessments.isNotEmpty) {
        final firstId = teacherAssessments.first.id;
        if (firstId != null) {
          await selectAssessment(firstId);
        }
      } else {
        selectedAssessmentId.value = null;
        activityOverview.value = null;
      }
    } catch (e) {
      logWarning('AnalyticsController: loadTeacherAssessments failed — $e');
      teacherAssessments.clear();
      courseNameByAssessment.clear();
      courseIdByAssessment.clear();
    } finally {
      isLoadingAssessments.value = false;
    }
  }

  /// Selects an assessment and fetches its overview. Clears previously
  /// loaded group detail since it no longer matches the selection.
  Future<void> selectAssessment(String assessmentId) async {
    logInfo('AnalyticsController: selectAssessment $assessmentId');
    selectedAssessmentId.value = assessmentId;
    groupDetail.value = null;
    isLoadingOverview.value = true;
    try {
      activityOverview.value =
          await _analyticsRepo.getActivityOverview(assessmentId);
    } catch (e) {
      logWarning('AnalyticsController: overview failed — $e');
      activityOverview.value = null;
    } finally {
      isLoadingOverview.value = false;
    }
  }

  /// Reloads the overview for the currently selected assessment (pull-to-
  /// refresh, post-submit, etc.).
  Future<void> refreshOverview() async {
    final id = selectedAssessmentId.value;
    if (id != null) await selectAssessment(id);
  }

  /// Loads the per-group breakdown for an assessment. Called when the
  /// teacher taps a bar in the group-comparison chart.
  Future<void> loadGroupDetail(String assessmentId, String groupId) async {
    logInfo(
        'AnalyticsController: loadGroupDetail assessment=$assessmentId group=$groupId');
    isLoadingGroup.value = true;
    try {
      groupDetail.value =
          await _analyticsRepo.getGroupDetail(assessmentId, groupId);
    } catch (e) {
      logWarning('AnalyticsController: group detail failed — $e');
      groupDetail.value = null;
    } finally {
      isLoadingGroup.value = false;
    }
  }

  /// Loads [studentId]'s evolution across every assessment in [courseId].
  Future<void> loadStudentEvolution(
      String courseId, String studentId) async {
    logInfo(
        'AnalyticsController: loadStudentEvolution course=$courseId student=$studentId');
    isLoadingEvolution.value = true;
    try {
      studentEvolution.value =
          await _analyticsRepo.getStudentEvolution(courseId, studentId);
    } catch (e) {
      logWarning('AnalyticsController: evolution failed — $e');
      studentEvolution.value = null;
    } finally {
      isLoadingEvolution.value = false;
    }
  }

  /// Convenience: resolves the course for the currently selected assessment
  /// and loads evolution. Used from the group-detail view where only the
  /// assessmentId is in scope.
  Future<void> loadEvolutionForCurrentAssessment(String studentId) async {
    final assessmentId = selectedAssessmentId.value;
    if (assessmentId == null) return;
    final courseId = courseIdByAssessment[assessmentId];
    if (courseId == null) return;
    await loadStudentEvolution(courseId, studentId);
  }

  // ──────────────────────────────────────────────────────────────────────
  // Student actions
  // ──────────────────────────────────────────────────────────────────────

  /// Loads the student's completed assessments (those with results) and
  /// auto-selects the most recent.
  Future<void> loadMyAssessments(String studentId) async {
    logInfo('AnalyticsController: loadMyAssessments student=$studentId');
    isLoadingMyAssessments.value = true;
    try {
      myAssessments.assignAll(
          await _analyticsRepo.getMyAssessmentsWithResults(studentId));
      if (myAssessments.isNotEmpty) {
        final firstId = myAssessments.first.id;
        if (firstId != null) {
          await selectMyAssessment(studentId, firstId);
        }
      } else {
        selectedMyAssessmentId.value = null;
        myResult.value = null;
      }
    } catch (e) {
      logWarning('AnalyticsController: loadMyAssessments failed — $e');
      myAssessments.clear();
      myResult.value = null;
    } finally {
      isLoadingMyAssessments.value = false;
    }
  }

  /// Picks an assessment and loads the student's own result for it.
  Future<void> selectMyAssessment(
      String studentId, String assessmentId) async {
    logInfo(
        'AnalyticsController: selectMyAssessment student=$studentId assessment=$assessmentId');
    selectedMyAssessmentId.value = assessmentId;
    isLoadingMyResult.value = true;
    try {
      myResult.value = await _analyticsRepo.getMyResultForAssessment(
          studentId, assessmentId);
    } catch (e) {
      logWarning('AnalyticsController: myResult failed — $e');
      myResult.value = null;
    } finally {
      isLoadingMyResult.value = false;
    }
  }
}
