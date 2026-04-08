import 'package:get/get.dart';
import 'package:loggy/loggy.dart';

import '../../domain/models/assessment.dart';
import '../../domain/models/criteria.dart';
import '../../domain/repositories/i_assessment_repository.dart';

class AssessmentController extends GetxController {
  final IAssessmentRepository repository;

  final RxList<Assessment> _assessments = <Assessment>[].obs;
  final RxBool isLoading = false.obs;

  List<Assessment> get assessments => _assessments;

  AssessmentController(this.repository);

  Future<void> loadAssessments(String courseId) async {
    logInfo('AssessmentController: Loading assessments for course $courseId');
    isLoading.value = true;
    try {
      _assessments.value = await repository.getAssessmentsByCourse(courseId);
    } catch (e) {
      logWarning('AssessmentController: Failed to load assessments — $e');
      _assessments.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createAssessment(
      Assessment assessment, List<Criteria> criteria, String courseId) async {
    logInfo('AssessmentController: Creating assessment "${assessment.title}"');
    isLoading.value = true;
    try {
      final result = await repository.createAssessment(assessment, criteria);
      if (result) {
        await loadAssessments(courseId);
      }
      return result;
    } catch (e) {
      logWarning('AssessmentController: Failed to create assessment — $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> cancelAssessment(String assessmentId) async {
    logInfo('AssessmentController: Cancelling assessment $assessmentId');
    isLoading.value = true;
    try {
      return await repository.cancelAssessment(assessmentId);
    } catch (e) {
      logWarning('AssessmentController: Failed to cancel assessment — $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
