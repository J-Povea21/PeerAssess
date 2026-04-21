import '../../../auth/ui/viewmodels/auth_controller.dart';
import 'package:f_clean_template/core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../assessment/ui/views/assessment_list_page.dart';
import '../../../group/ui/views/category_list_page.dart';
import '../../domain/models/course.dart';
import '../viewmodels/course_controller.dart';
import 'members_page.dart';

class CourseDetailPage extends StatelessWidget {
  final Course course;

  const CourseDetailPage({super.key, required this.course});

  Course _liveCourse(CourseController ctrl) {
    return ctrl.courses.firstWhereOrNull((c) => c.id == course.id) ?? course;
  }

  @override
  Widget build(BuildContext context) {
    final courseCtrl = Get.find<CourseController>();
    final authController = Get.find<AuthController>();
    final isTeacher = authController.currentUser?.role.name == 'teacher';

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Obx(() => Text(_liveCourse(courseCtrl).name)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.textDark,
          bottom: const TabBar(
            labelColor: AppColors.olive,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.olive,
            tabs: [
              Tab(text: 'Info'),
              Tab(text: 'Categorías'),
              Tab(text: 'Evaluaciones'),
              Tab(text: 'Miembros'),
            ],
          ),
        ),
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
          child: TabBarView(
            children: [
              _buildInfoTab(context, courseCtrl, isTeacher),
              _buildCategoriesTab(),
              _buildAssessmentsTab(),
              _buildMembersTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTab(
      BuildContext context, CourseController courseCtrl, bool isTeacher) {
    return Obx(() {
      final c = _liveCourse(courseCtrl);
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(c),
            const SizedBox(height: 20),
            _buildEnrollmentCard(context, c, isTeacher),
            const SizedBox(height: 20),
            _buildStatsCards(c),
          ],
        ),
      );
    });
  }

  Widget _buildInfoCard(Course c) {
    final isActive = c.status == CourseStatus.active;
    final statusColor = isActive ? AppColors.olive : AppColors.salmon;
    final statusText = isActive ? 'Activo' : 'Pendiente';

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.beige,
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.book_rounded, color: AppColors.olive, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  'Semestre ${c.semester}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
        ],
      ),
    );
  }

  Widget _buildEnrollmentCard(
      BuildContext context, Course c, bool isTeacher) {
    if (!isTeacher) return const SizedBox.shrink();
    if (c.enrollmentCode == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
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
            'Código de inscripción',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.beige.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  c.enrollmentCode!,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.olive,
                    letterSpacing: 4,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Builder(builder: (ctx) {
                return IconButton(
                  onPressed: () {
                    Clipboard.setData(
                        ClipboardData(text: c.enrollmentCode!));
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text('Código copiado al portapapeles'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon:
                      const Icon(Icons.copy_rounded, color: AppColors.olive),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(Course c) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            c.studentCount.toString(),
            'Estudiantes',
            Icons.people_rounded,
            AppColors.olive,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            c.categoryCount.toString(),
            'Categorías',
            Icons.category_rounded,
            AppColors.salmon,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            c.evaluationCount.toString(),
            'Evaluaciones',
            Icons.assessment_rounded,
            AppColors.rose,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab() {
    return CategoryListPage(courseId: course.id!);
  }

  Widget _buildAssessmentsTab() {
    return AssessmentListPage(courseId: course.id!);
  }

  Widget _buildMembersTab() {
    return MembersPage(courseId: course.id!);
  }
}