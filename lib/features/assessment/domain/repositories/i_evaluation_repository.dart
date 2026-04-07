import '../models/assessment.dart';
import '../models/criteria_score.dart';
import '../models/evaluation.dart';
import '../models/student_result.dart';

abstract class IEvaluationRepository {
  Future<List<Assessment>> getPendingAssessments(String studentId);

  Future<bool> submitEvaluation(
      Evaluation evaluation, List<CriteriaScore> scores);

  Future<List<StudentResult>> getGroupResults(
      String assessmentId, String groupId);
}
