/// A single reflection question shown to the student after completing a
/// peer-assessment activity.
///
/// Prompts are currently fixed by the product team (we ship the same four
/// questions to every student across every course), so they live as a
/// constant list inside the data source rather than a Roble table. Exposing
/// them as a model still gives us the flexibility to later move them to the
/// backend without touching callers.
class ReflectionPrompt {
  const ReflectionPrompt({
    required this.id,
    required this.question,
    this.hint,
  });

  /// Stable identifier used as the map key in [Reflection.answers]. We never
  /// renumber these — changing an id breaks historical reflections.
  final String id;

  /// The question shown to the student (Spanish, ready-to-display).
  final String question;

  /// Optional helper text (e.g. example phrasing).
  final String? hint;

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        if (hint != null) 'hint': hint,
      };

  factory ReflectionPrompt.fromJson(Map<String, dynamic> json) =>
      ReflectionPrompt(
        id: json['id'].toString(),
        question: json['question'].toString(),
        hint: json['hint']?.toString(),
      );
}
