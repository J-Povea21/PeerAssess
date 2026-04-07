class Assessment {
  Assessment({
    this.id,
    required this.categoryId,
    required this.title,
    required this.visibility,
    required this.timeWindowMinutes,
    this.status = 'active',
    this.deadline,
    this.createdAt,
  });

  String? id;
  String categoryId;
  String title;
  String visibility;
  int timeWindowMinutes;
  String status;
  DateTime? deadline;
  DateTime? createdAt;

  factory Assessment.fromJson(Map<String, dynamic> json) => Assessment(
        id: json['_id']?.toString(),
        categoryId: json['categoryID']?.toString() ?? '',
        title: json['title']?.toString() ?? '---',
        visibility: json['visibility']?.toString() ?? 'private',
        timeWindowMinutes: json['timeWindow'] is int
            ? json['timeWindow']
            : int.tryParse(json['timeWindow']?.toString() ?? '') ?? 0,
        status: json['status']?.toString() ?? 'active',
        deadline: json['deadline'] != null
            ? DateTime.tryParse(json['deadline'].toString())
            : null,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString())
            : null,
      );

  Map<String, dynamic> toJson() => {
        '_id': id ?? '0',
        'categoryID': categoryId,
        'title': title,
        'visibility': visibility,
        'timeWindow': timeWindowMinutes,
        'status': status,
        'deadline': deadline?.toUtc().toIso8601String(),
        'createdAt': createdAt?.toUtc().toIso8601String(),
      };

  Map<String, dynamic> toJsonNoId() => {
        'categoryID': categoryId,
        'title': title,
        'visibility': visibility,
        'timeWindow': timeWindowMinutes,
        'status': status,
        'deadline': deadline?.toUtc().toIso8601String(),
        'createdAt': createdAt?.toUtc().toIso8601String(),
      };

  @override
  String toString() {
    return '[Assessment]{id: $id, title: $title, status: $status}';
  }
}
