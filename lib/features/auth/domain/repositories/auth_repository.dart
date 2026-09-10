import 'package:gymrank/core/constants/app_constants.dart';
import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/features/profile/domain/entities/user_entity.dart';

/// Dados coletados no cadastro (ver spec "Autenticação" no README do
/// produto). `phone`/`email` dependem do método de login escolhido. O
/// vínculo com a treinadora (código de convite) é feito logo após o
/// cadastro pelo `CoachPanelRepository`, não aqui.
class SignUpData {
  const SignUpData({
    required this.name,
    required this.username,
    required this.birthDate,
    required this.sex,
    required this.heightCm,
    required this.city,
    required this.goal,
  });

  final String name;
  final String username;
  final DateTime birthDate;
  final String sex;
  final double heightCm;
  final String city;
  final UserGoal goal;
}

abstract interface class AuthRepository {
  Stream<String?> authStateChanges();

  Future<Result<UserEntity>> currentUser();

  Future<Result<String>> signInWithGoogle();

  Future<Result<String>> signInWithApple();

  Future<Result<String>> signInWithEmail({
    required String email,
    required String password,
  });

  Future<Result<String>> registerWithEmail({
    required String email,
    required String password,
  });

  Future<Result<void>> sendPhoneVerificationCode(String phoneNumber);

  Future<Result<String>> confirmPhoneCode({
    required String verificationId,
    required String smsCode,
  });

  Future<Result<bool>> isUsernameAvailable(String username);

  Future<Result<UserEntity>> completeSignUp({
    required String uid,
    required SignUpData data,
  });

  Future<void> signOut();
}
