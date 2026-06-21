import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:life_log/common/theme/app_radius.dart';
import 'package:life_log/common/theme/theme_extensions.dart';
import 'package:life_log/common/widgets/app_button.dart';
import 'package:life_log/common/widgets/app_text_field.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/core/routing/app_routes.dart';
import 'package:life_log/features/profile/presentation/login_cubit.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final LoginCubit loginCubit;
  late final TextEditingController emailController;
  late final TextEditingController passwordController;
  late final TextEditingController confirmPasswordController;
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    loginCubit = serviceLocator<LoginCubit>();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    loginCubit.close();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.semanticColors;

    return BlocBuilder<LoginCubit, LoginState>(
      bloc: loginCubit,
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: Text(state.isLogin ? '登录' : '注册')),
          body: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 28.h),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!state.isCloudAvailable) ...[
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
                    enabled: state.isCloudAvailable,
                    controller: emailController,
                    labelText: '邮箱',
                    prefixIcon: const Icon(Icons.email_outlined),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => value != null && value.contains('@')
                        ? null
                        : '请输入有效的邮箱',
                  ),
                  SizedBox(height: 20.h),
                  AppTextField(
                    enabled: state.isCloudAvailable,
                    controller: passwordController,
                    labelText: '密码',
                    prefixIcon: const Icon(Icons.lock_outline),
                    obscureText: true,
                    validator: (value) =>
                        value != null && value.length >= 6 ? null : '密码至少6位',
                  ),
                  if (!state.isLogin) ...[
                    SizedBox(height: 20.h),
                    AppTextField(
                      enabled: state.isCloudAvailable,
                      controller: confirmPasswordController,
                      labelText: '确认密码',
                      prefixIcon: const Icon(Icons.lock_outline),
                      obscureText: true,
                      validator: (value) =>
                          value != null && value.length >= 6 ? null : '密码至少6位',
                    ),
                  ],
                  SizedBox(height: 40.h),
                  AppButton.primary(
                    label: state.isLogin ? '登录' : '注册',
                    onPressed: state.isLoading || !state.isCloudAvailable
                        ? null
                        : _submit,
                    isLoading: state.isLoading,
                    height: 52.h,
                  ),
                  SizedBox(height: 20.h),
                  TextButton(
                    onPressed: state.isCloudAvailable
                        ? loginCubit.toggleMode
                        : null,
                    child: Text(
                      state.isLogin ? '没有账号？去注册' : '已有账号？去登录',
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
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final result = await loginCubit.submit(
      email: emailController.text.trim(),
      password: passwordController.text,
      confirmPassword: confirmPasswordController.text,
    );
    final failure = result.failureOrNull;
    if (failure != null) {
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
      return;
    }

    switch (result.valueOrNull!) {
      case LoginSubmitOutcome.signedIn:
        messenger.showSnackBar(const SnackBar(content: Text('登录成功')));
        if (!mounted) return;
        context.go(AppRoutes.root);
        break;
      case LoginSubmitOutcome.registered:
        confirmPasswordController.clear();
        messenger.showSnackBar(const SnackBar(content: Text('注册成功，请登录')));
        break;
    }
  }
}
