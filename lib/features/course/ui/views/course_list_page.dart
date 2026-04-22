import 'package:f_clean_template/core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../auth/ui/viewmodels/auth_controller.dart';
import '../../domain/models/course.dart';
import '../viewmodels/course_controller.dart';
import 'course_detail_page.dart';
import 'create_course_page.dart';

class CourseListPage extends StatelessWidget {
  const CourseListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final courseController = Get.find<CourseController>();
    final isTeacher =
        authController.currentUser?.role.name == 'teacher';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Cursos'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        automaticallyImplyLeading: false,
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
        child: Obx(() {
          if (courseController.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (courseController.courses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book_outlined,
                      size: 64,
                      color:
                          AppColors.textMuted.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(
                    isTeacher
                        ? 'No tienes cursos creados'
                        : 'No estás inscrito en ningún curso',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: courseController.courses.length,
            itemBuilder: (context, index) {
              final course = courseController.courses[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildCourseCard(course, isTeacher),
              );
            },
          );
        }),
      ),
      floatingActionButton: isTeacher
          ? FloatingActionButton(
              heroTag: 'course_list_fab',
              onPressed: () async {
                await Get.to(() => const CreateCoursePage());
                courseController.refreshCourses();
              },
              backgroundColor: AppColors.olive,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildCourseCard(Course course, bool isTeacher) {
    final isActive = course.status == CourseStatus.active;
    final statusColor = isActive ? AppColors.olive : AppColors.salmon;
    final statusText = isActive ? 'Activo' : 'Pendiente';

    return GestureDetector(
      onTap: () => Get.to(() => CourseDetailPage(course: course)),
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: statusColor, width: 4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      course.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          statusColor.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(8),
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

              const SizedBox(height: 6),

             
              Text(
                '${course.semester} | ${course.studentCount} estudiantes | ${course.categoryCount} categorías | ${course.evaluationCount} evaluaciones',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),

              const SizedBox(height: 10),
if (!isTeacher && course.evaluationCount > 0)
  Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.orange.withOpacity(0.12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        const Icon(Icons.warning_amber_rounded,
            size: 16, color: Colors.orange),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Tienes ${course.evaluationCount} evaluaciones pendientes',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  ),
              Row(
                children: [
                  _buildTag(
                    '${course.categoryCount} categorías',
                    AppColors.salmon,
                  ),
                  const SizedBox(width: 8),
                  _buildTag(
                    '${course.evaluationCount} evaluaciones',
                    AppColors.wheat,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
} 