import 'package:f_clean_template/core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../analytics/ui/views/teacher_analytics_page.dart';
import '../../../auth/ui/viewmodels/auth_controller.dart';
import '../../../course/domain/models/course.dart';
import '../../../course/ui/viewmodels/course_controller.dart';
import '../../../course/ui/views/course_detail_page.dart';
import '../../../course/ui/views/course_list_page.dart';
import '../../../course/ui/views/create_course_page.dart';
import '../../../profile/ui/views/profile_page.dart';

class TeacherHomePage extends StatefulWidget {
  const TeacherHomePage({super.key});

  @override
  State<TeacherHomePage> createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _TeacherDashboard(),
          CourseListPage(),
          TeacherAnalyticsPage(),
          ProfilePage(),
        ],
      ),
      floatingActionButton: (_currentIndex == 0 || _currentIndex == 1)
          ? FloatingActionButton(
              heroTag: 'teacher_home_fab',
              onPressed: () async {
                await Get.to(() => const CreateCoursePage());
                Get.find<CourseController>().refreshCourses();
              },
              backgroundColor: AppColors.olive,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.olive,
        unselectedItemColor: AppColors.textMuted,
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded), label: 'Inicio'),
          BottomNavigationBarItem(
              icon: Icon(Icons.book_rounded), label: 'Cursos'),
          BottomNavigationBarItem(
              icon: Icon(Icons.analytics_rounded), label: 'Analíticas'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded), label: 'Perfil'),
        ],
      ),
    );
  }
}

class _TeacherDashboard extends StatefulWidget {
  const _TeacherDashboard();

  @override
  State<_TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<_TeacherDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authController = Get.find<AuthController>();
      final courseController = Get.find<CourseController>();
      courseController.getCoursesByTeacher(authController.currentUser!.id!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final courseController = Get.find<CourseController>();
    final user = authController.currentUser!;

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
        child: Obx(() {
          if (courseController.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(user.name, user.initials),
                      const SizedBox(height: 20),
                      _buildStatsRow(courseController.courses),
                      const SizedBox(height: 24),
                      const Text(
                        'MIS CURSOS',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: courseController.courses.isEmpty
                    ? SliverToBoxAdapter(
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.book_outlined,
                                  size: 48,
                                  color: AppColors.textMuted
                                      .withValues(alpha: 0.5)),
                              const SizedBox(height: 12),
                              const Text(
                                'Crea tu primer curso con el botón +',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildCourseCard(
                                courseController.courses[index]),
                          ),
                          childCount: courseController.courses.length,
                        ),
                      ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildHeader(String name, String initials) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Buenos días',
              style: TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.olive,
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(List<Course> courses) {
    final activeCourses =
        courses.where((c) => c.status == CourseStatus.active).length;
    final totalEvaluations =
        courses.fold<int>(0, (sum, c) => sum + c.evaluationCount);
    final totalStudents =
        courses.fold<int>(0, (sum, c) => sum + c.studentCount);

    return Row(
      children: [
        Expanded(
            child: _buildStatCard(
                activeCourses.toString(), 'Cursos activos', AppColors.olive)),
        const SizedBox(width: 10),
        Expanded(
            child: _buildStatCard(totalEvaluations.toString(), 'Evaluaciones',
                AppColors.salmon)),
        const SizedBox(width: 10),
        Expanded(
            child: _buildStatCard(
                totalStudents.toString(), 'Estudiantes', AppColors.rose)),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildCourseCard(Course course) {
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
              color: statusColor.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border:
                Border(left: BorderSide(color: statusColor, width: 4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(course.name,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(statusText,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: statusColor)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${course.semester} | ${course.studentCount} estudiantes',
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildCourseTag(
                      '${course.categoryCount} categorías', AppColors.salmon),
                  const SizedBox(width: 8),
                  _buildCourseTag('${course.evaluationCount} evaluaciones',
                      AppColors.wheat),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w500, color: color)),
    );
  }
}

