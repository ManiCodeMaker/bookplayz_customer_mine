import 'dart:convert';
import 'dart:io';
import 'package:bookplayz/api/api_constants.dart';
import 'package:http/http.dart' as http;

import 'session_manager.dart';

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  static const Duration _timeout = Duration(seconds: 60);

  static String? _token;

  void setToken(String token) => _token = token;
  void clearToken()           => _token = null;
  bool get hasToken           => _token != null;

  // ── Headers ──────────────────────────────────────────────────────────────

  Map<String, String> _authHeaders({bool isJson = true}) {
    return {
      if (isJson) HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.acceptHeader: 'application/json',
      if (_token != null) HttpHeaders.authorizationHeader: 'Bearer $_token',
    };
  }

  // ── Public methods ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> get(String url) async {
    final res = await http
        .get(Uri.parse(url), headers: _authHeaders(isJson: false))
        .timeout(_timeout);
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> post(String url, Map<String, dynamic> body) async {
    final res = await http
        .post(Uri.parse(url), headers: _authHeaders(), body: jsonEncode(body))
        .timeout(_timeout);
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> put(String url, Map<String, dynamic> body) async {
    final res = await http
        .put(Uri.parse(url), headers: _authHeaders(), body: jsonEncode(body))
        .timeout(_timeout);
    return _handleResponse(res);
  }

  Future<Map<String, dynamic>> delete(String url) async {
    final res = await http
        .delete(Uri.parse(url), headers: _authHeaders(isJson: false))
        .timeout(_timeout);
    return _handleResponse(res);
  }

  Future<String?> refreshAccessToken(String refreshToken) async {
    final res = await http
        .post(
          Uri.parse(AuthApi.refreshTokenUrl),
          headers: _authHeaders(),
          body: jsonEncode({'refreshToken': refreshToken}),
        )
        .timeout(_timeout);
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded['data']?['accessToken'] as String?;
    }
    return null;
  }

  // ── Private ───────────────────────────────────────────────────────────────

  Map<String, dynamic> _handleResponse(http.Response res) {
    if (res.statusCode == 401) {
      SessionManager.instance.clearSession();
      throw ApiException(
        message: 'Session expired. Please login again.',
        statusCode: 401,
        body: {},
      );
    }
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) return decoded;
    throw ApiException(
      message: decoded['message'] as String? ?? 'Request failed (${res.statusCode})',
      statusCode: res.statusCode,
      body: decoded,
    );
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  final Map<String, dynamic> body;
  const ApiException({required this.message, required this.statusCode, required this.body});

  @override
  String toString() => 'ApiException($statusCode): $message';
}