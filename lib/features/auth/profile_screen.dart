import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/firebase_auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cpfController = TextEditingController();
  final _cnpjController = TextEditingController();
  bool _isOrganization = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _cpfController.dispose();
    _cnpjController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final user = Provider.of<AuthController>(context, listen: false).currentUser;
    if (user != null) {
      setState(() {
        _isOrganization = user.isOrganization;
        _cpfController.text = user.cpf ?? '';
        _cnpjController.text = user.cnpj ?? '';
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authController = Provider.of<AuthController>(context, listen: false);
      final currentUser = authController.currentUser;
      
      if (currentUser == null) {
        throw Exception('Usuário não encontrado');
      }

      // Criar novo modelo de usuário com dados atualizados
      final updatedUser = UserModel(
        uid: currentUser.uid,
        email: currentUser.email,
        cpf: _isOrganization ? null : _cpfController.text.trim(),
        cnpj: _isOrganization ? _cnpjController.text.trim() : null,
        isOrganization: _isOrganization,
        createdAt: currentUser.createdAt,
      );

      // Atualizar no Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update(updatedUser.toMap());

      // Atualizar no AuthController
      authController.updateCurrentUser(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado com sucesso!')),
        );
        
        // Redirecionar para a tela apropriada baseada no novo role
        Navigator.pushReplacementNamed(context, '/welcome');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar perfil: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthController>(context).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email: ${user?.email ?? ""}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tipo: ${user?.isOrganization == true ? "Organização" : "Usuário"}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                title: const Text('Sou uma organização'),
                subtitle: const Text('Marque se você representa uma organização'),
                value: _isOrganization,
                onChanged: (value) {
                  setState(() {
                    _isOrganization = value;
                    // Limpar campos quando trocar de tipo
                    if (value) {
                      _cpfController.clear();
                    } else {
                      _cnpjController.clear();
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              if (!_isOrganization) ...[
                TextFormField(
                  controller: _cpfController,
                  decoration: const InputDecoration(
                    labelText: 'CPF',
                    hintText: 'Digite seu CPF',
                  ),
                  keyboardType: TextInputType.number,
                  validator: !_isOrganization
                      ? (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira seu CPF';
                          }
                          return null;
                        }
                      : null,
                ),
              ],
              if (_isOrganization) ...[
                TextFormField(
                  controller: _cnpjController,
                  decoration: const InputDecoration(
                    labelText: 'CNPJ',
                    hintText: 'Digite o CNPJ da organização',
                  ),
                  keyboardType: TextInputType.number,
                  validator: _isOrganization
                      ? (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira o CNPJ';
                          }
                          return null;
                        }
                      : null,
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Atualizar Perfil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 