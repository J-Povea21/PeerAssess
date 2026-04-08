import 'dart:ui';

import 'package:f_clean_template/features/assessment/domain/models/assessment.dart';
import 'package:f_clean_template/features/assessment/domain/models/criteria.dart';
import 'package:f_clean_template/features/assessment/ui/viewmodels/assessment_controller.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';

/// Mock [AssessmentController] for Level 1 widget tests.
class MockAssessmentController extends GetxService
    with Mock
    implements AssessmentController {
  final RxList<Assessment> _assessments = <Assessment>[].obs;

  @override
  final RxBool isLoading = false.obs;

  @override
  List<Assessment> get assessments => _assessments;

  void setAssessments(List<Assessment> list) {
    _assessments.value = list;
  }

  @override
  Future<void> loadAssessments(String courseId) async {}

  /// Optional callback to verify createAssessment was called in tests.
  VoidCallback? onCreateCalled;

  /// Controls the return value of createAssessment.
  bool createReturns = true;

  @override
  Future<bool> createAssessment(
      Assessment assessment, List<Criteria> criteria, String courseId) async {
    onCreateCalled?.call();
    return createReturns;
  }

  @override
  Future<bool> cancelAssessment(String assessmentId) async {
    return true;
  }

  @override
  void onInit() {}
}
