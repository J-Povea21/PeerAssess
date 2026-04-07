class Criteria {
  Criteria({
    this.id,
    this.assessmentId,
    required this.name,
    required this.weight,
  });

  String? id;
  String? assessmentId;
  String name;
  double weight;

  factory Criteria.fromJson(Map<String, dynamic> json) => Criteria(
        id: json['_id']?.toString(),
        assessmentId: json['assessment_id']?.toString(),
        name: json['name']?.toString() ?? '---',
        weight: (json['weight'] is num)
            ? (json['weight'] as num).toDouble()
            : double.tryParse(json['weight']?.toString() ?? '') ?? 0.0,
      );

  Map<String, dynamic> toJson() => {
        '_id': id ?? '0',
        'assessment_id': assessmentId,
        'name': name,
        'weight': weight,
      };

  Map<String, dynamic> toJsonNoId() => {
        'assessment_id': assessmentId,
        'name': name,
        'weight': weight,
      };

  @override
  String toString() {
    return '[Criteria]{id: $id, name: $name, weight: $weight}';
  }
}
