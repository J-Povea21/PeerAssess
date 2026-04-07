import '../../domain/models/assessment.dart';
import '../../domain/models/criteria.dart';

abstract class IAssessmentSource {
  Future<bool> createAssessment(Assessment assessment, List<Criteria> criteria);

  Future<List<Assessment>> getAssessmentsByCourse(String courseId);

  Future<bool> cancelAssessment(String assessmentId);
}
