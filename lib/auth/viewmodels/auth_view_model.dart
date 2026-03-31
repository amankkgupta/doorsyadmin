import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum SignInResult { success, unauthorized, failure }

class AuthViewModel extends ChangeNotifier {
  StreamSubscription<AuthState>? _authSubscription;
  User? _user;
  String? _errorMessage;
  bool _isLoading = false;
  bool _isInitializing = true;
  bool _bootstrapped = false;

  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  bool get isLoggedIn => _user != null;

  Future<void> bootstrap() async {
    if (_bootstrapped) {
      return;
    }

    _bootstrapped = true;

    if (!_isSupabaseReady) {
      _isInitializing = false;
      notifyListeners();
      return;
    }

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      event,
    ) {
      _user =
          event.session?.user ??
          Supabase.instance.client.auth.currentSession?.user ??
          Supabase.instance.client.auth.currentUser;
      _isInitializing = false;
      notifyListeners();
    });

    _user =
        Supabase.instance.client.auth.currentSession?.user ??
        Supabase.instance.client.auth.currentUser;

    if (_user != null) {
      final isAuthorized = await _isAdminUser(_user!.id);
      if (!isAuthorized) {
        _errorMessage = 'Unauthorized';
        await Supabase.instance.client.auth.signOut();
        _user = null;
      } else {
        _errorMessage = null;
      }
    }

    _isInitializing = false;
    notifyListeners();
  }

  Future<SignInResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (_isLoading || !_isSupabaseReady) {
      return SignInResult.failure;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      _user = response.user ?? Supabase.instance.client.auth.currentUser;

      if (_user == null) {
        _errorMessage = 'Unable to sign in right now.';
        return SignInResult.failure;
      }

      final isAuthorized = await _isAdminUser(_user!.id);
      if (!isAuthorized) {
        _errorMessage = 'Unauthorized';
        await Supabase.instance.client.auth.signOut();
        _user = null;
        return SignInResult.unauthorized;
      }

      return SignInResult.success;
    } on AuthException catch (error) {
      _errorMessage = error.message;
      return SignInResult.failure;
    } catch (error) {
      debugPrint('Email sign-in failed: $error');
      _errorMessage = 'Unable to sign in right now.';
      return SignInResult.failure;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    if (_isLoading || !_isSupabaseReady) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Supabase.instance.client.auth.signOut();
      _user = null;
    } on AuthException catch (error) {
      _errorMessage = error.message;
    } catch (error) {
      debugPrint('Sign-out failed: $error');
      _errorMessage = 'Unable to sign out right now.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool get _isSupabaseReady {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _isAdminUser(String userId) async {
    final adminRecord = await Supabase.instance.client
        .from('admins')
        .select('admin_id')
        .eq('admin_id', userId)
        .maybeSingle();

    return adminRecord != null;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
