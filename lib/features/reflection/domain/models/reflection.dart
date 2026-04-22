/// A student's reflection submission for one assessment. One reflection per
/// (studentId, assessmentId) pair — re-submitting overwrites the existing
/// record rather than creating a new row.
///
/// The [answers] map is keyed by [ReflectionPrompt.id] so the UI can render
/// any future set of questions without schema migrations — the Reflections
/// table stores the whole map as a single JSON blob.
class Reflection {
  Reflection({
    this.id,
    required this.studentId,
    required this.assessmentId,
    required this.answers,
    this.submittedAt,
    this.studentName,
    this.assessmentTitle,
  });

  /// Roble `_id`. Null before the first insert.
  final String? id;

  final String studentId;
  final String assessmentId;

  /// promptId → free-text answer. Empty strings are allowed (the UI treats
  /// missing prompts the same as empty answers).
  final Map<String, String> answers;

  /// When the student last submitted. Null for drafts that never hit the
  /// backend.
  final DateTime? submittedAt;

  // ─── Display-only fields (not persisted, filled in by the data source) ──

  /// Resolved from Users.name when the teacher loads reflections — shown on
  /// the reflections review screen.
  final String? studentName;

  /// Resolved from Assessments.title for the same display purposes.
  final String? assessmentTitle;

  /// Convenience: returns the answer for [promptId], defaulting to an empty
  /// string so the UI can bind `TextEditingController.text` unconditionally.
  String answerFor(String promptId) => answers[promptId] ?? '';

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        'studentID': studentId,
        'assessmentID': assessmentId,
        // Answers are stored as a JSON string so the Reflections table has
        // a fixed schema regardless of how many prompts exist.
        'answers': answers,
        if (submittedAt != null) 'submittedAt': submittedAt!.toIso8601String(),
      };

  factory Reflection.fromJson(Map<String, dynamic> json) {
    final rawAnswers = json['answers'];
    final parsed = <String, String>{};
    if (rawAnswers is Map) {
      rawAnswers.forEach((k, v) {
        parsed[k.toString()] = v?.toString() ?? '';
      });
    }

    DateTime? submitted;
    final ts = json['submittedAt'];
    if (ts is String) {
      submitted = DateTime.tryParse(ts);
    }

    return Reflection(
      id: json['_id']?.toString(),
      studentId: json['studentID'].toString(),
      assessmentId: json['assessmentID'].toString(),
      answers: parsed,
      submittedAt: submitted,
      studentName: json['studentName']?.toString(),
      assessmentTitle: json['assessmentTitle']?.toString(),
    );
  }

  Reflection copyWith({
    String? id,
    Map<String, String>? answers,
    DateTime? submittedAt,
    String? studentName,
    String? assessmentTitle,
  }) =>
      Reflection(
        id: id ?? this.id,
        studentId: studentId,
        assessmentId: assessmentId,
        answers: answers ?? this.answers,
        submittedAt: submittedAt ?? this.submittedAt,
        studentName: studentName ?? this.studentName,
        assessmentTitle: assessmentTitle ?? this.assessmentTitle,
      );
}
