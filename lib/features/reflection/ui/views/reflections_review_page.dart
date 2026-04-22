import 'package:f_clean_template/core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/models/reflection.dart';
import '../viewmodels/reflection_controller.dart';

/// Teacher-facing list of every reflection submitted for an assessment or
/// course. Reached from the teacher analytics screen via the "Ver
/// reflexiones" entry point.
///
/// Scope is controlled by the constructor:
///   * [assessmentId] set → loads only reflections for that activity.
///   * [courseId] set (and [assessmentId] null) → loads every reflection in
///     any assessment of that course.
class ReflectionsReviewPage extends StatefulWidget {
  const ReflectionsReviewPage({
    super.key,
    this.assessmentId,
    this.courseId,
    this.title,
  }) : assert(assessmentId != null || courseId != null,
            'Must scope by assessmentId or courseId');

  final String? assessmentId;
  final String? courseId;

  /// Optional header override — e.g. "Reflexiones – Sprint 2".
  final String? title;

  @override
  State<ReflectionsReviewPage> createState() => _ReflectionsReviewPageState();
}

class _ReflectionsReviewPageState extends State<ReflectionsReviewPage> {
  ReflectionController get controller => Get.find<ReflectionController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await controller.loadPrompts();
      await _load();
    });
  }

  Future<void> _load() {
    if (widget.assessmentId != null) {
      return controller.loadReflectionsByAssessment(widget.assessmentId!);
    }
    return controller.loadReflectionsByCourse(widget.courseId!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
            onRefresh: _load,
            child: Obx(() {
              final loading = controller.isLoadingReviewList.value;
              final items = controller.reviewList;

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(items.length),
                          const SizedBox(height: 16),
                          if (loading && items.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 60),
                              child:
                                  Center(child: CircularProgressIndicator()),
                            )
                          else if (items.isEmpty)
                            _buildEmpty()
                          else
                            ...items.map((r) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildReflectionCard(r),
                                )),
                          const SizedBox(height: 28),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  // ─── sub-widgets ───────────────────────────────────────────────────────

  Widget _buildHeader(int count) {
    final fallbackTitle = widget.assessmentId != null
        ? 'Reflexiones del ejercicio'
        : 'Reflexiones del curso';
    return Row(
      children: [
        IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textDark),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          tooltip: 'Volver',
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title ?? fallbackTitle,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$count reflexión(es) enviada(s)',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        children: [
          Icon(Icons.forum_outlined,
              size: 48, color: AppColors.textMuted),
          SizedBox(height: 10),
          Text(
            'Aún no hay reflexiones',
            style: TextStyle(fontSize: 16, color: AppColors.textMuted),
          ),
          SizedBox(height: 6),
          Text(
            'Las reflexiones de los estudiantes aparecerán aquí una vez las envíen.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildReflectionCard(Reflection r) {
    final answeredPrompts =
        r.answers.entries.where((e) => e.value.trim().isNotEmpty).toList();

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
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.olive.withValues(alpha: 0.2),
                child: Text(
                  _initials(r.studentName ?? r.studentId),
                  style: const TextStyle(
                    color: AppColors.olive,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.studentName ?? r.studentId,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    if (widget.assessmentId == null &&
                        r.assessmentTitle != null)
                      Text(
                        r.assessmentTitle!,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted),
                      ),
                  ],
                ),
              ),
              if (r.submittedAt != null)
                Text(
                  _formatDate(r.submittedAt!),
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (answeredPrompts.isEmpty)
            const Text(
              'Este estudiante envió una reflexión vacía.',
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  fontStyle: FontStyle.italic),
            )
          else
            ...answeredPrompts.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.questionFor(e.key),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.olive,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        e.value,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textDark,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  // ─── helpers ───────────────────────────────────────────────────────────

  String _initials(String name) {
    final parts =
        name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  String _formatDate(DateTime d) {
    final local = d.toLocal();
    String pad(int v) => v.toString().padLeft(2, '0');
    return '${local.year}-${pad(local.month)}-${pad(local.day)}';
  }
}
