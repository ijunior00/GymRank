import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/constants/app_constants.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
import 'package:gymrank/features/auth/domain/repositories/auth_repository.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_controller.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';

/// Cadastro em duas etapas: credenciais (e-mail/senha) e perfil (nome,
/// username, data de nascimento, sexo, altura, cidade, objetivo).
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
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false) || _birthDate == null) {
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

    await controller.completeSignUp(
      uid,
      SignUpData(
        name: _nameController.text.trim(),
        username: _usernameController.text.trim(),
        birthDate: _birthDate!,
        sex: _sex,
        heightCm: double.tryParse(_heightController.text) ?? 0,
        city: _cityController.text.trim(),
        goal: _goal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
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
                    : Text(_step == 0 ? 'Continuar' : 'Concluir cadastro'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _credentialsStep() {
    return [
      Text('Sua conta', style: AppTextStyles.headline),
      const SizedBox(height: 16),
      TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(hintText: 'E-mail'),
        validator: (v) =>
            (v == null || !v.contains('@')) ? 'E-mail inválido' : null,
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _passwordController,
        obscureText: true,
        decoration: const InputDecoration(hintText: 'Senha'),
        validator: (v) =>
            (v == null || v.length < 6) ? 'Mínimo de 6 caracteres' : null,
      ),
    ];
  }

  List<Widget> _profileStep() {
    return [
      Text('Seu perfil', style: AppTextStyles.headline),
      const SizedBox(height: 16),
      TextFormField(
        controller: _nameController,
        decoration: const InputDecoration(hintText: 'Nome completo'),
        validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _usernameController,
        decoration: const InputDecoration(hintText: 'Username único'),
        validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
      ),
      const SizedBox(height: 12),
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          _birthDate == null
              ? 'Data de nascimento'
              : '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}',
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
          DropdownMenuItem(value: 'feminino', child: Text('Feminino')),
          DropdownMenuItem(value: 'masculino', child: Text('Masculino')),
          DropdownMenuItem(value: 'outro', child: Text('Outro')),
        ],
        onChanged: (v) => setState(() => _sex = v ?? _sex),
        decoration: const InputDecoration(labelText: 'Sexo'),
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _heightController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(hintText: 'Altura (cm)'),
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _cityController,
        decoration: const InputDecoration(hintText: 'Cidade'),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<UserGoal>(
        initialValue: _goal,
        items: UserGoal.values
            .map((g) => DropdownMenuItem(value: g, child: Text(g.label)))
            .toList(),
        onChanged: (v) => setState(() => _goal = v ?? _goal),
        decoration: const InputDecoration(labelText: 'Objetivo'),
      ),
    ];
  }
}

extension on UserGoal {
  String get label => switch (this) {
    UserGoal.emagrecimento => 'Emagrecimento',
    UserGoal.hipertrofia => 'Hipertrofia',
    UserGoal.performance => 'Performance',
    UserGoal.saude => 'Saúde',
    UserGoal.reabilitacao => 'Reabilitação',
  };
}
