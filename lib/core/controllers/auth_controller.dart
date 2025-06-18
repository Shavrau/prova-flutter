import 'package:flutter/foundation.dart';
import '../repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthController with ChangeNotifier {
  final AuthRepository _authRepository;
  UserModel? _currentUser;

  AuthController(this._authRepository);

  UserModel? get currentUser => _currentUser;

  Future<UserModel?> initializeUser() async {
    try {
      _currentUser = await _authRepository.getCurrentUser();
      notifyListeners();
      return _currentUser;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> signIn(String email, String password) async {
    try {
      _currentUser = await _authRepository.signIn(email, password);
      notifyListeners();
      return _currentUser;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> signUp({
    required String email,
    required String password,
    String? cpf,
    String? cnpj,
  }) async {
    try {
      _currentUser = await _authRepository.signUp(
        email: email,
        password: password,
        cpf: cpf,
        cnpj: cnpj,
      );
      notifyListeners();
      return _currentUser;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  void updateCurrentUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }
}
