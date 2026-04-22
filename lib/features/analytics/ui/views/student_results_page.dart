import 'package:f_clean_template/core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../auth/ui/viewmodels/auth_controller.dart';
import '../../../reflection/domain/models/reflection_prompt.dart';
import '../../../reflection/ui/viewmodels/reflection_controller.dart';
import '../../domain/models/member_result.dart';
import '../viewmodels/analytics_controller.dart';

/// Student "Reflexión Post-Evaluación" screen. Shows the student's own
/// average for a selected assessment plus an auto-feedback paragraph and
/// editable reflection fields that persist to the backend.
///
/// The view drives two controllers:
///   * [AnalyticsController] — assessment list + [MemberResult] for the
///     selected assessment (score, per-criterion breakdown).
///   * [ReflectionController] — prompt catalogue + the student's current
///     answers + submit.
///
/// Why both? Analytics is read-only derived data; reflections have ownership.
/// Keeping them separate matches the Single Responsibility Principle — each
/// controller has one reason to change.
class StudentResultsPage extends StatefulWidget {
  const StudentResultsPage({super.key});

  @override
  State<StudentResultsPage> createState() => _StudentResultsPageState();
}

class _StudentResultsPageState extends State<StudentResultsPage> {
  AnalyticsController get analytics => Get.find<AnalyticsController>();
  ReflectionController get reflection => Get.find<ReflectionController>();

  /// One text controller per prompt id. Built lazily when prompts load so the
  /// number of fields always matches the catalogue.
  final Map<String, TextEditingController> _fieldControllers = {};

