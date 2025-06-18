import 'package:cloud_firestore/cloud_firestore.dart'; // Importação necessária

class UserModel {
  final String uid;
  final String email;
  final String? cpf;
  final String? cnpj;
  final bool isOrganization;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    this.cpf,
    this.cnpj,
    required this.isOrganization,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String,
      email: map['email'] as String,
      cpf: map['cpf'] as String?,
      cnpj: map['cnpj'] as String?,
      isOrganization: map['isOrganization'] as bool,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'cpf': cpf,
      'cnpj': cnpj,
      'isOrganization': isOrganization,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
