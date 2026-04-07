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
        assessmentId: json['assessmentID']?.toString() ?? '',
        evaluatorId: json['evaluatorID']?.toString() ?? '',
        evaluatedId: json['evaluatedID']?.toString() ?? '',
        totalScore: (json['totalScore'] is num)
            ? (json['totalScore'] as num).toDouble()
            : double.tryParse(json['totalScore']?.toString() ?? ''),
        submittedAt: json['submittedAt'] != null
            ? DateTime.tryParse(json['submittedAt'].toString())
            : null,
      );

  Map<String, dynamic> toJson() => {
        '_id': id ?? '0',
        'assessmentID': assessmentId,
        'evaluatorID': evaluatorId,
        'evaluatedID': evaluatedId,
        'totalScore': totalScore,
        'submittedAt': submittedAt?.toUtc().toIso8601String(),
      };

  Map<String, dynamic> toJsonNoId() => {
        'assessmentID': assessmentId,
        'evaluatorID': evaluatorId,
        'evaluatedID': evaluatedId,
        'totalScore': totalScore,
        'submittedAt': submittedAt?.toUtc().toIso8601String(),
      };

  @override
  String toString() {
    return '[Evaluation]{id: $id, evaluator: $evaluatorId, evaluated: $evaluatedId}';
  }
}
