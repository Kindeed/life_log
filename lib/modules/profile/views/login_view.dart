import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../common/widgets/app_button.dart';
import '../../../common/widgets/app_text_field.dart';
import '../login_controller.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LoginController>();
    final theme = Theme.of(context);

    return Obx(
      () => Scaffold(
        appBar: AppBar(title: Text(controller.isLogin.value ? '登录' : '注册')),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: controller.emailController,
                  labelText: '邮箱',
                  prefixIcon: const Icon(Icons.email_outlined),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      v != null && v.contains('@') ? null : '请输入有效的邮箱',
                ),
                SizedBox(height: 20.h),
                AppTextField(
                  controller: controller.passwordController,
                  labelText: '密码',
                  prefixIcon: const Icon(Icons.lock_outline),
                  obscureText: true,
                  validator: (v) =>
                      v != null && v.length >= 6 ? null : '密码至少6位',
                ),
                SizedBox(height: 40.h),
                AppButton.primary(
                  label: controller.isLogin.value ? '登录' : '注册',
                  onPressed: controller.isLoading.value
                      ? null
                      : () => controller.submit(),
                  isLoading: controller.isLoading.value,
                  height: 52.h,
                ),
                SizedBox(height: 20.h),
                TextButton(
                  onPressed: () => controller.toggleMode(),
                  child: Text(
                    controller.isLogin.value ? '没有账号？去注册' : '已有账号？去登录',
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color?.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
