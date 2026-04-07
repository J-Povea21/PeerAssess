class Evaluation {
  Evaluation({
    this.id,
    required this.assessmentId,
    required this.evaluatorId,
    required this.evaluatedId,
    this.totalScore,
    this.submittedAt,
  });

  String? id;
  String assessmentId;
  String evaluatorId;
  String evaluatedId;
  double? totalScore;
  DateTime? submittedAt;

  factory Evaluation.fromJson(Map<String, dynamic> json) => Evaluation(
        id: json['_id']?.toString(),
        assessmentId: json['assessment_id']?.toString() ?? '',
        evaluatorId: json['evaluator_id']?.toString() ?? '',
        evaluatedId: json['evaluated_id']?.toString() ?? '',
        totalScore: (json['total_score'] is num)
            ? (json['total_score'] as num).toDouble()
            : double.tryParse(json['total_score']?.toString() ?? ''),
        submittedAt: json['submitted_at'] != null
            ? DateTime.tryParse(json['submitted_at'].toString())
            : null,
      );

  Map<String, dynamic> toJson() => {
        '_id': id ?? '0',
        'assessment_id': assessmentId,
        'evaluator_id': evaluatorId,
        'evaluated_id': evaluatedId,
        'total_score': totalScore,
        'submitted_at': submittedAt?.toUtc().toIso8601String(),
      };

  Map<String, dynamic> toJsonNoId() => {
        'assessment_id': assessmentId,
        'evaluator_id': evaluatorId,
        'evaluated_id': evaluatedId,
        'total_score': totalScore,
        'submitted_at': submittedAt?.toUtc().toIso8601String(),
      };

  @override
  String toString() {
    return '[Evaluation]{id: $id, evaluator: $evaluatorId, evaluated: $evaluatedId}';
  }
}
