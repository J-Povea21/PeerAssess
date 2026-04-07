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
        categoryId: json['category_id']?.toString() ?? '',
        title: json['title']?.toString() ?? '---',
        visibility: json['visibility']?.toString() ?? 'private',
        timeWindowMinutes: json['time_window'] is int
            ? json['time_window']
            : int.tryParse(json['time_window']?.toString() ?? '') ?? 0,
        status: json['status']?.toString() ?? 'active',
        deadline: json['deadline'] != null
            ? DateTime.tryParse(json['deadline'].toString())
            : null,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
      );

  Map<String, dynamic> toJson() => {
        '_id': id ?? '0',
        'category_id': categoryId,
        'title': title,
        'visibility': visibility,
        'time_window': timeWindowMinutes,
        'status': status,
        'deadline': deadline?.toUtc().toIso8601String(),
        'created_at': createdAt?.toUtc().toIso8601String(),
      };

  Map<String, dynamic> toJsonNoId() => {
        'category_id': categoryId,
        'title': title,
        'visibility': visibility,
        'time_window': timeWindowMinutes,
        'status': status,
        'deadline': deadline?.toUtc().toIso8601String(),
        'created_at': createdAt?.toUtc().toIso8601String(),
      };

  @override
  String toString() {
    return '[Assessment]{id: $id, title: $title, status: $status}';
  }
}
