import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/constants/app_constants.dart';
import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/core/l10n/labels_es.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
import 'package:gymrank/core/utils/date_formatter.dart';
import 'package:gymrank/features/auth/domain/repositories/auth_repository.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_controller.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';
import 'package:gymrank/features/coach_panel/presentation/controllers/coach_panel_providers.dart';

/// Cadastro em duas etapas: credenciais (e-mail/senha) e perfil (nome,
/// usuário, data de nascimento, sexo, altura, cidade, objetivo e, opcional,
/// o código de convite da treinadora).
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _heightController = TextEditingController();
  final _cityController = TextEditingController();
  final _inviteCodeController = TextEditingController();

  DateTime? _birthDate;
  String _sex = 'feminino';
  UserGoal _goal = UserGoal.hipertrofia;
  int _step = 0;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _heightController.dispose();
    _cityController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elige tu fecha de nacimiento.')),
      );
      return;
    }
    final controller = ref.read(authControllerProvider.notifier);
    final registerFailure = await controller.registerWithEmail(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (registerFailure != null || !mounted) return;

    final uid = ref.read(authStateProvider).valueOrNull;
    if (uid == null) return;

    final signUpFailure = await controller.completeSignUp(
      uid,
      SignUpData(
        name: _nameController.text.trim(),
        username: _usernameController.text.trim(),
        birthDate: _birthDate!,
        sex: _sex,
        heightCm: double.tryParse(_heightController.text.replaceAll(',', '.')) ?? 0,
        city: _cityController.text.trim(),
        goal: _goal,
      ),
    );
    if (signUpFailure != null || !mounted) return;

    // Vínculo opcional com a treinadora pelo código de convite. Falha aqui
    // não invalida o cadastro: o aluno pode tentar de novo pelo Perfil.
    final code = _inviteCodeController.text.trim();
    if (code.isEmpty) return;
    final join = await ref
        .read(coachPanelRepositoryProvider)
        .joinCoach(userId: uid, inviteCode: code);
    if (!mounted) return;
    if (join.failureOrNull != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tu cuenta se creó, pero el código de coach no es válido. '
            'Puedes intentarlo de nuevo desde Perfil.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (_step == 0) ..._credentialsStep() else ..._profileStep(),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () {
                        if (_step == 0) {
                          if (_formKey.currentState?.validate() ?? false) {
                            setState(() => _step = 1);
                          }
                        } else {
                          _submit();
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_step == 0 ? 'Continuar' : 'Terminar registro'),
              ),
              if (_step == 1)
                TextButton(
                  onPressed: isLoading ? null : () => setState(() => _step = 0),
                  child: const Text('Volver'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _credentialsStep() {
    return [
      const Text('Tu cuenta', style: AppTextStyles.headline),
      const SizedBox(height: 16),
      TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        decoration: const InputDecoration(hintText: 'Correo electrónico'),
        validator: (v) =>
            (v == null || !v.contains('@')) ? 'Correo inválido' : null,
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _passwordController,
        obscureText: true,
        autofillHints: const [AutofillHints.newPassword],
        decoration: const InputDecoration(hintText: 'Contraseña'),
        validator: (v) =>
            (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
      ),
    ];
  }

  List<Widget> _profileStep() {
    return [
      const Text('Tu perfil', style: AppTextStyles.headline),
      const SizedBox(height: 16),
      TextFormField(
        controller: _nameController,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(hintText: 'Nombre completo'),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _usernameController,
        decoration: const InputDecoration(hintText: 'Nombre de usuario'),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9._]')),
        ],
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
      ),
      const SizedBox(height: 12),
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          _birthDate == null
              ? 'Fecha de nacimiento'
              : DateFormatter.shortDate(_birthDate!),
        ),
        trailing: const Icon(Icons.calendar_today),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime(2000),
            firstDate: DateTime(1940),
            lastDate: DateTime.now(),
          );
          if (picked != null) setState(() => _birthDate = picked);
        },
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        initialValue: _sex,
        items: const [
          DropdownMenuItem(value: 'feminino', child: Text('Femenino')),
          DropdownMenuItem(value: 'masculino', child: Text('Masculino')),
          DropdownMenuItem(value: 'outro', child: Text('Otro')),
        ],
        onChanged: (v) => setState(() => _sex = v ?? _sex),
        decoration: const InputDecoration(labelText: 'Sexo'),
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _heightController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(hintText: 'Estatura (cm)'),
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _cityController,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(hintText: 'Ciudad'),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<UserGoal>(
        initialValue: _goal,
        items: UserGoal.values
            .map((g) => DropdownMenuItem(value: g, child: Text(g.labelEs)))
            .toList(),
        onChanged: (v) => setState(() => _goal = v ?? _goal),
        decoration: const InputDecoration(labelText: 'Objetivo'),
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _inviteCodeController,
        textCapitalization: TextCapitalization.characters,
        inputFormatters: [
          LengthLimitingTextInputFormatter(8),
          FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
        ],
        decoration: const InputDecoration(
          labelText: 'Código de tu coach (opcional)',
          hintText: 'ABC123',
          helperText: 'Si tu coach te compartió un código, escríbelo aquí.',
        ),
      ),
    ];
  }
}
