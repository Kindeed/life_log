import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../common/theme/app_colors.dart';
import '../login_controller.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject controller specific to this view
    final controller = Get.put(LoginController());
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
                TextFormField(
                  controller: controller.emailController,
                  decoration: const InputDecoration(
                    labelText: '邮箱',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      v != null && v.contains('@') ? null : '请输入有效的邮箱',
                ),
                SizedBox(height: 20.h),
                TextFormField(
                  controller: controller.passwordController,
                  decoration: const InputDecoration(
                    labelText: '密码',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (v) =>
                      v != null && v.length >= 6 ? null : '密码至少6位',
                ),
                SizedBox(height: 40.h),
                ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : () => controller.submit(),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: controller.isLoading.value
                      ? CircularProgressIndicator(
                          color: theme.colorScheme.onPrimary,
                          strokeWidth: 2,
                        )
                      : Text(
                          controller.isLogin.value ? '登录' : '注册',
                          style: TextStyle(fontSize: 16.sp),
                        ),
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
