import 'package:flutter/foundation.dart';
import 'package:habitos_app/domain/entities/user_entity.dart';
import 'package:habitos_app/domain/repositories/auth_repository.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthProvider({required AuthRepository authRepository})
      : _authRepository = authRepository;

  AuthStatus _status = AuthStatus.initial;
  UserEntity? _user;
  String? _error;
  bool _registeredSuccessfully = false;

  AuthStatus get status => _status;
  UserEntity? get user => _user;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get registeredSuccessfully => _registeredSuccessfully;

  Future<void> checkAuthStatus() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final isAuth = await _authRepository.isAuthenticated();
      if (isAuth) {
        _user = await _authRepository.getCurrentUser();
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      _user = await _authRepository.login(email, password);
      _status = AuthStatus.authenticated;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _status = AuthStatus.error;
    }
    notifyListeners();
  }

  Future<void> register(String name, String email, String password) async {
    _status = AuthStatus.loading;
    _error = null;
    _registeredSuccessfully = false;
    notifyListeners();

    try {
      await _authRepository.register(name, email, password);
      _status = AuthStatus.unauthenticated;
      _registeredSuccessfully = true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _status = AuthStatus.error;
    }
    notifyListeners();
  }

  void clearRegisteredFlag() {
    _registeredSuccessfully = false;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
