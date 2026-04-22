import '../models/reflection.dart';
import '../models/reflection_prompt.dart';

/// Contract for reading + writing post-evaluation reflections.
///
/// Why split this from the analytics repository? Analytics is read-only and
/// derived, while reflections have ownership (a student writes them, a
/// teacher reads them). Different concerns → different interfaces, each
/// small enough to stub for tests.
abstract class IReflectionRepository {
  /// The fixed list of reflection questions every student answers. Today
  /// these are hard-coded in the data source; the interface still returns a
  /// future so a backend-driven prompt catalogue can drop in without any
  /// consumer changes.
  Future<List<ReflectionPrompt>> getPrompts();

  /// Inserts a new reflection or overwrites the existing one for
  /// (studentID, assessmentID). Returns the stored record (with the
  /// backend-assigned `_id` and `submittedAt` filled in).
  Future<Reflection> submitReflection(Reflection reflection);

  /// The student's own reflection for [assessmentId], or null if they
  /// haven't submitted one yet.
  Future<Reflection?> getMyReflection(String studentId, String assessmentId);

  /// Every reflection submitted for [assessmentId] — used on the teacher
  /// review screen. Each entry carries resolved studentName + assessmentTitle
  /// so the UI doesn't have to cross-reference.
  Future<List<Reflection>> getReflectionsByAssessment(String assessmentId);

  /// Every reflection submitted in any assessment of [courseId]. Used when
  /// the teacher wants a course-wide review across activities.
  Future<List<Reflection>> getReflectionsByCourse(String courseId);
}
