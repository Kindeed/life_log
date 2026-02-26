import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../common/services/auth_service.dart';
import '../../../common/theme/app_colors.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final isLoading = false.obs;
  final isLogin = true.obs;

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void toggleMode() {
    isLogin.value = !isLogin.value;
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;

    try {
      if (isLogin.value) {
        await AuthService.to.signIn(
          email: emailController.text.trim(),
          password: passwordController.text,
        );
        Get.back(); // Return to Profile View
        Get.snackbar(
          '成功',
          '登录成功',
          backgroundColor: AppColors.successGreen.withValues(alpha: 0.1),
          colorText: AppColors.successGreen,
        );
      } else {
        await AuthService.to.signUp(
          email: emailController.text.trim(),
          password: passwordController.text,
        );
        Get.snackbar(
          '成功',
          '注册成功，请登录',
          backgroundColor: AppColors.successGreen.withValues(alpha: 0.1),
          colorText: AppColors.successGreen,
        );
        isLogin.value = true;
      }
    } on AuthException catch (e) {
      String message = e.message;
      if (e.code == 'email_not_confirmed') {
        message = '邮箱尚未验证，请查收邮件或登录 Supabase 后台关闭验证。';
      } else if (e.code == 'invalid_credentials') {
        message = '邮箱或密码错误。';
      } else if (e.code == 'user_already_exists') {
        message = '该邮箱已被注册。';
      }

      Get.snackbar(
        '操作失败',
        message,
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
        colorText: Get.theme.colorScheme.error,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
        colorText: Get.theme.colorScheme.error,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
