import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _storage = FlutterSecureStorage();
const _baseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'https://leadbridge-api.onrender.com/api',
);

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));
    _dio.interceptors.add(_AuthInterceptor(_dio));
  }

  Future<Response> get(String path, {Map<String, dynamic>? params}) =>
      _dio.get(path, queryParameters: params);
  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);
  Future<Response> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);
  Future<Response> delete(String path) => _dio.delete(path);
}

class _AuthInterceptor extends Interceptor {
  final Dio _dio;
  _AuthInterceptor(this._dio);

  @override
  Future<void> onRequest(options, handler) async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  Future<void> onError(err, handler) async {
    if (err.response?.statusCode == 401) {
      try {
        final refresh = await _storage.read(key: 'refresh_token');
        if (refresh == null) { await _storage.deleteAll(); return handler.reject(err); }
        final r = await Dio().post('$_baseUrl/auth/refresh', data: {'refreshToken': refresh});
        final token = r.data['data']['accessToken'];
        await _storage.write(key: 'access_token', value: token);
        err.requestOptions.headers['Authorization'] = 'Bearer $token';
        return handler.resolve(await _dio.fetch(err.requestOptions));
      } catch (_) { await _storage.deleteAll(); return handler.reject(err); }
    }
    handler.next(err);
  }
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
