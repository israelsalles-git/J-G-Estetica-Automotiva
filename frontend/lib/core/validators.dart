/// Validações reutilizáveis. Todas retornam `null` quando o valor é válido
/// ou a mensagem de erro quando é inválido — o formato que o `TextFormField`
/// espera em `validator:` e que os providers também usam.
class Validators {
  Validators._();

  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  /// Campo de texto obrigatório.
  static String? requiredField(String? value,
      [String message = 'Campo obrigatório.']) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  /// Seleção obrigatória (dia, horário, serviço…).
  static String? choice(Object? value, String message) =>
      value == null ? message : null;

  static String? name(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Informe seu nome.';
    if (v.length < 3) return 'O nome deve ter ao menos 3 caracteres.';
    return null;
  }

  static String digitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');

  /// Telefone brasileiro: DDD + 8 ou 9 dígitos. Aceita máscara e +55.
  static String? phone(String? value) {
    var digits = digitsOnly(value ?? '');
    if (digits.isEmpty) return 'Informe o telefone.';
    if (digits.length > 11 && digits.startsWith('55')) {
      digits = digits.substring(2);
    }
    if (digits.length != 10 && digits.length != 11) {
      return 'Telefone inválido. Use DDD + número.';
    }
    if (int.parse(digits.substring(0, 2)) < 11) return 'DDD inválido.';
    if (digits.length == 11 && digits[2] != '9') {
      return 'Celular deve começar com 9 após o DDD.';
    }
    return null;
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Informe o e-mail.';
    if (!_email.hasMatch(v)) return 'E-mail inválido.';
    return null;
  }

  /// Torna qualquer validador opcional: campo vazio é aceito.
  static String? Function(String?) optional(String? Function(String?) rule) {
    return (value) {
      if (value == null || value.trim().isEmpty) return null;
      return rule(value);
    };
  }
}
