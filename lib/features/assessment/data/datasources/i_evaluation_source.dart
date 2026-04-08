import '../../domain/models/assessment.dart';
import '../../domain/models/criteria_score.dart';
import '../../domain/models/evaluation.dart';
import '../../domain/models/student_result.dart';

abstract class IEvaluationSource {
  Future<List<Assessment>> getPendingAssessments(String studentId);

  Future<bool> submitEvaluation(
      Evaluation evaluation, List<CriteriaScore> scores);

  Future<List<StudentResult>> getGroupResults(
      String assessmentId, String groupId);
}
