import '../models/user_model.dart'; // Importação adicionada

abstract class AuthRepository {
  Future<UserModel?> signIn(String email, String password);
  Future<UserModel?> signUp({
    required String email,
    required String password,
    String? cpf,
    String? cnpj,
  });
  Future<UserModel?> getCurrentUser();
  Future<void> signOut();
}
