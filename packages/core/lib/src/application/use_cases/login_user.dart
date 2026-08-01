import 'package:core/src/domain/entities/report.dart';
import 'package:core/src/domain/entities/user.dart';
import 'package:core/src/domain/repositories/auth_repository.dart';
import 'package:core/src/domain/value_objects/enums.dart';

class LoginUser {
  LoginUser(this._auth);

  final AuthRepository _auth;

  Future<AuthSession> call({required String email, required String password}) {
    return _auth.login(email: email, password: password);
  }
}

class RegisterUser {
  RegisterUser(this._auth);

  final AuthRepository _auth;

  Future<AuthSession> call({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? phone,
  }) {
    return _auth.register(
      email: email,
      password: password,
      fullName: fullName,
      role: role,
      phone: phone,
    );
  }
}
