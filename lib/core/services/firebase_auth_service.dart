import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

class FirebaseAuthService implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  // Dependency injection for better testability
  FirebaseAuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<UserModel?> signIn(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (result.user == null) return null;

      // Buscar dados do usuário, criar se não existir
      final userData = await _getUserData(result.user!.uid);
      if (userData != null) {
        return userData;
      } else {
        // Usuário logado mas sem dados no Firestore, criar documento padrão
        return await _createDefaultUserDocument(result.user!);
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw Exception('Erro desconhecido durante o login: $e');
    }
  }

  @override
  Future<UserModel?> signUp({
    required String email,
    required String password,
    String? cpf,
    String? cnpj,
  }) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (result.user == null) return null;

      final user = UserModel(
        uid: result.user!.uid,
        email: email.trim(),
        cpf: cpf?.trim(),
        cnpj: cnpj?.trim(),
        isOrganization: cnpj != null,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .set(user.toMap());

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } on FirebaseException catch (e) {
      throw Exception('Erro no Firestore: ${e.message}');
    } catch (e) {
      throw Exception('Erro desconhecido durante o cadastro: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Erro ao fazer logout: $e');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final currentUser = _auth.currentUser;
      
      if (currentUser == null) {
        return null;
      }
      
      final userData = await _getUserData(currentUser.uid);
      
      if (userData != null) {
        return userData;
      } else {
        // Usuário logado mas sem dados no Firestore, criar documento padrão
        return await _createDefaultUserDocument(currentUser);
      }
    } catch (e) {
      throw Exception('Erro ao buscar usuário atual: $e');
    }
  }

  Future<UserModel> _createDefaultUserDocument(User firebaseUser) async {
    try {
      // Criar usuário padrão (usuário comum, não organização)
      final user = UserModel(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        cpf: null,
        cnpj: null,
        isOrganization: false, // Por padrão, usuário comum
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(user.toMap());

      return user;
    } on FirebaseException catch (e) {
      throw Exception('Erro ao criar documento do usuário: ${e.message}');
    }
  }

  Future<UserModel?> _getUserData(String uid) async {
    try {
      final DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) {
        return null;
      }

      return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    } on FirebaseException catch (e) {
      throw Exception('Erro ao buscar dados do usuário: ${e.message}');
    }
  }

  // Handles Firebase Auth specific errors
  Exception _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return Exception('Email inválido');
      case 'user-disabled':
        return Exception('Esta conta foi desativada');
      case 'user-not-found':
        return Exception('Usuário não encontrado');
      case 'wrong-password':
        return Exception('Senha incorreta');
      case 'email-already-in-use':
        return Exception('Email já está em uso');
      case 'operation-not-allowed':
        return Exception('Operação não permitida');
      case 'weak-password':
        return Exception('Senha muito fraca (mínimo 6 caracteres)');
      case 'too-many-requests':
        return Exception('Muitas tentativas. Tente novamente mais tarde');
      default:
        return Exception('Erro de autenticação: ${e.message}');
    }
  }
}
