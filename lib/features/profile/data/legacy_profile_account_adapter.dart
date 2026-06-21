import 'dart:async';

import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/common/services/auth_service.dart';
import 'package:life_log/common/services/cloud_config_service.dart';
import 'package:life_log/common/services/sync_service.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/profile/domain/entities/profile_account_snapshot.dart';
import 'package:life_log/features/profile/domain/repositories/profile_account_repository_port.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final class LegacyProfileAccountAdapter
    implements ProfileAccountRepositoryPort {
  final CloudConfigService _cloudConfig;
  final AuthService? _authService;
  final SyncService? _syncService;

  const LegacyProfileAccountAdapter({
    required CloudConfigService cloudConfig,
    AuthService? authService,
    SyncService? syncService,
  }) : _cloudConfig = cloudConfig,
       _authService = authService,
       _syncService = syncService;

  @override
  bool get isCloudAvailable =>
      _cloudConfig.isConfigured && _authService != null;

  @override
  ProfileAccountSnapshot loadAccount() => _snapshot();

  @override
  Stream<ProfileAccountSnapshot> watchAccount() {
    final authService = _authService;
    if (authService == null) {
      return const Stream<ProfileAccountSnapshot>.empty();
    }

    late final StreamController<ProfileAccountSnapshot> controller;
    void Function()? listener;
    controller = StreamController<ProfileAccountSnapshot>(
      onListen: () {
        controller.add(_snapshot());
        listener = () {
          if (!controller.isClosed) {
            controller.add(_snapshot());
          }
        };
        authService.currentUser.addListener(listener!);
      },
      onCancel: () {
        final activeListener = listener;
        if (activeListener != null) {
          authService.currentUser.removeListener(activeListener);
        }
      },
    );
    return controller.stream;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      final authService = _requireAuthService();
      await authService.signIn(email: email, password: password);
    } catch (error, stackTrace) {
      throw _profileAuthFailure(error, stackTrace);
    }
  }

  @override
  Future<void> signUp({required String email, required String password}) async {
    try {
      final authService = _requireAuthService();
      await authService.signUp(email: email, password: password);
    } catch (error, stackTrace) {
      throw _profileAuthFailure(error, stackTrace);
    }
  }

  @override
  Future<void> signOut() async {
    await _authService?.signOut();
  }

  @override
  Future<bool> syncNow() async {
    final syncService =
        _syncService ??
        (serviceLocator.isRegistered<SyncService>()
            ? serviceLocator<SyncService>()
            : null);
    if (syncService == null) return false;
    return syncService.syncAll(
      reason: 'manual',
      forceFullRefresh: true,
      forceNew: true,
    );
  }

  ProfileAccountSnapshot _snapshot() {
    return ProfileAccountSnapshot(
      isCloudConfigured: _cloudConfig.isConfigured,
      userEmail: _authService?.currentUser.value?.email,
    );
  }

  AuthService _requireAuthService() {
    final authService = _authService;
    if (!isCloudAvailable || authService == null) {
      throw StateError('云同步未配置，登录和注册暂不可用。');
    }
    return authService;
  }

  AppFailure _profileAuthFailure(Object error, StackTrace stackTrace) {
    if (error is AppFailure) {
      return error;
    }
    if (error is AuthException) {
      return AppFailure(
        code: 'profile/auth-${error.code ?? 'supabase'}',
        message: _supabaseAuthMessage(error),
        cause: error,
        stackTrace: stackTrace,
      );
    }
    return AppFailure(
      code: 'profile/auth-unexpected',
      message: error.toString(),
      cause: error,
      stackTrace: stackTrace,
    );
  }

  String _supabaseAuthMessage(AuthException error) {
    return switch (error.code) {
      'email_not_confirmed' => '邮箱尚未验证，请查收邮件或登录 Supabase 后台关闭验证。',
      'invalid_credentials' => '邮箱或密码错误。',
      'user_already_exists' => '该邮箱已被注册。',
      _ => error.message,
    };
  }
}
