import 'dart:convert';

import 'package:loggy/loggy.dart';

import '../../../../../core/network/roble_db_client.dart';
import '../../../domain/models/reflection.dart';
import '../../../domain/models/reflection_prompt.dart';
import '../i_reflection_source.dart';

/// Roble-backed reflection source.
///
/// Schema — a single `Reflections` table keyed by `(studentID, assessmentID)`:
///   _id (string, server-assigned)
///   studentID (string)
///   assessmentID (string)
///   answers (string — JSON-encoded `Map<String,String>`)
///   submittedAt (string — ISO-8601 UTC)
///
/// Answers are JSON-encoded into a single column so adding or removing prompt
/// questions never requires a schema migration. The Roble backend accepts
/// plain Dart Maps too, but we encode defensively because some Roble
/// deployments flatten nested JSON on read.
class RemoteReflectionSource with UiLoggy implements IReflectionSource {
  final RobleDbClient _db;

  RemoteReflectionSource(this._db);

  static const String _table = 'Reflections';

  /// Per-instance cache of userId → name, populated lazily so the teacher
  /// review screen doesn't re-download the Users table per reflection.
  Map<String, String>? _userNameCache;

  /// Per-instance cache of assessmentId → title, populated lazily.
  Map<String, String>? _assessmentTitleCache;

  /// Canonical prompt list. When/if the product wants these editable, move
  /// this list into a Roble table and query it here — the interface doesn't
  /// need to change.
  static const List<ReflectionPrompt> _prompts = [
    ReflectionPrompt(
      id: 'learned',
      question: '¿Qué aprendiste de esta evaluación?',
      hint: 'Escribe tu reflexión aquí...',
    ),
    ReflectionPrompt(
      id: 'improve',
      question: '¿Qué mejorarás para la próxima evaluación?',
      hint: 'Escribe tu reflexión aquí...',
    ),
    ReflectionPrompt(
      id: 'team',
      question: '¿Cómo contribuiste al trabajo del equipo?',
      hint: 'Ejemplos: liderazgo, apoyo, ideas, ejecución...',
    ),
    ReflectionPrompt(
      id: 'challenges',
      question: '¿Qué desafíos enfrentaste y cómo los resolviste?',
      hint: 'Escribe tu reflexión aquí...',
    ),
  ];

  @override
  Future<List<ReflectionPrompt>> getPrompts() async {
    loggy.info('RemoteReflectionSource: getPrompts → ${_prompts.length}');
    return List.unmodifiable(_prompts);
  }

  // ──────────────────────────────────────────────────────────────────────
  // Submit (upsert)
  // ──────────────────────────────────────────────────────────────────────

  @override
  Future<Reflection> submitReflection(Reflection reflection) async {
    loggy.info(
        'RemoteReflectionSource: submitReflection student=${reflection.studentId} assessment=${reflection.assessmentId}');

    // Look up any existing row so we upsert by (student, assessment).
    final existing = await _db.read(_table, {
      'studentID': reflection.studentId,
      'assessmentID': reflection.assessmentId,
    });

    final now = DateTime.now().toUtc();
    final payload = <String, dynamic>{
      'studentID': reflection.studentId,
      'assessmentID': reflection.assessmentId,
      'answers': jsonEncode(reflection.answers),
      'submittedAt': now.toIso8601String(),
    };

    if (existing.isEmpty) {
      // New submission.
      final result = await _db.insert(_table, [payload]);
      final inserted = (result['inserted'] as List?) ?? const [];
      final row = inserted.isNotEmpty
          ? Map<String, dynamic>.from(inserted.first as Map)
          : payload;
      return _hydrate(row, submittedAt: now);
    }

    // Overwrite the existing row. Students may lack UPDATE permission on
    // Reflections (the Roble role only grants INSERT/SELECT to the
    // "student" role), so we try the update but treat a 403 as a no-op:
    // the first submission is kept and we return that row unchanged. The
    // UI still shows "enviada" so the student gets confirmation.
    final existingId = existing.first['_id'].toString();
    try {
      await _db.update(_table, '_id', existingId, {
        'answers': payload['answers'],
        'submittedAt': payload['submittedAt'],
      });
      return _hydrate({
        '_id': existingId,
        ...existing.first,
        ...payload,
      }, submittedAt: now);
    } catch (e) {
      loggy.warning(
          'RemoteReflectionSource: update failed ($e) — returning the existing '
          'reflection. This usually means the signed-in role lacks UPDATE '
          'permission on Reflections; the original submission is preserved.');
      return _hydrate(Map<String, dynamic>.from(existing.first));
    }
  }

  // ──────────────────────────────────────────────────────────────────────
  // Student: my reflection for one assessment
  // ──────────────────────────────────────────────────────────────────────

  @override
  Future<Reflection?> getMyReflection(
      String studentId, String assessmentId) async {
    loggy.info(
        'RemoteReflectionSource: getMyReflection student=$studentId assessment=$assessmentId');
    final rows = await _db.read(_table, {
      'studentID': studentId,
      'assessmentID': assessmentId,
    });
    if (rows.isEmpty) return null;
    return _hydrate(rows.first);
  }

  // ──────────────────────────────────────────────────────────────────────
  // Teacher: all reflections for an assessment
  // ──────────────────────────────────────────────────────────────────────

