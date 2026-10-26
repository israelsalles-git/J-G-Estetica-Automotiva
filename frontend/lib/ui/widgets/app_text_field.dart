import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Campo de texto padrão do site, pronto para formulários ligados a uma API.
///
/// [name] é o identificador do campo e deve ser o MESMO nome da propriedade
/// enviada à API (ex.: `customerPhone`). Ele vira a `Key` do campo
/// (`field_customerPhone`), o que também facilita testes automatizados.
///
/// Exemplo (telefone obrigatório):
/// ```dart
/// AppTextField(
///   name: 'customerPhone',
///   label: 'Telefone',
///   keyboardType: TextInputType.phone,
///   validator: Validators.phone,
/// )
/// ```
class AppTextField extends StatelessWidget {
  final String name;
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final int maxLines;
  final bool enabled;

  const AppTextField({
    super.key,
    required this.name,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.onChanged,
    this.keyboardType,
    this.inputFormatters,
    this.autofillHints,
    this.maxLines = 1,
    this.enabled = true,
  });

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color),
      );

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: ValueKey('field_$name'),
      controller: controller,
      validator: validator,
      onChanged: onChanged,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      autofillHints: autofillHints,
      maxLines: maxLines,
      enabled: enabled,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: AppColors.muted),
        filled: true,
        fillColor: AppColors.card2,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: _border(AppColors.border),
        enabledBorder: _border(AppColors.border),
        focusedBorder: _border(AppColors.red),
        errorBorder: _border(Colors.redAccent),
        focusedErrorBorder: _border(Colors.redAccent),
      ),
    );
  }
}
