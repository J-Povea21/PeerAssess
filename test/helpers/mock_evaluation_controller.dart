import 'dart:ui';

import 'package:f_clean_template/features/assessment/domain/models/assessment.dart';
import 'package:f_clean_template/features/assessment/domain/models/criteria_score.dart';
import 'package:f_clean_template/features/assessment/domain/models/evaluation.dart';
import 'package:f_clean_template/features/assessment/ui/viewmodels/evaluation_controller.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';

/// Mock [EvaluationController] for Level 1 widget tests.
class MockEvaluationController extends GetxService
    with Mock
    implements EvaluationController {
  final RxList<Assessment> _pendingAssessments = <Assessment>[].obs;

  @override
  final RxBool isLoading = false.obs;

  @override
  List<Assessment> get pendingAssessments => _pendingAssessments;

  void setPendingAssessments(List<Assessment> list) {
    _pendingAssessments.value = list;
  }

  /// Optional callback to verify submitAllEvaluations was called.
  VoidCallback? onSubmitCalled;

  /// Controls the return value of submitAllEvaluations.
  bool submitReturns = true;

  @override
  Future<void> loadPendingAssessments(String studentId) async {}

  @override
  Future<bool> submitAllEvaluations(
      List<Evaluation> evaluations,
      List<List<CriteriaScore>> scoresPerEvaluation) async {
    onSubmitCalled?.call();
    return submitReturns;
  }

  @override
  void onInit() {}
}
