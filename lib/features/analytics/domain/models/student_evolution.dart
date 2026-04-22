/// Time-series view of one student's performance across every assessment in
/// a course. Drives the evolution (line chart + criteria ranking) screen.
class StudentEvolution {
  StudentEvolution({
    required this.studentId,
    required this.studentName,
    required this.courseId,
    required this.courseName,
    required this.points,
    required this.criteriaDeltas,
  });

  final String studentId;
  final String studentName;
  final String courseId;
  final String courseName;

  /// One point per assessment the student received results for, in
  /// chronological order (oldest first).
  final List<EvolutionPoint> points;

  /// Per-criterion improvement from the student's first recorded assessment
  /// to their most recent — sorted by delta descending. Powers the
  /// "Ranking de mejora" card.
  final List<CriterionDelta> criteriaDeltas;

  /// Most recent assessment's overall average (or 0.0 if no points).
  double get latestAverage => points.isEmpty ? 0.0 : points.last.average;
}

/// A single (assessment, score) observation.
class EvolutionPoint {
  EvolutionPoint({
    required this.assessmentId,
    required this.assessmentTitle,
    required this.average,
    required this.criteriaAverages,
    this.submittedAt,
  });

  final String assessmentId;
  final String assessmentTitle;
  final double average;

  /// Criterion name → score for this specific assessment.
  final Map<String, double> criteriaAverages;

  /// When the latest evaluation for this assessment was submitted (used only
  /// for chronological ordering — null when unknown).
  final DateTime? submittedAt;
}

/// How much a single criterion moved between the student's first and last
/// assessment. Positive delta = improvement.
class CriterionDelta {
  CriterionDelta({
    required this.name,
    required this.current,
    required this.previous,
  });

  final String name;
  final double current;
  final double previous;

  double get delta => current - previous;
}
