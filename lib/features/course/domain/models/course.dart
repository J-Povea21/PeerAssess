enum CourseStatus { active, pending }

class Course {
  Course({
    this.id,
    required this.name,
    required this.semester,
    required this.studentCount,
    required this.status,
    required this.categoryCount,
    required this.evaluationCount,
    this.teacherName,
    this.groupName,
    this.pendingEvaluations = 0,
    this.enrollmentCode,
  });

  String? id;
  String name;
  String semester;
  int studentCount;
  CourseStatus status;
  int categoryCount;
  int evaluationCount;
  String? teacherName;
  String? groupName;
  int pendingEvaluations;
  String? enrollmentCode;

  factory Course.fromJson(Map<String, dynamic> json) => Course(
        id: json["_id"],
        name: json["name"] ?? "---",
        semester: json["semester"] ?? "---",
        studentCount: json["studentCount"] ?? 0,
        status: json["status"] == "active"
            ? CourseStatus.active
            : CourseStatus.pending,
        categoryCount: json["categoryCount"] ?? 0,
        evaluationCount: json["evaluationCount"] ?? 0,
        teacherName: json["teacherName"],
        groupName: json["groupName"],
        pendingEvaluations: json["pendingEvaluations"] ?? 0,
        enrollmentCode: json["enrollmentCode"],
      );

  Map<String, dynamic> toJson() => {
        "_id": id ?? "0",
        "name": name,
        "semester": semester,
        "studentCount": studentCount,
        "status": status == CourseStatus.active ? "active" : "pending",
        "categoryCount": categoryCount,
        "evaluationCount": evaluationCount,
        "teacherName": teacherName,
        "groupName": groupName,
        "pendingEvaluations": pendingEvaluations,
        "enrollmentCode": enrollmentCode,
      };

  Map<String, dynamic> toJsonNoId() => {
        "name": name,
        "semester": semester,
        "studentCount": studentCount,
        "status": status == CourseStatus.active ? "active" : "pending",
        "categoryCount": categoryCount,
        "evaluationCount": evaluationCount,
        "teacherName": teacherName,
        "groupName": groupName,
        "pendingEvaluations": pendingEvaluations,
        "enrollmentCode": enrollmentCode,
      };

  @override
  String toString() {
    return '[Course]{id: $id, name: $name, semester: $semester}';
  }
}
