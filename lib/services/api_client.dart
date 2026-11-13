import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

/// Decoded `{success, message, data}` reply from the website API.
class ApiResult {
  final String message;
  final dynamic data;
  ApiResult(this.message, this.data);

  Map<String, dynamic> get map => data is Map ? Map<String, dynamic>.from(data as Map) : <String, dynamic>{};
  List<dynamic> get list => data is List ? data as List : <dynamic>[];
}

/// Thin HTTP wrapper for `api/v2/*`. Endpoint = file name such as `auth.php`.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const _tokenKey = 'auth_token';
  String? token;

  /// Called when the server answers 401 (expired/invalid token).
  void Function()? onUnauthorized;

  Future<void> loadToken() async {
    final p = await SharedPreferences.getInstance();
    token = p.getString(_tokenKey);
  }

  Future<void> saveToken(String? value) async {
    token = value;
    final p = await SharedPreferences.getInstance();
    if (value == null) {
      await p.remove(_tokenKey);
    } else {
      await p.setString(_tokenKey, value);
    }
  }

  Uri _uri(String endpoint, Map<String, dynamic>? query) {
    final q = <String, String>{};
    query?.forEach((k, v) {
      if (v != null && '$v'.isNotEmpty) q[k] = '$v';
    });
    final base = '${AppConfig.apiBaseUrl}/$endpoint';
    final uri = Uri.parse(base);
    return q.isEmpty ? uri : uri.replace(queryParameters: {...uri.queryParameters, ...q});
  }

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json; charset=UTF-8',
        if (token != null) 'Authorization': 'Bearer $token',
        if (token != null) 'X-Auth-Token': token!,
      };

  Future<ApiResult> get(String endpoint, {Map<String, dynamic>? query}) =>
      _send('GET', endpoint, query: query);

  Future<ApiResult> post(String endpoint, {Map<String, dynamic>? query, Map<String, dynamic>? body}) =>
      _send('POST', endpoint, query: query, body: body);

  Future<ApiResult> patch(String endpoint, {Map<String, dynamic>? query, Map<String, dynamic>? body}) =>
      _send('PATCH', endpoint, query: query, body: body);

  Future<ApiResult> delete(String endpoint, {Map<String, dynamic>? query, Map<String, dynamic>? body}) =>
      _send('DELETE', endpoint, query: query, body: body);

  Future<ApiResult> _send(String method, String endpoint,
      {Map<String, dynamic>? query, Map<String, dynamic>? body}) async {
    final uri = _uri(endpoint, query);
    http.Response res;
    try {
      final req = http.Request(method, uri)..headers.addAll(_headers);
      if (body != null && method != 'GET') req.body = jsonEncode(body);
      final streamed = await req.send().timeout(const Duration(seconds: 25));
      res = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw ApiException('The server took too long to respond. Check your connection and server address.');
    } catch (e) {
      throw ApiException(
          'Cannot reach the server (${AppConfig.address}). Make sure XAMPP is running and your phone is on the same Wi-Fi.');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      throw ApiException('Unexpected reply from the server (HTTP ${res.statusCode}).', statusCode: res.statusCode);
    }
    if (decoded is! Map) {
      throw ApiException('Unexpected reply from the server.', statusCode: res.statusCode);
    }
    final ok = decoded['success'] == true;
    final message = (decoded['message'] ?? '').toString();
    if (res.statusCode == 401 && token != null) {
      onUnauthorized?.call();
    }
    if (!ok) {
      throw ApiException(message.isEmpty ? 'Request failed (HTTP ${res.statusCode}).' : message,
          statusCode: res.statusCode);
    }
    return ApiResult(message, decoded['data']);
  }
}
