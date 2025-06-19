import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/controllers/auth_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Aguarda um pouco para mostrar a splash
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Verifica primeiro se há usuário logado no Firebase Auth
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    // Se há usuário logado, tenta buscar os dados do Firestore
    final authController = Provider.of<AuthController>(context, listen: false);

    try {
      final user = await authController.initializeUser();

      if (user != null && mounted) {
        // Redireciona para a tela de boas-vindas independente do tipo de usuário
        Navigator.pushReplacementNamed(context, '/welcome');
      } else {
        // Usuário logado mas sem dados no Firestore, fazer logout e ir para login
        await authController.signOut();
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } catch (e) {
      // Erro ao buscar dados do usuário, fazer logout e ir para login
      try {
        await authController.signOut();
      } catch (signOutError) {
        // Ignorar erro de logout
      }
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/cps-55-anos.png', height: 100),
            Image.asset('assets/images/cst-dsm.png', height: 100),
            Image.asset('assets/images/fatec-matao.jpg', height: 100),
            const SizedBox(height: 30),
            const Text('Equipe: Eventplan', style: TextStyle(fontSize: 20)),
            const Text('Membros:', style: TextStyle(fontSize: 18)),
            const Text('1. Cleston Tomioka', style: TextStyle(fontSize: 16)),
            const Text('2. Felipe Slagado', style: TextStyle(fontSize: 16)),
            const Text('3. Kayro César', style: TextStyle(fontSize: 16)),
            const Text('4. Pedro Biondi', style: TextStyle(fontSize: 16)),
            const Text('5 Paulo Selestrino', style: TextStyle(fontSize: 16)),
            const Text('6. Rhian Souza', style: TextStyle(fontSize: 16)),
            // Adicione todos os membros
            const SizedBox(height: 50),
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text('Carregando...', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
