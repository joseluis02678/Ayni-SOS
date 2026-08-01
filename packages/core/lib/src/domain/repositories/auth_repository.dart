import 'package:core/src/domain/entities/user.dart';
import 'package:core/src/domain/value_objects/enums.dart';

abstract class AuthRepository {
  Future<AuthSession> register({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? phone,
  });

  Future<AuthSession> login({required String email, required String password});

  Future<AuthSession> refresh(String refreshToken);

  Future<void> logout();

  Future<AuthSession?> getCachedSession();

  Future<void> saveSession(AuthSession session);
}
