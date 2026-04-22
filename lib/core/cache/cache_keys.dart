class CacheKeys {
  CacheKeys._();

  static String coursesTeacher(String teacherId) =>
      'courses:teacher:$teacherId';

  static String coursesStudent(String studentId) =>
      'courses:student:$studentId';

  static String groupCategories(String courseId) =>
      'group_categories:$courseId';

  static String groups(String categoryId) => 'groups:$categoryId';

  static const String robleUsers = 'roble_users';
}