  @override
  Future<List<Reflection>> getReflectionsByAssessment(
      String assessmentId) async {
    loggy.info(
        'RemoteReflectionSource: getReflectionsByAssessment assessment=$assessmentId');
    final rows = await _db.read(_table, {'assessmentID': assessmentId});
    if (rows.isEmpty) return const [];

    // Resolve display fields in one pass.
    final users = await _getUserNames();
    final titles = await _getAssessmentTitles();

    final results = rows
        .map((r) => _hydrate(
              r,
              studentName: users[r['studentID']?.toString() ?? ''],
              assessmentTitle:
                  titles[r['assessmentID']?.toString() ?? ''],
            ))
        .toList();

    // Most recent first so teachers see fresh reflections at the top.
    results.sort((a, b) {
      final at = a.submittedAt;
      final bt = b.submittedAt;
      if (at == null && bt == null) return 0;
      if (at == null) return 1;
      if (bt == null) return -1;
      return bt.compareTo(at);
    });

    return results;
  }

  // ──────────────────────────────────────────────────────────────────────
  // Teacher: all reflections across every assessment in a course
  // ──────────────────────────────────────────────────────────────────────

  @override
  Future<List<Reflection>> getReflectionsByCourse(String courseId) async {
    loggy.info(
        'RemoteReflectionSource: getReflectionsByCourse course=$courseId');

    // 1. Categories in the course → assessments in those categories.
    final cats =
        await _db.read('GroupCategories', {'courseID': courseId});
    final catIds = cats.map((r) => r['_id'].toString()).toSet();
    if (catIds.isEmpty) return const [];

    final assessmentIds = <String>{};
    for (final cid in catIds) {
      final arows = await _db.read('Assessments', {'categoryID': cid});
      for (final a in arows) {
        assessmentIds.add(a['_id'].toString());
      }
    }
    if (assessmentIds.isEmpty) return const [];

    // 2. Read all reflections in the table, then filter to this course's
    //    assessments. A single bulk read is cheaper than one-read-per-
    //    assessment when the reflections table is small.
    final all = await _db.read(_table);
    final matching = all
        .where((r) =>
            assessmentIds.contains(r['assessmentID']?.toString() ?? ''))
        .toList();
    if (matching.isEmpty) return const [];

    final users = await _getUserNames();
    final titles = await _getAssessmentTitles();

    final results = matching
        .map((r) => _hydrate(
              r,
              studentName: users[r['studentID']?.toString() ?? ''],
              assessmentTitle:
                  titles[r['assessmentID']?.toString() ?? ''],
            ))
        .toList();

    results.sort((a, b) {
      final at = a.submittedAt;
      final bt = b.submittedAt;
      if (at == null && bt == null) return 0;
      if (at == null) return 1;
      if (bt == null) return -1;
      return bt.compareTo(at);
    });

    return results;
  }

  // ──────────────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────────────

  Future<Map<String, String>> _getUserNames() async {
    if (_userNameCache != null) return _userNameCache!;
    final rows = await _db.read('Users');
    _userNameCache = {
      for (final u in rows)
        if (u['_id'] != null)
          u['_id'].toString(): (u['name']?.toString().trim().isEmpty ?? true)
              ? 'Estudiante ${u['_id']}'
              : u['name'].toString().trim(),
    };
    return _userNameCache!;
  }

  Future<Map<String, String>> _getAssessmentTitles() async {
    if (_assessmentTitleCache != null) return _assessmentTitleCache!;
    final rows = await _db.read('Assessments');
    _assessmentTitleCache = {
      for (final a in rows)
        if (a['_id'] != null)
          a['_id'].toString(): a['title']?.toString() ?? '—',
    };
    return _assessmentTitleCache!;
  }

  /// Normalizes a raw Roble row into a [Reflection]. Handles both the case
  /// where answers are returned as a JSON string and where Roble decodes
  /// them back into a nested map.
  Reflection _hydrate(
    Map<String, dynamic> row, {
    String? studentName,
    String? assessmentTitle,
    DateTime? submittedAt,
  }) {
    final rawAnswers = row['answers'];
    final answers = <String, String>{};
    if (rawAnswers is String) {
      try {
        final decoded = jsonDecode(rawAnswers);
        if (decoded is Map) {
          decoded.forEach((k, v) {
            answers[k.toString()] = v?.toString() ?? '';
          });
        }
      } catch (_) {
        loggy.warning(
            'RemoteReflectionSource: failed to decode answers JSON for row ${row['_id']}');
      }
    } else if (rawAnswers is Map) {
      rawAnswers.forEach((k, v) {
        answers[k.toString()] = v?.toString() ?? '';
      });
    }

    DateTime? ts = submittedAt;
    if (ts == null) {
      final raw = row['submittedAt'];
      if (raw is String) ts = DateTime.tryParse(raw);
    }

    return Reflection(
      id: row['_id']?.toString(),
      studentId: row['studentID']?.toString() ?? '',
      assessmentId: row['assessmentID']?.toString() ?? '',
      answers: answers,
      submittedAt: ts,
      studentName: studentName,
      assessmentTitle: assessmentTitle,
    );
  }
}
