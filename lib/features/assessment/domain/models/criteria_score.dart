class CriteriaScore {
  CriteriaScore({
    this.id,
    this.evaluationId,
    required this.criteriaId,
    required this.score,
  });

  String? id;
  String? evaluationId;
  String criteriaId;
  double score;

  /// Valid scores: 2.0, 3.0, 4.0, 5.0
  static final validScores = {2.0, 3.0, 4.0, 5.0};

  bool get isValidScore => validScores.contains(score);

  factory CriteriaScore.fromJson(Map<String, dynamic> json) => CriteriaScore(
        id: json['_id']?.toString(),
        evaluationId: json['evaluation_id']?.toString(),
        criteriaId: json['criteria_id']?.toString() ?? '',
        score: (json['score'] is num)
            ? (json['score'] as num).toDouble()
            : double.tryParse(json['score']?.toString() ?? '') ?? 0.0,
      );

  Map<String, dynamic> toJson() => {
        '_id': id ?? '0',
        'evaluation_id': evaluationId,
        'criteria_id': criteriaId,
        'score': score,
      };

  Map<String, dynamic> toJsonNoId() => {
        'evaluation_id': evaluationId,
        'criteria_id': criteriaId,
        'score': score,
      };

  @override
  String toString() {
    return '[CriteriaScore]{id: $id, criteria: $criteriaId, score: $score}';
  }
}
