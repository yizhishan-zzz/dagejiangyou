import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  static const _storage = FlutterSecureStorage();
  static const _defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8080/api/v1',
  );
  String _baseUrl = _defaultBaseUrl;
  String _userId = '';
  String _accessToken = '';
  String _refreshToken = '';
  double _latitude = 31.2304;
  double _longitude = 121.4737;
  bool _isDarkMode = false;

  String get baseUrl => _baseUrl;
  String get sanitizedBaseUrl => _baseUrl.endsWith('/')
      ? _baseUrl.substring(0, _baseUrl.length - 1)
      : _baseUrl;
  String get userId => _userId;
  String get accessToken => _accessToken;
  String get refreshToken => _refreshToken;
  bool get isDarkMode => _isDarkMode;
  double get latitude => _latitude;
  double get longitude => _longitude;
  bool get isConfigured => _userId.trim().isNotEmpty;
  bool get isLoggedIn =>
      _userId.trim().isNotEmpty && _accessToken.trim().isNotEmpty;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString('baseUrl') ?? _baseUrl;
    _latitude = prefs.getDouble('latitude') ?? _latitude;
    _longitude = prefs.getDouble('longitude') ?? _longitude;
    _userId = await _readCredential(prefs, 'userId') ?? '';
    _accessToken = await _readCredential(prefs, 'accessToken') ?? '';
    _refreshToken = await _readCredential(prefs, 'refreshToken') ?? '';
    _isDarkMode = prefs.getBool('darkMode') ?? false;
    notifyListeners();
  }

  Future<void> saveConnection({
    required String baseUrl,
    required String userId,
    required double latitude,
    required double longitude,
  }) async {
    _baseUrl = baseUrl.trim().isEmpty ? _baseUrl : baseUrl.trim();
    _userId = userId.trim();
    _latitude = latitude;
    _longitude = longitude;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('baseUrl', _baseUrl);
    await prefs.setDouble('latitude', _latitude);
    await prefs.setDouble('longitude', _longitude);
    if (_userId.isEmpty) {
      await clearSession();
    }
    notifyListeners();
  }

  Future<void> saveLocation({
    required double latitude,
    required double longitude,
  }) async {
    _latitude = latitude;
    _longitude = longitude;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('latitude', latitude);
    await prefs.setDouble('longitude', longitude);
    notifyListeners();
  }

  Future<void> saveSession(
    String userId, {
    required String accessToken,
    required String refreshToken,
  }) async {
    _userId = userId.trim();
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    final prefs = await SharedPreferences.getInstance();
    await _writeCredential(prefs, 'userId', _userId);
    await _writeCredential(prefs, 'accessToken', _accessToken);
    await _writeCredential(prefs, 'refreshToken', _refreshToken);
    notifyListeners();
  }

  Future<void> clearSession() async {
    _userId = '';
    _accessToken = '';
    _refreshToken = '';
    final prefs = await SharedPreferences.getInstance();
    await _deleteCredential(prefs, 'userId');
    await _deleteCredential(prefs, 'accessToken');
    await _deleteCredential(prefs, 'refreshToken');
    notifyListeners();
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    final prefs = await SharedPreferences.getInstance();
    await _writeCredential(prefs, 'accessToken', accessToken);
    await _writeCredential(prefs, 'refreshToken', refreshToken);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
    notifyListeners();
  }

  Future<String?> _readCredential(SharedPreferences prefs, String key) async {
    if (kIsWeb) {
      return prefs.getString(key);
    }
    try {
      return await _storage.read(key: key) ?? prefs.getString(key);
    } catch (_) {
      // Web secure-storage implementations can be unavailable in restricted
      // contexts; keep the app usable with the platform preferences store.
      return prefs.getString(key);
    }
  }

  Future<void> _writeCredential(
    SharedPreferences prefs,
    String key,
    String value,
  ) async {
    if (kIsWeb) {
      await prefs.setString(key, value);
      return;
    }
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      await prefs.setString(key, value);
    }
  }

  Future<void> _deleteCredential(SharedPreferences prefs, String key) async {
    if (kIsWeb) {
      await prefs.remove(key);
      return;
    }
    try {
      await _storage.delete(key: key);
    } catch (_) {
      // The fallback store is cleared below as well.
    }
    await prefs.remove(key);
  }
}
