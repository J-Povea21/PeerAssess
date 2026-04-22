import 'package:f_clean_template/core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../analytics/ui/views/student_results_page.dart';
import '../../../auth/ui/viewmodels/auth_controller.dart';
import '../../../course/domain/models/course.dart';
import '../../../course/ui/viewmodels/course_controller.dart';
import '../../../course/ui/views/course_detail_page.dart';
import '../../../course/ui/views/course_list_page.dart';
import '../../../enrollment/ui/views/join_course_page.dart';
import '../../../profile/ui/views/profile_page.dart';

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({super.key});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _StudentDashboard(),
          CourseListPage(),
          StudentResultsPage(),
          ProfilePage(),
        ],
      ),
      floatingActionButton: (_currentIndex == 0 || _currentIndex == 1)
          ? FloatingActionButton(
              heroTag: 'student_home_fab',
              onPressed: () => Get.to(() => const JoinCoursePage()),
              backgroundColor: AppColors.olive,
              child: const Icon(Icons.group_add_rounded, color: Colors.white),
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
              icon: Icon(Icons.bar_chart_rounded), label: 'Resultados'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded), label: 'Perfil'),
        ],
      ),
    );
  }
}

class _StudentDashboard extends StatefulWidget {
  const _StudentDashboard();

  @override
  State<_StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<_StudentDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authController = Get.find<AuthController>();
      final courseController = Get.find<CourseController>();
      courseController.getCoursesByStudent(authController.currentUser!.id!);
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

          final pendingCourse = courseController.courses
              .cast<Course?>()
              .firstWhere((c) => c!.pendingEvaluations > 0,
                  orElse: () => null);

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
                      if (pendingCourse != null) _buildPendingBanner(pendingCourse),
                      if (pendingCourse != null) const SizedBox(height: 20),
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
                                'No estás inscrito en ningún curso',
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
                            child: _buildStudentCourseCard(
                                courseController.courses[index]),
                          ),
                          childCount: courseController.courses.length,
                        ),
                      ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'RESULTADOS RECIENTES',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildNoResultsCard(),
                    ],
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
            Text('Hola',
                style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
            const SizedBox(height: 4),
            Text(name,
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
          ],
        ),
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.olive,
          child: Text(initials,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16)),
        ),
      ],
    );
  }

  Widget _buildPendingBanner(Course course) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.salmon, AppColors.rose],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.warning_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Evaluación pendiente',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
                const SizedBox(height: 2),
                Text('Sprint 2 - ${course.name}',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85))),
                Text('Quedan 2h 30min',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCourseCard(Course course) {
    final hasPending = course.pendingEvaluations > 0;
    final badgeText =
        hasPending ? '${course.pendingEvaluations} pendiente' : 'Al día';
    final badgeColor = hasPending ? AppColors.salmon : AppColors.olive;

    return GestureDetector(
      onTap: () => Get.to(() => CourseDetailPage(course: course)),
      child: Container(
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
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.beige,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.book_rounded,
                  color: AppColors.olive, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course.name,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark)),
                  const SizedBox(height: 2),
                  Text(
                    '${course.teacherName ?? ""} | ${course.groupName ?? ""}',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(badgeText,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: badgeColor)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
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
        children: [
          SvgPicture.asset(
            'assets/logo.svg',
            height: 64,
            colorFilter: ColorFilter.mode(
              AppColors.textMuted.withValues(alpha: 0.35),
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sin resultados aún',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Aquí aparecerán tus calificaciones cuando\nse publiquen los resultados',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

