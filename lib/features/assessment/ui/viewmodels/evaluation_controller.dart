import 'package:get/get.dart';
import 'package:loggy/loggy.dart';

import '../../domain/models/assessment.dart';
import '../../domain/models/criteria_score.dart';
import '../../domain/models/evaluation.dart';
import '../../domain/repositories/i_evaluation_repository.dart';

class EvaluationController extends GetxController {
  final IEvaluationRepository repository;

  final RxList<Assessment> _pendingAssessments = <Assessment>[].obs;
  final RxBool isLoading = false.obs;

  List<Assessment> get pendingAssessments => _pendingAssessments;

  EvaluationController(this.repository);

  Future<void> loadPendingAssessments(String studentId) async {
    logInfo(
        'EvaluationController: Loading pending assessments for $studentId');
    isLoading.value = true;
    try {
      _pendingAssessments.value =
          await repository.getPendingAssessments(studentId);
    } catch (e) {
      logWarning(
          'EvaluationController: Failed to load pending assessments — $e');
      _pendingAssessments.clear();
    } finally {
      isLoading.value = false;
    }
  }

  /// Submits evaluations for all peers in a single batch.
  ///
  /// Loops over each evaluation and calls [repository.submitEvaluation] once
  /// per peer. Returns `false` if any submission fails.
  Future<bool> submitAllEvaluations(
    List<Evaluation> evaluations,
    List<List<CriteriaScore>> scoresPerEvaluation,
  ) async {
    logInfo(
        'EvaluationController: Submitting ${evaluations.length} evaluations');
    isLoading.value = true;
    bool allSucceeded = true;
    try {
      for (int i = 0; i < evaluations.length; i++) {
        final success = await repository.submitEvaluation(
          evaluations[i],
          scoresPerEvaluation[i],
        );
        if (!success) {
          logWarning(
              'EvaluationController: Failed to submit evaluation for '
              'peer ${evaluations[i].evaluatedId}');
          allSucceeded = false;
        }
      }
    } catch (e) {
      logWarning('EvaluationController: Submission error — $e');
      allSucceeded = false;
    } finally {
      isLoading.value = false;
    }
    return allSucceeded;
  }
}
