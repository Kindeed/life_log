import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../common/services/cloud_config_service.dart';
import '../../../common/theme/app_radius.dart';
import '../../../common/theme/theme_extensions.dart';
import '../../../common/widgets/app_button.dart';
import '../../../common/widgets/app_text_field.dart';
import '../login_controller.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LoginController>();
    final cloudConfig = Get.find<CloudConfigService>();
    final theme = Theme.of(context);
    final semantic = theme.semanticColors;

    return Obx(
      () => Scaffold(
        appBar: AppBar(title: Text(controller.isLogin.value ? '登录' : '注册')),
        body: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 28.h),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!cloudConfig.isConfigured.value) ...[
                  Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: semantic.warning.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: semantic.warning.withValues(alpha: 0.24),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.cloud_off_rounded,
                          size: 19.sp,
                          color: semantic.warning,
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            '云同步未配置，本地数据仍可使用。登录和注册暂不可用。',
                            style: TextStyle(
                              fontSize: 13.sp,
                              height: 1.35,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],
                AppTextField(
                  enabled: controller.isCloudAvailable,
                  controller: controller.emailController,
                  labelText: '邮箱',
                  prefixIcon: const Icon(Icons.email_outlined),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      v != null && v.contains('@') ? null : '请输入有效的邮箱',
                ),
                SizedBox(height: 20.h),
                AppTextField(
                  enabled: controller.isCloudAvailable,
                  controller: controller.passwordController,
                  labelText: '密码',
                  prefixIcon: const Icon(Icons.lock_outline),
                  obscureText: true,
                  validator: (v) =>
                      v != null && v.length >= 6 ? null : '密码至少6位',
                ),
                if (!controller.isLogin.value) ...[
                  SizedBox(height: 20.h),
                  AppTextField(
                    enabled: controller.isCloudAvailable,
                    controller: controller.confirmPasswordController,
                    labelText: '确认密码',
                    prefixIcon: const Icon(Icons.lock_outline),
                    obscureText: true,
                    validator: (v) =>
                        v != null && v.length >= 6 ? null : '密码至少6位',
                  ),
                ],
                SizedBox(height: 40.h),
                AppButton.primary(
                  label: controller.isLogin.value ? '登录' : '注册',
                  onPressed:
                      controller.isLoading.value || !controller.isCloudAvailable
                      ? null
                      : () => controller.submit(),
                  isLoading: controller.isLoading.value,
                  height: 52.h,
                ),
                SizedBox(height: 20.h),
                TextButton(
                  onPressed: controller.isCloudAvailable
                      ? () => controller.toggleMode()
                      : null,
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
