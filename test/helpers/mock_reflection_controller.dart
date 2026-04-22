import 'package:f_clean_template/features/reflection/domain/models/reflection.dart';
import 'package:f_clean_template/features/reflection/domain/models/reflection_prompt.dart';
import 'package:f_clean_template/features/reflection/ui/viewmodels/reflection_controller.dart';
import 'package:get/get.dart';
import 'package:mockito/mockito.dart';

class MockReflectionController extends GetxService
    with Mock
    implements ReflectionController {
  @override
  final RxList<ReflectionPrompt> prompts = <ReflectionPrompt>[].obs;

  @override
  final RxBool isLoadingPrompts = false.obs;

  @override
  final Rx<Reflection?> myReflection = Rx<Reflection?>(null);

  @override
  final RxBool isLoadingMyReflection = false.obs;

  @override
  final RxBool isSubmitting = false.obs;

  @override
  final RxList<Reflection> reviewList = <Reflection>[].obs;

  @override
  final RxBool isLoadingReviewList = false.obs;

  @override
  Future<void> loadPrompts() async {}

  @override
  Future<void> loadMyReflection(String studentId, String assessmentId) async {}

  @override
  Future<bool> submitReflection(Reflection reflection) async => true;

  @override
  Future<void> loadReviewList(String studentId, String assessmentId) async {}

  @override
  void onInit() {}
}
