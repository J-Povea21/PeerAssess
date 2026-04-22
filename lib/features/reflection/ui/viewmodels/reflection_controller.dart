import 'package:get/get.dart';
import 'package:loggy/loggy.dart';

import '../../domain/models/reflection.dart';
import '../../domain/models/reflection_prompt.dart';
import '../../domain/repositories/i_reflection_repository.dart';

/// Coordinates reflection state for both the student submission screen and
/// the teacher review screen.
///
/// One controller covers both because the data model is identical — the UI
/// just reads different slices of it.
class ReflectionController extends GetxController {
  final IReflectionRepository _repo;

  ReflectionController(this._repo);

  // ─── Prompts (shared) ──────────────────────────────────────────────────

  final RxList<ReflectionPrompt> prompts = <ReflectionPrompt>[].obs;
  final RxBool isLoadingPrompts = false.obs;

  // ─── Student: own reflection for the selected assessment ──────────────

  /// The student's most recently loaded reflection — null if they haven't
  /// submitted one yet. The UI reads [Reflection.answerFor] to prefill text
  /// fields when editing.
  final Rx<Reflection?> myReflection = Rx<Reflection?>(null);
  final RxBool isLoadingMyReflection = false.obs;
  final RxBool isSubmitting = false.obs;

  // ─── Teacher: list review ─────────────────────────────────────────────

  final RxList<Reflection> reviewList = <Reflection>[].obs;
  final RxBool isLoadingReviewList = false.obs;

  // ──────────────────────────────────────────────────────────────────────
  // Prompts
  // ──────────────────────────────────────────────────────────────────────

  Future<void> loadPrompts() async {
    if (prompts.isNotEmpty) return;
    logInfo('ReflectionController: loadPrompts');
    isLoadingPrompts.value = true;
    try {
      prompts.assignAll(await _repo.getPrompts());
    } catch (e) {
      logWarning('ReflectionController: loadPrompts failed — $e');
      prompts.clear();
    } finally {
      isLoadingPrompts.value = false;
    }
  }

  // ──────────────────────────────────────────────────────────────────────
  // Student
  // ──────────────────────────────────────────────────────────────────────

  /// Loads the student's previously submitted reflection (if any) for
  /// [assessmentId]. Called from [StudentResultsPage] whenever the student
  /// picks a different assessment in the dropdown.
  Future<void> loadMyReflection(
      String studentId, String assessmentId) async {
    logInfo(
        'ReflectionController: loadMyReflection student=$studentId assessment=$assessmentId');
    isLoadingMyReflection.value = true;
    try {
      myReflection.value =
          await _repo.getMyReflection(studentId, assessmentId);
    } catch (e) {
      logWarning('ReflectionController: loadMyReflection failed — $e');
      myReflection.value = null;
    } finally {
      isLoadingMyReflection.value = false;
    }
  }

  /// Submits (or overwrites) the student's reflection for [assessmentId].
  /// Returns true on success so the view can show feedback.
  Future<bool> submitMyReflection({
    required String studentId,
    required String assessmentId,
    required Map<String, String> answers,
  }) async {
    logInfo(
        'ReflectionController: submitMyReflection student=$studentId assessment=$assessmentId');
    isSubmitting.value = true;
    try {
      final stored = await _repo.submitReflection(Reflection(
        studentId: studentId,
        assessmentId: assessmentId,
        answers: answers,
      ));
      myReflection.value = stored;
      return true;
    } catch (e) {
      logWarning('ReflectionController: submitMyReflection failed — $e');
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // ──────────────────────────────────────────────────────────────────────
  // Teacher
  // ──────────────────────────────────────────────────────────────────────

  /// Loads every reflection for [assessmentId] (most-recent-first).
  Future<void> loadReflectionsByAssessment(String assessmentId) async {
    logInfo(
        'ReflectionController: loadReflectionsByAssessment assessment=$assessmentId');
    isLoadingReviewList.value = true;
    try {
      reviewList.assignAll(
          await _repo.getReflectionsByAssessment(assessmentId));
    } catch (e) {
      logWarning(
          'ReflectionController: loadReflectionsByAssessment failed — $e');
      reviewList.clear();
    } finally {
      isLoadingReviewList.value = false;
    }
  }

  /// Loads every reflection submitted in any assessment of [courseId].
  /// Used by the teacher's course-wide review entry point.
  Future<void> loadReflectionsByCourse(String courseId) async {
    logInfo(
        'ReflectionController: loadReflectionsByCourse course=$courseId');
    isLoadingReviewList.value = true;
    try {
      reviewList.assignAll(await _repo.getReflectionsByCourse(courseId));
    } catch (e) {
      logWarning(
          'ReflectionController: loadReflectionsByCourse failed — $e');
      reviewList.clear();
    } finally {
      isLoadingReviewList.value = false;
    }
  }

  /// Returns the human-readable question text for a stored promptId.
  /// When a future prompt change removes an id, we still show the id so no
  /// historical answer is lost.
  String questionFor(String promptId) {
    final match = prompts.firstWhereOrNull((p) => p.id == promptId);
    return match?.question ?? promptId;
  }
}
