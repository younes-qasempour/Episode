import 'package:flutter/foundation.dart';
import '../models/auth_models.dart';
import '../repositories/auth_repository.dart';
import '../services/api_exceptions.dart';

class AuthController extends ChangeNotifier {
  final AuthRepository authRepository;

  AuthState _state = AuthState.unknown;
  AuthenticatedUser? _currentUser;
  String? _errorMessage;

  AuthController({required this.authRepository});

  AuthState get state => _state;
  AuthenticatedUser? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated =>
      _state == AuthState.authenticated ||
      _state == AuthState.authenticatedOffline;
  bool get isOffline => _state == AuthState.authenticatedOffline;

  Future<void> restoreSession() async {
    _errorMessage = null;
    try {
      final tokens = await authRepository.tokenStorage.loadTokens();
      if (tokens == null || tokens.refreshToken.isEmpty) {
        _state = AuthState.anonymous;
        _currentUser = null;
        notifyListeners();
        return;
      }

      try {
        final user = await authRepository.getCurrentUser();
        _currentUser = user;
        _state = AuthState.authenticated;
      } on NetworkUnavailableException {
        _state = AuthState.authenticatedOffline;
      } on RequestTimeoutException {
        _state = AuthState.authenticatedOffline;
      } on ServerUnavailableException {
        _state = AuthState.authenticatedOffline;
      } on AuthenticationRequiredException {
        await authRepository.tokenStorage.clearTokens();
        _currentUser = null;
        _state = AuthState.sessionExpired;
      } catch (_) {
        _state = AuthState.authenticatedOffline;
      }
    } catch (_) {
      _state = AuthState.anonymous;
      _currentUser = null;
    }
    notifyListeners();
  }

  Future<bool> register({
    required String email,
    required String password,
  }) async {
    _errorMessage = null;
    try {
      final result = await authRepository.register(
        email: email,
        password: password,
      );
      _currentUser = result.user;
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Registration failed: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _errorMessage = null;
    try {
      final result = await authRepository.login(
        email: email,
        password: password,
      );
      _currentUser = result.user;
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Login failed: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _errorMessage = null;
    await authRepository.logout();
    _currentUser = null;
    _state = AuthState.anonymous;
    notifyListeners();
  }

  Future<void> logoutAll() async {
    _errorMessage = null;
    await authRepository.logoutAll();
    _currentUser = null;
    _state = AuthState.anonymous;
    notifyListeners();
  }

  Future<bool> deleteAccount({required String password}) async {
    _errorMessage = null;
    try {
      await authRepository.deleteAccount(password: password);
      _currentUser = null;
      _state = AuthState.anonymous;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Account deletion failed: $e';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
