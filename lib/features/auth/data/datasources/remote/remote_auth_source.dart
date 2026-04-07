import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:loggy/loggy.dart';

import '../../../../../core/config/app_config.dart';
import '../../../../../core/services/session_service.dart';
import '../../../../../core/models/user.dart';
import '../i_auth_source.dart';

class RemoteAuthSource implements IAuthSource {
  final http.Client httpClient;
  final SessionService session;

  RemoteAuthSource(this.httpClient, this.session);

  String get _base =>
      '${AppConfig.robleBaseUrl}/auth/${AppConfig.robleToken}';

  @override
  Future<User?> login(String email, String password) async {
    logInfo('RemoteAuthSource: Logging in $email');

    final response = await httpClient.post(
      Uri.parse('$_base/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final user = User.fromJson(data['user'] as Map<String, dynamic>);

      await session.saveSession(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
        user: user,
      );

      logInfo('RemoteAuthSource: Login successful — ${user.name}');
      return user;
    }

    final error = jsonDecode(response.body);
    logWarning('RemoteAuthSource: Login failed — ${error['message']}');
    return null;
  }

  @override
  Future<void> logout() async {
    logInfo('RemoteAuthSource: Logging out');

    await httpClient.post(
      Uri.parse('$_base/logout'),
      headers: {'Content-Type': 'application/json'},
    );

    await session.clearSession();
    logInfo('RemoteAuthSource: Session cleared');
  }

  @override
  Future<User?> getCurrentUser() async {
    if (!session.hasSession) {
      logInfo('RemoteAuthSource: No session found');
      return null;
    }

    logInfo('RemoteAuthSource: Verifying token');

    final response = await httpClient.get(
      Uri.parse('$_base/verify-token'),
    );

    if (response.statusCode == 200) {
      logInfo('RemoteAuthSource: Token valid, restoring session');
      return session.cachedUser;
    }

    logWarning('RemoteAuthSource: Token invalid, clearing session');
    await session.clearSession();
    return null;
  }

}
