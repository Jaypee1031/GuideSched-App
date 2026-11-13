import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

/// Where the app finds the GuideSched website API.
///
/// The user only has to type the server address (e.g. `192.168.1.5`) in the
/// "Server settings" sheet on the login screen. Everything else is derived.
class AppConfig {
  static const String sitePath = 'APPOINTMENT%20IN%20GUIDANCE';
  static const String _prefsKey = 'server_address';

  static String _stored = '';

  /// Default address when nothing has been saved yet.
  static String get defaultAddress {
    if (kIsWeb) {
      // When the app is served from the same XAMPP, reuse that host.
      final host = Uri.base.host;
      return host.isEmpty ? 'localhost' : host;
    }
    return '10.0.2.2'; // Android emulator -> your PC. Change it for a real phone.
  }

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _stored = p.getString(_prefsKey) ?? '';
  }

  static String get address => _stored.isEmpty ? defaultAddress : _stored;

  static Future<void> saveAddress(String value) async {
    _stored = value.trim();
    final p = await SharedPreferences.getInstance();
    if (_stored.isEmpty) {
      await p.remove(_prefsKey);
    } else {
      await p.setString(_prefsKey, _stored);
    }
  }

  /// `192.168.1.5`, `192.168.1.5:8080`, or a full URL such as `https://school.example/APPOINTMENT%20IN%20GUIDANCE`.
  static String get siteBaseUrl {
    var a = address.trim();
    if (a.endsWith('/')) a = a.substring(0, a.length - 1);
    if (a.startsWith('http://') || a.startsWith('https://')) {
      return a.contains('/api/v2') ? a.substring(0, a.indexOf('/api/v2')) : (Uri.parse(a).path.isEmpty || Uri.parse(a).path == '/' ? '$a/$sitePath' : a);
    }
    return 'http://$a/$sitePath';
  }

  static String get apiBaseUrl => '$siteBaseUrl/api/v2';

  /// URL of the website itself (used for uploads such as profile pictures).
  static String assetUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) return '';
    if (relativePath.startsWith('http')) return relativePath;
    return '$siteBaseUrl/$relativePath';
  }
}
