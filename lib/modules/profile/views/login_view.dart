import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../common/services/auth_service.dart';
import '../../../common/theme/app_colors.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isLogin = true; // Toggle between Login and Sign Up

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await AuthService.to.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        Get.back(); // Return to Profile View
        Get.snackbar(
          '成功',
          '登录成功',
          backgroundColor: AppColors.green.withValues(alpha: 0.1),
          colorText: AppColors.green,
        );
      } else {
        await AuthService.to.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        Get.snackbar(
          '成功',
          '注册成功，请登录',
          backgroundColor: AppColors.green.withValues(alpha: 0.1),
          colorText: AppColors.green,
        );
        setState(() => _isLogin = true); // Switch to login
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
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? '登录' : '注册')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
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
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: '密码',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (v) => v != null && v.length >= 6 ? null : '密码至少6位',
              ),
              SizedBox(height: 40.h),

              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _isLogin ? '登录' : '注册',
                        style: TextStyle(fontSize: 16.sp),
                      ),
              ),

              SizedBox(height: 20.h),
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(
                  _isLogin ? '没有账号？去注册' : '已有账号？去登录',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
