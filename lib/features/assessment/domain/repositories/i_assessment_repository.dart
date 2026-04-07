import '../models/assessment.dart';
import '../models/criteria.dart';

abstract class IAssessmentRepository {
  Future<bool> createAssessment(Assessment assessment, List<Criteria> criteria);

  Future<List<Assessment>> getAssessmentsByCourse(String courseId);

  Future<bool> cancelAssessment(String assessmentId);
}
