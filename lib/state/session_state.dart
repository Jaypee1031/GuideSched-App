import 'package:flutter/foundation.dart';

import '../services/api_client.dart';

/// Holds the logged-in user. Provided at the root of the widget tree.
class SessionState extends ChangeNotifier {
  final ApiClient _api = ApiClient.instance;

  Map<String, dynamic>? user;
  bool ready = false;

  bool get isLoggedIn => user != null && _api.token != null;
  String get role => (user?['role'] ?? '').toString();
  int get userId => int.tryParse('${user?['id'] ?? 0}') ?? 0;
  String get name => (user?['name'] ?? '').toString();
  String get firstName {
    final n = name.trim();
    return n.isEmpty ? '' : n.split(' ').first;
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Future<void> restore() async {
    _api.onUnauthorized = () {
      // Token expired — drop the session; the root widget shows the login screen.
      _forceLogout();
    };
    await _api.loadToken();
    if (_api.token != null) {
      try {
        final r = await _api.get('auth.php', query: {'action': 'me'});
        user = Map<String, dynamic>.from(r.map['user'] as Map);
      } on ApiException catch (e) {
        if (e.statusCode == 401) {
          await _api.saveToken(null);
        }
        // For network errors keep the token; the user can retry once online.
      }
    }
    ready = true;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final r = await _api.post('auth.php', query: {'action': 'login'}, body: {'email': email, 'password': password});
    await _api.saveToken(r.map['token'] as String);
    user = Map<String, dynamic>.from(r.map['user'] as Map);
    notifyListeners();
  }

  Future<String> register(Map<String, dynamic> data) async {
    final r = await _api.post('auth.php', query: {'action': 'register'}, body: data);
    return r.message;
  }

  Future<void> refreshUser() async {
    final r = await _api.get('auth.php', query: {'action': 'me'});
    user = Map<String, dynamic>.from(r.map['user'] as Map);
    notifyListeners();
  }

  Future<void> logout() async {
    await _api.saveToken(null);
    user = null;
    notifyListeners();
  }

  void _forceLogout() {
    _api.token = null;
    user = null;
    notifyListeners();
    _api.saveToken(null);
  }
}
