import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

class FirebaseAuthService implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

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

      // Atualizar o token com as claims mais recentes
      await result.user?.getIdToken(true);

      final userData = await _getUserData(result.user!.uid);
      return userData ?? await _createDefaultUserDocument(result.user!);
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

      final isOrganization = cnpj != null;
      final user = UserModel(
        uid: result.user!.uid,
        email: email.trim(),
        cpf: cpf?.trim(),
        cnpj: cnpj?.trim(),
        isOrganization: isOrganization,
        createdAt: DateTime.now(),
      );

      // Salvar no Firestore
      await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .set(user.toMap());

      // Configurar custom claims (se for organização)
      if (isOrganization) {
        await _setOrganizationClaim(result.user!.uid, true);
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw Exception('Erro desconhecido durante o cadastro: $e');
    }
  }

  Future<void> _setOrganizationClaim(String uid, bool isOrganization) async {
    try {
      // Em produção, isso deve ser feito em um backend seguro (Cloud Functions)
      // Esta é uma implementação simplificada para desenvolvimento

      // Obter o token atual
      final user = _auth.currentUser;
      if (user == null) return;

      // Atualizar claims
      await user.getIdToken(true); // Forçar refresh do token
    } catch (e) {
      throw Exception('Erro ao configurar permissões de organização: $e');
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
      if (currentUser == null) return null;

      // Forçar atualização do token para obter claims atualizadas
      await currentUser.getIdToken(true);

      final userData = await _getUserData(currentUser.uid);
      return userData ?? await _createDefaultUserDocument(currentUser);
    } catch (e) {
      throw Exception('Erro ao buscar usuário atual: $e');
    }
  }

  Future<UserModel> _createDefaultUserDocument(User firebaseUser) async {
    try {
      final user = UserModel(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        isOrganization: false,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(user.toMap());
      return user;
    } catch (e) {
      throw Exception('Erro ao criar documento do usuário: $e');
    }
  }

  Future<UserModel?> _getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists ? UserModel.fromMap(doc.data()!) : null;
    } catch (e) {
      throw Exception('Erro ao buscar dados do usuário: $e');
    }
  }

  Exception _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return Exception('Email inválido');
      case 'user-disabled':
        return Exception('Conta desativada');
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

  // Método para atualizar status de organização (deve ser chamado de um backend seguro)
  Future<void> updateOrganizationStatus(String uid, bool isOrganization) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isOrganization': isOrganization,
      });

      // Em produção, chamar uma Cloud Function para atualizar as claims
    } catch (e) {
      throw Exception('Erro ao atualizar status de organização: $e');
    }
  }
}
