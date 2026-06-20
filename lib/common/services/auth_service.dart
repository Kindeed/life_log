import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../common/services/log_service.dart';

class AuthService extends ChangeNotifier {
  final _client = Supabase.instance.client;
  final ValueNotifier<User?> currentUser = ValueNotifier<User?>(null);
  StreamSubscription<AuthState>? _authStateSub;
  VoidCallback? _sessionExpiredHandler;

  AuthService start() {
    // Initialize current user
    _setCurrentUser(_client.auth.currentUser);

    // Listen to auth state changes
    _authStateSub = _client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      final hadUser = currentUser.value != null;

      _setCurrentUser(session?.user);

      if (event == AuthChangeEvent.signedIn) {
        LogService.to.info('Auth', 'User signed in: ${session?.user.email}');
      } else if (event == AuthChangeEvent.signedOut) {
        LogService.to.info('Auth', 'User signed out');
      } else if (session == null && hadUser) {
        LogService.to.warning('Auth', 'Auth session cleared by Supabase');
        _redirectToLogin();
      }
    });
    return this;
  }

  @override
  void dispose() {
    _authStateSub?.cancel();
    _authStateSub = null;
    currentUser.dispose();
    super.dispose();
  }

  void setSessionExpiredHandler(VoidCallback? handler) {
    _sessionExpiredHandler = handler;
  }

  // Sign In
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } catch (e, stackTrace) {
      LogService.to.error('Auth', 'Sign in failed: $e', stackTrace);
      rethrow;
    }
  }

  // Sign Up
  Future<void> signUp({required String email, required String password}) async {
    try {
      await _client.auth.signUp(email: email, password: password);
    } catch (e, stackTrace) {
      LogService.to.error('Auth', 'Sign up failed: $e', stackTrace);
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      _setCurrentUser(null);
    } catch (e, stackTrace) {
      LogService.to.error('Auth', 'Sign out failed: $e', stackTrace);
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
    _setCurrentUser(null);
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
    _sessionExpiredHandler?.call();
  }

  void _setCurrentUser(User? user) {
    if (currentUser.value == user) return;
    currentUser.value = user;
    notifyListeners();
  }

  // Check if logged in
  bool get isLoggedIn => currentUser.value != null;

  // Get User ID
  String? get userId => currentUser.value?.id;
}
