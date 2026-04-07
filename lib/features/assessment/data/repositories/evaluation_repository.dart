import '../../domain/models/assessment.dart';
import '../../domain/models/criteria_score.dart';
import '../../domain/models/evaluation.dart';
import '../../domain/models/student_result.dart';
import '../../domain/repositories/i_evaluation_repository.dart';
import '../datasources/i_evaluation_source.dart';

class EvaluationRepository implements IEvaluationRepository {
  late IEvaluationSource source;

  EvaluationRepository(this.source);

  @override
  Future<List<Assessment>> getPendingAssessments(String studentId) async =>
      await source.getPendingAssessments(studentId);

  @override
  Future<bool> submitEvaluation(
          Evaluation evaluation, List<CriteriaScore> scores) async =>
      await source.submitEvaluation(evaluation, scores);

  @override
  Future<List<StudentResult>> getGroupResults(
          String assessmentId, String groupId) async =>
      await source.getGroupResults(assessmentId, groupId);
}
