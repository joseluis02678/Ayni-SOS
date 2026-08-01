import 'package:equatable/equatable.dart';
import 'package:core/src/domain/value_objects/enums.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.phone,
  });

  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String? phone;

  @override
  List<Object?> get props => [id, email, fullName, role, phone];
}

class AuthSession extends Equatable {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final AppUser user;

  @override
  List<Object?> get props => [accessToken, refreshToken, user];
}
