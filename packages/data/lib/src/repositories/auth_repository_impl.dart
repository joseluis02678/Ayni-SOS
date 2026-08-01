import 'package:core/core.dart';
import 'package:data/src/local/app_database.dart';
import 'package:data/src/remote/api_client.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._api, this._db);

  final ApiClient _api;
  final AppDatabase _db;

  @override
  Future<AuthSession> register({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? phone,
  }) async {
    final res = await _api.dio.post('/api/v1/auth/register', data: {
      'email': email,
      'password': password,
      'full_name': fullName,
      'phone': phone,
      'role': role.name,
    });
    return _fromTokenResponse(res.data as Map<String, dynamic>);
  }

  @override
  Future<AuthSession> login({required String email, required String password}) async {
    final res = await _api.dio.post('/api/v1/auth/login', data: {
      'email': email,
      'password': password,
    });
    return _fromTokenResponse(res.data as Map<String, dynamic>);
  }

  @override
  Future<AuthSession> refresh(String refreshToken) async {
    final res = await _api.dio.post('/api/v1/auth/refresh', data: {
      'refresh_token': refreshToken,
    });
    return _fromTokenResponse(res.data as Map<String, dynamic>);
  }

  @override
  Future<void> logout() async {
    try {
      await _api.dio.post('/api/v1/auth/logout');
    } catch (_) {}
    await _api.clearTokens();
    await _db.clearSession();
  }

  @override
  Future<AuthSession?> getCachedSession() async {
    final row = await _db.getSession();
    if (row == null) return null;
    return AuthSession(
      accessToken: row['access_token'] as String,
      refreshToken: row['refresh_token'] as String,
      user: AppUser(
        id: row['user_id'] as String,
        email: row['email'] as String? ?? '',
        fullName: row['full_name'] as String? ?? '',
        role: UserRole.values.byName(row['role'] as String? ?? 'citizen'),
      ),
    );
  }

  @override
  Future<void> saveSession(AuthSession session) async {
    await _api.saveTokens(access: session.accessToken, refresh: session.refreshToken);
    await _db.saveSession({
      'access_token': session.accessToken,
      'refresh_token': session.refreshToken,
      'user_id': session.user.id,
      'email': session.user.email,
      'full_name': session.user.fullName,
      'role': session.user.role.name,
    });
  }

  Future<AuthSession> _fromTokenResponse(Map<String, dynamic> data) async {
    final role = UserRole.values.byName(data['role'] as String);
    final session = AuthSession(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
      user: AppUser(
        id: data['user_id'] as String,
        email: '',
        fullName: data['full_name'] as String,
        role: role,
      ),
    );
    await saveSession(session);
    return session;
  }
}
