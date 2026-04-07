// TODO: If more non-persisted types emerge, extract to domain/types/
class StudentResult {
  StudentResult({
    required this.evaluatedId,
    required this.averageScore,
    required this.evaluationCount,
    this.criteriaAverages = const {},
  });

  String evaluatedId;
  double averageScore;
  int evaluationCount;
  Map<String, double> criteriaAverages;

  @override
  String toString() {
    return '[StudentResult]{evaluated: $evaluatedId, avg: $averageScore, count: $evaluationCount}';
  }
}
