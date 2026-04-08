import 'package:f_clean_template/core/app_colors.dart';
import 'package:f_clean_template/core/models/user.dart';
import 'package:f_clean_template/core/network/roble_db_client.dart';
import 'package:f_clean_template/core/services/session_service.dart';
import 'package:f_clean_template/features/auth/ui/viewmodels/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../group/domain/models/group_member.dart';
import '../../../group/ui/viewmodels/group_controller.dart';
import '../../domain/models/assessment.dart';
import '../../domain/models/criteria.dart';
import '../viewmodels/assessment_controller.dart';
import '../viewmodels/evaluation_controller.dart';
import 'create_assessment_page.dart';
import 'evaluation_form_page.dart';

class AssessmentListPage extends StatefulWidget {
  final String courseId;
  final String? categoryId;

  const AssessmentListPage({
    super.key,
    required this.courseId,
    this.categoryId,
  });

  @override
  State<AssessmentListPage> createState() => _AssessmentListPageState();
}

class _AssessmentListPageState extends State<AssessmentListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<AssessmentController>().loadAssessments(widget.courseId);
      // For students, also load pending assessments to know which ones
      // still need evaluation.
      final auth = Get.find<AuthController>();
      if (auth.currentRole == UserRole.student) {
        final studentId = auth.currentUser?.id ?? '';
        Get.find<EvaluationController>().loadPendingAssessments(studentId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AssessmentController>();
    final authController = Get.find<AuthController>();
    final isTeacher = authController.currentRole == UserRole.teacher;

    final evalController = isTeacher ? null : Get.find<EvaluationController>();

    return Stack(
      children: [
        Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final filtered = widget.categoryId != null
              ? controller.assessments
                  .where((a) => a.categoryId == widget.categoryId)
                  .toList()
              : controller.assessments.toList();

          // For students, build the set of pending assessment IDs
          final pendingIds = isTeacher
              ? <String>{}
              : evalController!.pendingAssessments
                  .map((a) => a.id ?? '')
                  .toSet();

          if (filtered.isEmpty) {
            return const Center(
              child: Text(
                'No hay evaluaciones',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textMuted,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) => _buildAssessmentCard(
                filtered[index], isTeacher, controller, pendingIds),
          );
        }),
        if (isTeacher)
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              heroTag: 'assessment_fab',
              onPressed: () async {
                await Get.to(
                    () => CreateAssessmentPage(courseId: widget.courseId));
                controller.loadAssessments(widget.courseId);
              },
              backgroundColor: AppColors.olive,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
      ],
    );
  }

  String _resolveCategoryName(String categoryId) {
    final groupController = Get.find<GroupController>();
    for (final cat in groupController.categories) {
      if (cat.id == categoryId) return cat.name;
    }
    return '';
  }

  Widget _buildAssessmentCard(Assessment assessment, bool isTeacher,
      AssessmentController controller, Set<String> pendingIds) {
    final isExpired = assessment.deadline != null &&
        assessment.deadline!.isBefore(DateTime.now());
    final isOpen = !isExpired;
    final isPending = pendingIds.contains(assessment.id);

    final statusText = isExpired ? 'Cerrada' : 'Activa';
    final statusColor = isExpired ? AppColors.textMuted : AppColors.olive;
    final visibilityText =
        assessment.visibility == 'public' ? 'Pública' : 'Privada';
    final categoryName = _resolveCategoryName(assessment.categoryId);

    return GestureDetector(
      onTap: isPending ? () => _startEvaluation(assessment) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
                Expanded(
                  child: Text(
                    assessment.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: statusColor,
                    ),
                  ),
                ),
                if (isTeacher && isOpen) ...[
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 20,
                      icon: const Icon(Icons.cancel_outlined,
                          color: AppColors.salmon),
                      tooltip: 'Cancelar evaluación',
                      onPressed: () =>
                          _confirmCancel(context, assessment, controller),
                    ),
                  ),
                ],
              ],
            ),
            if (categoryName.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.beige,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  categoryName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.visibility,
                    size: 16, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(
                  visibilityText,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.timer, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(
                  '${assessment.timeWindowMinutes} min',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            if (assessment.deadline != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.event, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    'Cierre: ${_formatDeadline(assessment.deadline!)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
            if (!isTeacher && isOpen) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    isPending ? 'Evaluar' : 'Evaluado',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isPending ? AppColors.olive : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isPending ? Icons.arrow_forward_ios : Icons.check_circle,
                    size: 14,
                    color: isPending ? AppColors.olive : AppColors.textMuted,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, Assessment assessment,
      AssessmentController controller) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar evaluación'),
        content: Text(
            '¿Estás seguro de que deseas cancelar "${assessment.title}"? '
            'Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child:
                const Text('Sí, cancelar', style: TextStyle(color: AppColors.salmon)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final success = await controller.cancelAssessment(assessment.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Evaluación cancelada'
                : 'No se pudo cancelar la evaluación'),
          ),
        );
      }
      controller.loadAssessments(widget.courseId);
    }
  }

  Future<void> _startEvaluation(Assessment assessment) async {
    // Load criteria and peers from Roble for this assessment
    final robleDb = Get.find<RobleDbClient>();
    final session = Get.find<SessionService>();
    final email = session.cachedUser?.email ?? '';

    // Resolve the student's ID by email — the auth system and CSV import
    // may use different IDs, but the email is the stable identifier.
    final userRows = await robleDb.read('Users', {'mail': email});
    if (userRows.isEmpty) return;
    final studentId = userRows.first['_id']?.toString() ?? '';

    // 1. Fetch criteria for this assessment
    final criteriaRows =
        await robleDb.read('Criteria', {'assessmentID': assessment.id!});
    final criteria = criteriaRows
        .map((r) => Criteria(
              id: r['_id']?.toString(),
              name: r['name']?.toString() ?? '',
              weight: (r['weight'] is num)
                  ? (r['weight'] as num).toDouble()
                  : double.tryParse(r['weight']?.toString() ?? '') ?? 1.0,
              assessmentId: assessment.id,
            ))
        .toList();

    if (criteria.isEmpty) return;

    // 2. Find the student's group for this assessment's category
    final memberRows =
        await robleDb.read('GroupMembers', {'studentID': studentId});
    String? groupId;
    for (final row in memberRows) {
      final gId = row['groupID'].toString();
      final groupRows = await robleDb.read('Groups', {'_id': gId});
      if (groupRows.isNotEmpty &&
          groupRows.first['categoryID'].toString() == assessment.categoryId) {
        groupId = gId;
        break;
      }
    }
    if (groupId == null) return;

    // 3. Fetch peers (all group members except the current student)
    final allMemberRows =
        await robleDb.read('GroupMembers', {'groupID': groupId});
    final usersCache = <String, Map<String, dynamic>>{};
    final allUsers = await robleDb.read('Users');
    for (final u in allUsers) {
      if (u['_id'] != null) usersCache[u['_id'].toString()] = u;
    }

    final peers = <GroupMember>[];
    for (final r in allMemberRows) {
      final sid = r['studentID']?.toString() ?? '';
      if (sid == studentId) continue; // skip self
      final user = usersCache[sid];
      if (user != null) {
        final name = user['name']?.toString() ?? '';
        final parts = name.split(' ');
        peers.add(GroupMember(
          id: sid,
          firstName: parts.isNotEmpty ? parts.first : '',
          lastName: parts.length > 1 ? parts.sublist(1).join(' ') : '',
          email: user['mail']?.toString() ?? '',
        ));
      }
    }

    if (peers.isEmpty) return;

    await Get.to(() => EvaluationFormPage(
          assessment: assessment,
          peers: peers,
          criteria: criteria,
          evaluatorId: studentId,
        ));

    // Reload pending list so "Evaluar"/"Evaluado" updates after returning
    Get.find<EvaluationController>().loadPendingAssessments(studentId);
  }

  String _formatDeadline(DateTime deadline) {
    final local = deadline.toLocal();
    return '${local.day}/${local.month}/${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}
