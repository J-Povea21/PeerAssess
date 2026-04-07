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
        evaluationId: json['evaluationID']?.toString(),
        criteriaId: json['criteriaID']?.toString() ?? '',
        score: (json['score'] is num)
            ? (json['score'] as num).toDouble()
            : double.tryParse(json['score']?.toString() ?? '') ?? 0.0,
      );

  Map<String, dynamic> toJson() => {
        '_id': id ?? '0',
        'evaluationID': evaluationId,
        'criteriaID': criteriaId,
        'score': score,
      };

  Map<String, dynamic> toJsonNoId() => {
        'evaluationID': evaluationId,
        'criteriaID': criteriaId,
        'score': score,
      };

  @override
  String toString() {
    return '[CriteriaScore]{id: $id, criteria: $criteriaId, score: $score}';
  }
}
