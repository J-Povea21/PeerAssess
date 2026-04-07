import '../../domain/models/assessment.dart';
import '../../domain/models/criteria.dart';
import '../../domain/repositories/i_assessment_repository.dart';
import '../datasources/i_assessment_source.dart';

class AssessmentRepository implements IAssessmentRepository {
  late IAssessmentSource source;

  AssessmentRepository(this.source);

  @override
  Future<bool> createAssessment(
          Assessment assessment, List<Criteria> criteria) async =>
      await source.createAssessment(assessment, criteria);

  @override
  Future<List<Assessment>> getAssessmentsByCourse(String courseId) async =>
      await source.getAssessmentsByCourse(courseId);

  @override
  Future<bool> cancelAssessment(String assessmentId) async =>
      await source.cancelAssessment(assessmentId);
}
