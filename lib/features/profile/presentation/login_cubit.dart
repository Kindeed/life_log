import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/core/result/app_result.dart';
import 'package:life_log/features/profile/application/sign_in_profile_account.dart';
import 'package:life_log/features/profile/application/sign_up_profile_account.dart';

enum LoginSubmitOutcome { signedIn, registered }

final class LoginState extends Equatable {
  final bool isLogin;
  final bool isLoading;
  final bool isCloudAvailable;

  const LoginState({
    required this.isLogin,
    required this.isLoading,
    required this.isCloudAvailable,
  });

  LoginState copyWith({
    bool? isLogin,
    bool? isLoading,
    bool? isCloudAvailable,
  }) {
    return LoginState(
      isLogin: isLogin ?? this.isLogin,
      isLoading: isLoading ?? this.isLoading,
      isCloudAvailable: isCloudAvailable ?? this.isCloudAvailable,
    );
  }

  @override
  List<Object?> get props => [isLogin, isLoading, isCloudAvailable];
}

final class LoginCubit extends Cubit<LoginState> {
  final SignInProfileAccount _signIn;
  final SignUpProfileAccount _signUp;

  LoginCubit({
    required SignInProfileAccount signIn,
    required SignUpProfileAccount signUp,
    required bool isCloudAvailable,
  }) : _signIn = signIn,
       _signUp = signUp,
       super(
         LoginState(
           isLogin: true,
           isLoading: false,
           isCloudAvailable: isCloudAvailable,
         ),
       );

  void toggleMode() {
    emit(state.copyWith(isLogin: !state.isLogin));
  }

  Future<AppResult<LoginSubmitOutcome>> submit({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    if (!state.isCloudAvailable) {
      return const AppResult.failure(
        AppFailure(
          code: 'profile/cloud-unavailable',
          message: '当前为本地模式，登录和注册暂不可用。',
        ),
      );
    }
    if (!state.isLogin && confirmPassword != password) {
      return const AppResult.failure(
        AppFailure(code: 'profile/password-mismatch', message: '两次输入的密码不一致。'),
      );
    }

    emit(state.copyWith(isLoading: true));
    final AppResult<LoginSubmitOutcome> result;
    if (state.isLogin) {
      final signInResult = await _signIn(email: email, password: password);
      result = signInResult.when(
        success: (_) => const AppResult.success(LoginSubmitOutcome.signedIn),
        failure: AppResult.failure,
      );
    } else {
      final signUpResult = await _signUp(email: email, password: password);
      result = signUpResult.when(
        success: (_) => const AppResult.success(LoginSubmitOutcome.registered),
        failure: AppResult.failure,
      );
      if (result.isSuccess) {
        emit(state.copyWith(isLogin: true, isLoading: false));
        return result;
      }
    }

    if (!isClosed) {
      emit(state.copyWith(isLoading: false));
    }
    return result;
  }
}
