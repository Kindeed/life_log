import 'dart:async';

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../common/services/log_service.dart';

class AuthService extends GetxService {
  static AuthService get to => Get.find();

  final _client = Supabase.instance.client;
  final Rx<User?> currentUser = Rx<User?>(null);
  StreamSubscription<AuthState>? _authStateSub;

  @override
  void onInit() {
    super.onInit();
    // Initialize current user
    currentUser.value = _client.auth.currentUser;

    // Listen to auth state changes
    _authStateSub = _client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      final hadUser = currentUser.value != null;

      currentUser.value = session?.user;

      if (event == AuthChangeEvent.signedIn) {
        LogService.to.info('Auth', 'User signed in: ${session?.user.email}');
      } else if (event == AuthChangeEvent.signedOut) {
        LogService.to.info('Auth', 'User signed out');
      } else if (session == null && hadUser) {
        LogService.to.warning('Auth', 'Auth session cleared by Supabase');
        _redirectToLogin();
      }
    });
  }

  @override
  void onClose() {
    _authStateSub?.cancel();
    _authStateSub = null;
    super.onClose();
  }

  // Sign In
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      LogService.to.error('Auth', 'Sign in failed: $e');
      rethrow;
    }
  }

  // Sign Up
  Future<void> signUp({required String email, required String password}) async {
    try {
      await _client.auth.signUp(email: email, password: password);
    } catch (e) {
      LogService.to.error('Auth', 'Sign up failed: $e');
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      currentUser.value = null;
    } catch (e) {
      LogService.to.error('Auth', 'Sign out failed: $e');
      rethrow;
    }
  }

  Future<void> handleSessionExpired(
    Object error, {
    String source = 'unknown',
  }) async {
    if (!isSessionExpiredError(error)) return;

    LogService.to.warning(
      'Auth',
      'Session expired during $source; signing out locally',
    );
    currentUser.value = null;
    try {
      await _client.auth.signOut();
    } catch (e) {
      LogService.to.warning('Auth', 'Remote sign out after expiry failed: $e');
    }
    _redirectToLogin();
  }

  bool isSessionExpiredError(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('401') ||
        text.contains('unauthorized') ||
        text.contains('jwt expired') ||
        text.contains('invalid jwt') ||
        text.contains('invalid refresh token') ||
        text.contains('refresh token not found') ||
        text.contains('session_not_found') ||
        text.contains('invalid_session');
  }

  void _redirectToLogin() {
    if (Get.currentRoute != '/login') {
      Get.offAllNamed('/login');
    }
  }

  // Check if logged in
  bool get isLoggedIn => currentUser.value != null;

  // Get User ID
  String? get userId => currentUser.value?.id;
}