  /// Last assessment we prefilled fields for. Guards against redundant
  /// refill loops from the reactive rebuild.
  String? _lastPrefilledAssessmentId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final sid = Get.find<AuthController>().currentUser?.id;
      if (sid == null) return;
      await reflection.loadPrompts();
      _ensureFieldControllers();
      if (analytics.myAssessments.isEmpty) {
        await analytics.loadMyAssessments(sid);
      }
      final aid = analytics.selectedMyAssessmentId.value;
      if (aid != null) {
        await reflection.loadMyReflection(sid, aid);
        _prefillFrom(aid);
      }
    });
  }

  @override
  void dispose() {
    for (final c in _fieldControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ─── build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.beige,
            Colors.white,
            AppColors.rose.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: Obx(() {
            if (analytics.isLoadingMyAssessments.value &&
                analytics.myAssessments.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (analytics.myAssessments.isEmpty) {
              return _emptyScroll();
            }

            // Keep text fields in sync when the selected assessment changes.
            _ensureFieldControllers();
            final currentId = analytics.selectedMyAssessmentId.value;
            if (currentId != null &&
                currentId != _lastPrefilledAssessmentId &&
                !reflection.isLoadingMyReflection.value) {
              _prefillFrom(currentId);
            }

            final result = analytics.myResult.value;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 16),
                        _buildAssessmentDropdown(),
                        const SizedBox(height: 24),
                        if (analytics.isLoadingMyResult.value)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 30),
                            child:
                                Center(child: CircularProgressIndicator()),
                          )
                        else ...[
                          Center(child: _buildScoreBadge(result)),
                          const SizedBox(height: 12),
                          Center(
                            child: Text(
                              _selectedAssessmentTitle(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Center(
                            child: Text(
                              result == null || result.hasNoResults
                                  ? 'Aún no has recibido evaluaciones'
                                  : '${result.evaluationCount} compañero(s) te evaluaron',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (result != null && !result.hasNoResults) ...[
                            _buildAutoFeedbackCard(result),
                            const SizedBox(height: 16),
                            _buildCriteriaBreakdown(result),
                            const SizedBox(height: 24),
                          ],
                          _sectionTitle('TU AUTO-REFLEXIÓN (VOLUNTARIA)'),
                          const SizedBox(height: 14),
                          _buildAlreadySubmittedBanner(),
                          _buildReflectionFields(),
                          const SizedBox(height: 20),
                          _buildSubmitButton(),
                          const SizedBox(height: 8),
                          _buildLastSubmittedLine(),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // ─── sub-widgets ───────────────────────────────────────────────────────

  Widget _emptyScroll() {
    return ListView(
      children: const [
        SizedBox(height: 100),
        Icon(Icons.inbox_rounded, size: 64, color: AppColors.textMuted),
        SizedBox(height: 16),
        Center(
          child: Text(
            'Sin resultados',
            style: TextStyle(fontSize: 18, color: AppColors.textMuted),
          ),
        ),
        SizedBox(height: 8),
        Center(
          child: Text(
            'Aún no has sido evaluado en ninguna actividad',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return const Row(
      children: [
        Icon(Icons.bar_chart_rounded, color: AppColors.textDark),
        SizedBox(width: 12),
        Text(
          'Reflexión Post-Evaluación',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildAssessmentDropdown() {
    return GestureDetector(
      onTap: _showAssessmentPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppColors.textMuted.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_note_rounded,
                color: AppColors.olive, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _selectedAssessmentTitle(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBadge(MemberResult? result) {
    final hasScore = result != null && !result.hasNoResults;
    final text = hasScore ? result.average.toStringAsFixed(1) : '—';
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.wheat.withValues(alpha: 0.5),
        border: Border.all(color: AppColors.olive, width: 3),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _buildAutoFeedbackCard(MemberResult result) {
    final segments = _buildFeedbackSegments(result);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.wheat.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.wheat),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.olive.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'RETROALIMENTACIÓN AUTOMÁTICA',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.olive,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textDark,
                height: 1.5,
              ),
              children: segments,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaBreakdown(MemberResult result) {
    final entries = result.criteriaScores.entries.toList();
    if (entries.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Desglose por criterio',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          ...entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        e.key,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (e.value / 5.0).clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: AppColors.beige,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.olive),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 28,
                      child: Text(
                        e.value.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildReflectionFields() {
    return Obx(() {
      final list = reflection.prompts;
      if (reflection.isLoadingPrompts.value && list.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (list.isEmpty) {
        return const Text(
          'No se pudieron cargar las preguntas de reflexión',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        );
      }
      final alreadySent = reflection.myReflection.value != null;
      return Column(
        children: [
          for (final p in list) ...[
            _buildReflectionField(p, readOnly: alreadySent),
            const SizedBox(height: 14),
          ],
        ],
      );
    });
  }

  Widget _buildReflectionField(ReflectionPrompt p, {bool readOnly = false}) {
    final controller = _fieldControllers.putIfAbsent(
        p.id, () => TextEditingController());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          p.question,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: 3,
          readOnly: readOnly,
          enabled: !readOnly,
          decoration: InputDecoration(
            hintText: p.hint ?? 'Escribe tu reflexión aquí...',
            hintStyle: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
            filled: true,
            fillColor: readOnly
                ? AppColors.beige.withValues(alpha: 0.4)
                : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: AppColors.textMuted.withValues(alpha: 0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: AppColors.textMuted.withValues(alpha: 0.2)),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: AppColors.textMuted.withValues(alpha: 0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: AppColors.olive, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Obx(() {
      final submitting = reflection.isSubmitting.value;
      final alreadySent = reflection.myReflection.value != null;
      final enabled = !submitting &&
          !alreadySent &&
          analytics.selectedMyAssessmentId.value != null;
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: enabled ? _submitReflection : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.olive,
            foregroundColor: Colors.white,
            disabledBackgroundColor:
                AppColors.olive.withValues(alpha: 0.35),
            disabledForegroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: submitting
              ? const SizedBox.shrink()
              : Icon(
                  alreadySent
                      ? Icons.check_circle_rounded
                      : Icons.send_rounded,
                  size: 18,
                ),
          label: submitting
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  alreadySent ? 'Reflexión ya enviada' : 'Enviar reflexión',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
        ),
      );
    });
  }

  /// Banner that appears above the fields once the student has already
  /// submitted a reflection for the selected assessment. Tells them the
  /// submission is locked and no further edits are accepted.
  Widget _buildAlreadySubmittedBanner() {
    return Obx(() {
      final r = reflection.myReflection.value;
      if (r == null) return const SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.olive.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppColors.olive.withValues(alpha: 0.35), width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.olive, size: 20),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Ya enviaste tu reflexión para esta evaluación. No se '
                'permiten cambios posteriores.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textDark,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildLastSubmittedLine() {
    return Obx(() {
      final r = reflection.myReflection.value;
      if (r?.submittedAt == null) {
        return const SizedBox.shrink();
      }
      final ts = r!.submittedAt!.toLocal();
      final formatted =
          '${ts.year}-${_pad(ts.month)}-${_pad(ts.day)} ${_pad(ts.hour)}:${_pad(ts.minute)}';
      return Center(
        child: Text(
          'Última actualización: $formatted',
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
      );
    });
  }

  // ─── helpers ───────────────────────────────────────────────────────────

  String _selectedAssessmentTitle() {
    final id = analytics.selectedMyAssessmentId.value;
    if (id == null) return 'Selecciona una evaluación';
    final a = analytics.myAssessments.firstWhereOrNull((x) => x.id == id);
    return a?.title ?? 'Selecciona una evaluación';
  }

  void _showAssessmentPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Selecciona una evaluación',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              ...analytics.myAssessments.map((a) => ListTile(
                    title: Text(a.title),
                    trailing: analytics.selectedMyAssessmentId.value == a.id
                        ? const Icon(Icons.check_rounded,
                            color: AppColors.olive)
                        : null,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      final sid =
                          Get.find<AuthController>().currentUser?.id;
                      if (a.id != null && sid != null) {
                        analytics.selectMyAssessment(sid, a.id!);
                        reflection.loadMyReflection(sid, a.id!).then((_) {
                          if (mounted) _prefillFrom(a.id!);
                        });
                      }
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  Future<void> _refresh() async {
    final sid = Get.find<AuthController>().currentUser?.id;
    if (sid == null) return;
    await analytics.loadMyAssessments(sid);
    final aid = analytics.selectedMyAssessmentId.value;
    if (aid != null) {
      await reflection.loadMyReflection(sid, aid);
      _prefillFrom(aid);
    }
  }

  void _ensureFieldControllers() {
    for (final p in reflection.prompts) {
      _fieldControllers.putIfAbsent(p.id, () => TextEditingController());
    }
  }

  /// Fills text controllers from the currently loaded reflection (if any).
  /// Clears fields when no stored reflection exists — this way the student
  /// doesn't see another assessment's answers bleed into a new one.
  void _prefillFrom(String assessmentId) {
    final stored = reflection.myReflection.value;
    for (final p in reflection.prompts) {
      final ctrl = _fieldControllers[p.id];
      if (ctrl == null) continue;
      final text =
          stored != null && stored.assessmentId == assessmentId
              ? stored.answerFor(p.id)
              : '';
      if (ctrl.text != text) ctrl.text = text;
    }
    _lastPrefilledAssessmentId = assessmentId;
  }

  Future<void> _submitReflection() async {
    FocusScope.of(context).unfocus();
    final sid = Get.find<AuthController>().currentUser?.id;
    final aid = analytics.selectedMyAssessmentId.value;
    if (sid == null || aid == null) return;

    final answers = <String, String>{
      for (final p in reflection.prompts)
        p.id: _fieldControllers[p.id]?.text.trim() ?? '',
    };

    final ok = await reflection.submitMyReflection(
      studentId: sid,
      assessmentId: aid,
      answers: answers,
    );

    if (!mounted) return;
    // Use ScaffoldMessenger instead of Get.snackbar — this page is nested
    // inside a parent navigator/tab, so Get.snackbar's overlay lookup fails
    // with "No Overlay widget found". ScaffoldMessenger attaches to the
    // nearest Scaffold and works regardless of routing depth.
    final messenger = ScaffoldMessenger.of(context);
    if (ok) {
      messenger.showSnackBar(SnackBar(
        content: const Text(
          'Tu reflexión fue guardada y estará disponible para tu profesor.',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.olive.withValues(alpha: 0.95),
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      messenger.showSnackBar(SnackBar(
        content: const Text(
          'No se pudo enviar la reflexión. Intenta de nuevo.',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.rose.withValues(alpha: 0.95),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  String _pad(int v) => v.toString().padLeft(2, '0');

  /// Builds the rich-text feedback paragraph from the student's top and
  /// bottom criteria. Purely local — no LLM or backend call.
  List<TextSpan> _buildFeedbackSegments(MemberResult result) {
    final scored = result.criteriaScores.entries
        .where((e) => e.value > 0.0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (scored.isEmpty) {
      return const [
        TextSpan(text: 'Aún no hay suficientes datos para dar feedback.'),
      ];
    }

    final best = scored.first;
    final worst = scored.last;
    final avg = result.average;
    final tone = avg >= 4.3
        ? 'un desempeño destacado'
        : avg >= 3.5
            ? 'un buen desempeño'
            : 'un desempeño por mejorar';

    if (best.key == worst.key) {
      return [
        const TextSpan(text: 'Demuestras '),
        TextSpan(
          text: tone,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        TextSpan(
            text:
                '. Tu criterio "${best.key}" sobresale con ${best.value.toStringAsFixed(1)}.'),
      ];
    }

    return [
      const TextSpan(text: 'Demuestras '),
      TextSpan(
        text: tone,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      const TextSpan(text: '. Tu fortaleza es '),
      TextSpan(
        text: best.key,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      TextSpan(text: ' (${best.value.toStringAsFixed(1)}). '),
      const TextSpan(text: 'Se recomienda reforzar '),
      TextSpan(
        text: worst.key.toLowerCase(),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      TextSpan(text: ' (${worst.value.toStringAsFixed(1)}).'),
    ];
  }
}
