import 'package:flutter/material.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/ui/theme/app_theme.dart';
import 'package:frontend/ui/widgets/app_container.dart';

/// Tela de login: e-mail e senha, ou entrar com o Google.
/// Quem decide o que acontece depois do login é quem chama a tela,
/// através do [onLoggedIn].
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onLoggedIn,
    this.authService = const MockAuthService(),
  });

  final ValueChanged<AuthUser> onLoggedIn;
  final AuthService authService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _obscure = true;
  bool _busyEmail = false;
  bool _busyGoogle = false;
  String? _error;

  bool get _busy => _busyEmail || _busyGoogle;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Informe seu e-mail.';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text);
    return ok ? null : 'E-mail inválido.';
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Informe sua senha.';
    if (value.length < 6) return 'A senha deve ter pelo menos 6 caracteres.';
    return null;
  }

  Future<void> _submitEmail() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _busyEmail = true;
      _error = null;
    });
    try {
      final user = await widget.authService
          .signInWithEmail(_email.text.trim(), _password.text);
      if (!mounted) return;
      widget.onLoggedIn(user);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Não foi possível entrar. Tente novamente.');
    } finally {
      if (mounted) setState(() => _busyEmail = false);
    }
  }

  Future<void> _signInGoogle() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _busyGoogle = true;
      _error = null;
    });
    try {
      final user = await widget.authService.signInWithGoogle();
      if (!mounted) return;
      widget.onLoggedIn(user);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error = 'Não foi possível entrar com o Google. Tente novamente.',
      );
    } finally {
      if (mounted) setState(() => _busyGoogle = false);
    }
  }

  void _forgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recuperação de senha será ligada ao backend.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mobile = Responsive.isMobile(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.2,
            colors: [AppColors.card2, AppColors.bg],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(mobile ? 20 : 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _Logo(),
                    const SizedBox(height: 24),
                    _buildCard(mobile),
                    const SizedBox(height: 20),
                    const Text(
                      '© 2026 J&G Estética Automotiva',
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(bool mobile) {
    return Container(
      padding: EdgeInsets.all(mobile ? 22 : 32),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Bem-vindo de volta',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Entre para acessar o painel administrativo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 14),
              ),
              const SizedBox(height: 28),
              const _FieldLabel('E-MAIL'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _email,
                enabled: !_busy,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: _validateEmail,
                decoration: _decoration(
                  hint: 'voce@exemplo.com',
                  icon: Icons.mail_outline,
                ),
              ),
              const SizedBox(height: 16),
              const _FieldLabel('SENHA'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _password,
                enabled: !_busy,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                validator: _validatePassword,
                onFieldSubmitted: (_) => _submitEmail(),
                decoration: _decoration(
                  hint: '••••••••',
                  icon: Icons.lock_outline,
                  suffix: IconButton(
                    tooltip: _obscure ? 'Mostrar senha' : 'Ocultar senha',
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _busy ? null : _forgotPassword,
                  child: const Text(
                    'Esqueci minha senha',
                    style: TextStyle(color: AppColors.red, fontSize: 12),
                  ),
                ),
              ),
              if (_error != null) _ErrorBox(message: _error!),
              const SizedBox(height: 4),
              _PrimaryButton(
                label: 'Entrar',
                loading: _busyEmail,
                onTap: _busy ? null : _submitEmail,
              ),
              const SizedBox(height: 20),
              const _OrDivider(),
              const SizedBox(height: 20),
              _GoogleButton(
                loading: _busyGoogle,
                onPressed: _busy ? null : _signInGoogle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _decoration({
  required String hint,
  required IconData icon,
  Widget? suffix,
}) {
  OutlineInputBorder outline(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color),
      );

  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.muted),
    prefixIcon: Icon(icon, size: 20, color: AppColors.muted),
    suffixIcon: suffix,
    filled: true,
    fillColor: AppColors.card2,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: outline(AppColors.border),
    enabledBorder: outline(AppColors.border),
    focusedBorder: outline(AppColors.red),
  );
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.card,
        border: Border.all(
          color: AppColors.red.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.redGlow.withValues(alpha: 0.5),
            blurRadius: 40,
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'J&G',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: AppColors.red,
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w700,
        color: AppColors.muted,
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 13, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botão principal em largura total (o GradientButton do site tem largura
/// do texto e alinha o rótulo à esquerda, então aqui há uma versão própria).
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.loading,
    required this.onTap,
  });

  final String label;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    return Opacity(
      opacity: onTap == null && !loading ? 0.6 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.gradient,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: AppColors.redGlow.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: SizedBox(
              height: 52,
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'ou',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ),
        Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: AppColors.card2,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onPressed,
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.red,
                ),
              )
            : const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _GoogleBadge(),
                  SizedBox(width: 12),
                  Text(
                    'Continuar com o Google',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Selo simples com a letra G (não é o logotipo oficial do Google).
class _GoogleBadge extends StatelessWidget {
  const _GoogleBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            color: Color(0xFF4285F4),
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
