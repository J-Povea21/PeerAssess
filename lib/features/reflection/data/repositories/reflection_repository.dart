import '../../domain/models/reflection.dart';
import '../../domain/models/reflection_prompt.dart';
import '../../domain/repositories/i_reflection_repository.dart';
import '../datasources/i_reflection_source.dart';

/// Concrete reflection repository. Pure delegator — all backend concerns
/// (caching, JSON encoding, Roble schema) are the data source's problem.
class ReflectionRepository implements IReflectionRepository {
  final IReflectionSource source;

  ReflectionRepository(this.source);

  @override
  Future<List<ReflectionPrompt>> getPrompts() => source.getPrompts();

  @override
  Future<Reflection> submitReflection(Reflection reflection) =>
      source.submitReflection(reflection);

  @override
  Future<Reflection?> getMyReflection(String studentId, String assessmentId) =>
      source.getMyReflection(studentId, assessmentId);

  @override
  Future<List<Reflection>> getReflectionsByAssessment(String assessmentId) =>
      source.getReflectionsByAssessment(assessmentId);

  @override
  Future<List<Reflection>> getReflectionsByCourse(String courseId) =>
      source.getReflectionsByCourse(courseId);
}
