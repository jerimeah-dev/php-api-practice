import 'dart:convert';
import 'package:dio/dio.dart';

class ApiClient {
  static final instance = ApiClient._();

  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'http://127.0.0.1:12345',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        contentType: 'application/json',
      ),
    );
  }

  late final Dio _dio;

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final res = await _dio.post(path, data: body);
    if (res.data is Map<String, dynamic>) return res.data;
    if (res.data is String) return jsonDecode(res.data) as Map<String, dynamic>;
    return {'status': 'error', 'message': 'Unexpected response: ${res.data.runtimeType}'};
  }
}
