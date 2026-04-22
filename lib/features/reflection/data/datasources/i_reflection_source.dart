import '../../domain/models/reflection.dart';
import '../../domain/models/reflection_prompt.dart';

/// Data-source contract mirroring [IReflectionRepository]. The repository is
/// a pure delegator; all backend logic lives in whichever implementation is
/// registered (today: [RemoteReflectionSource]).
abstract class IReflectionSource {
  Future<List<ReflectionPrompt>> getPrompts();

  Future<Reflection> submitReflection(Reflection reflection);

  Future<Reflection?> getMyReflection(String studentId, String assessmentId);

  Future<List<Reflection>> getReflectionsByAssessment(String assessmentId);

  Future<List<Reflection>> getReflectionsByCourse(String courseId);
}
