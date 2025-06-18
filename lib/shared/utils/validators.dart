class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return "E-mail obrigatório";
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return "E-mail inválido";
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return "Senha obrigatória";
    if (value.length < 6) return "Senha deve ter 6+ caracteres";
    return null;
  }

  static String? validateCPF(String? value) {
    if (value == null || value.isEmpty) return "CPF obrigatório";
    if (value.length != 14) return "CPF inválido";
    return null;
  }

  static String? validateCNPJ(String? value) {
    if (value == null || value.isEmpty) return "CNPJ obrigatório";
    if (value.length != 18) return "CNPJ inválido";
    return null;
  }
}
