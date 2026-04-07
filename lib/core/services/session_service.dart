import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

class SessionService {
  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyUser = 'cached_user';

  String? _accessToken;
  String? _refreshToken;
  User? _cachedUser;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  User? get cachedUser => _cachedUser;

  /// Load tokens and cached user from SharedPreferences into memory.
  /// Call this once on app startup before anything else.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(_keyAccessToken);
    _refreshToken = prefs.getString(_keyRefreshToken);

    final userJson = prefs.getString(_keyUser);
    if (userJson != null) {
      _cachedUser = User.fromJson(jsonDecode(userJson));
    }
  }

  /// Persist tokens and user after a successful login.
  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required User user,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _cachedUser = user;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, accessToken);
    await prefs.setString(_keyRefreshToken, refreshToken);
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
  }

  /// Update tokens in memory and storage after a token refresh.
  Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, accessToken);
    await prefs.setString(_keyRefreshToken, refreshToken);
  }

  /// Clear all session data from memory and storage on logout.
  Future<void> clearSession() async {
    _accessToken = null;
    _refreshToken = null;
    _cachedUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyUser);
  }

  bool get hasSession => _accessToken != null;

  @visibleForTesting
  void setTestUser(User user) => _cachedUser = user;
}
