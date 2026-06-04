import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/api_client.dart';

const _storage = FlutterSecureStorage();

class AuthUser {
  final String id, orgId, email, fullName, role;
  final String? orgName;
  AuthUser({required this.id, required this.orgId, required this.email,
      required this.fullName, required this.role, this.orgName});

  factory AuthUser.fromJson(Map<String, dynamic> j) => AuthUser(
    id: j['id'] ?? '', orgId: j['org_id'] ?? '', email: j['email'] ?? '',
    fullName: j['full_name'] ?? '', role: j['role'] ?? 'agent',
    orgName: j['org_name'],
  );
}

class AuthRepository {
  final ApiClient _api;
  AuthRepository(this._api);

  Future<AuthUser> login(String email, String password) async {
    final r = await _api.post('/auth/login', data: {'email': email, 'password': password});
    final data = r.data['data'];
    await _storage.write(key: 'access_token',  value: data['accessToken']);
    await _storage.write(key: 'refresh_token', value: data['refreshToken']);
    return AuthUser.fromJson(data['user']);
  }

  Future<AuthUser> register({required String orgName, required String email,
      required String password, required String fullName}) async {
    final r = await _api.post('/auth/register', data: {
      'orgName': orgName, 'email': email, 'password': password, 'fullName': fullName,
    });
    final data = r.data['data'];
    await _storage.write(key: 'access_token',  value: data['accessToken']);
    await _storage.write(key: 'refresh_token', value: data['refreshToken']);
    return AuthUser.fromJson(data['user']);
  }

  Future<AuthUser?> getCurrentUser() async {
    try {
      final token = await _storage.read(key: 'access_token');
      if (token == null) return null;
      final r = await _api.get('/auth/me');
      return AuthUser.fromJson(r.data['data']);
    } catch (_) { return null; }
  }

  Future<void> logout() async {
    try { await _api.post('/auth/logout'); } finally { await _storage.deleteAll(); }
  }
}
