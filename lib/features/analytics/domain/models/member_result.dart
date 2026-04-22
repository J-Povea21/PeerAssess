/// Aggregated result for a single student in the context of one assessment.
///
/// Shared by the group detail view (list of members) and the student's own
/// results view (their single entry). The [criteriaScores] map is keyed by
/// criterion *name* (not id) so the UI can render it without a second lookup
/// against the Criteria table.
class MemberResult {
  MemberResult({
    required this.studentId,
    required this.studentName,
    required this.average,
    required this.evaluationCount,
    this.criteriaScores = const {},
  });

  final String studentId;
  final String studentName;
  final double average;
  final int evaluationCount;
  final Map<String, double> criteriaScores;

  /// True when no peer has evaluated this student yet.
  bool get hasNoResults => evaluationCount == 0;

  @override
  String toString() =>
      '[MemberResult]{student: $studentName, avg: $average, n: $evaluationCount}';
}
