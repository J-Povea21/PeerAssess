import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:loggy/loggy.dart';

import '../config/app_config.dart';
import '../services/session_service.dart';

/// An HTTP client that automatically:
/// 1. Attaches the Bearer token to every request.
/// 2. On a 401 response from a data endpoint, attempts a token refresh once.
/// 3. Retries the original request with the new token.
/// 4. If the refresh also fails, clears the session and calls [onSessionExpired].
///
/// Auth endpoints (under `/auth/`) are excluded from the retry logic — a 401
/// there means invalid credentials or an invalid token, not an expired session.
///
/// A Completer lock prevents multiple simultaneous 401s from each
/// triggering their own refresh call — only one refresh runs at a time.
class AuthenticatedClient extends http.BaseClient {
  final http.Client _inner;
  final SessionService _session;
  final Future<void> Function() onSessionExpired;

  Completer<void>? _refreshCompleter;

  AuthenticatedClient(this._inner, this._session,
      {required this.onSessionExpired});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    _attachToken(request, _session.accessToken);

    final response = await _inner.send(request);

    if (response.statusCode != 401) return response;

    // Auth endpoints return 401 for invalid credentials — not an expired
    // session. Skip the refresh logic entirely for these.
    if (_isAuthEndpoint(request.url)) return response;

    logInfo('AuthenticatedClient: 401 received, attempting token refresh');

    try {
      await _refreshTokens();
    } catch (_) {
      logWarning('AuthenticatedClient: Refresh failed, forcing logout');
      await _session.clearSession();
      await onSessionExpired();
      return response;
    }

    final retryRequest = _copyRequest(request);
    _attachToken(retryRequest, _session.accessToken);
    return _inner.send(retryRequest);
  }

  /// Returns true for endpoints where a 401 means something other than an
  /// expired token, so the refresh+retry flow should be skipped:
  /// - login/signup: wrong credentials
  /// - logout: token already invalid, we're clearing the session anyway
  /// - refresh-token: would cause an infinite loop
  ///
  /// verify-token is intentionally NOT excluded — a 401 there means the
  /// token expired and we should attempt a refresh.
  bool _isAuthEndpoint(Uri url) {
    final path = url.path;
    return path.endsWith('/login') ||
        path.endsWith('/logout') ||
        path.endsWith('/signup-direct') ||
        path.endsWith('/refresh-token');
  }

  /// Refreshes tokens. If a refresh is already in progress, waits for it
  /// instead of starting a new one (Completer lock).
  Future<void> _refreshTokens() async {
    if (_refreshCompleter != null) {
      logInfo('AuthenticatedClient: Refresh already in progress, waiting');
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<void>();

    try {
      final url = Uri.parse(
        '${AppConfig.robleBaseUrl}/auth/${AppConfig.robleToken}/refresh-token',
      );

      final response = await _inner.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': _session.refreshToken}),
      );

      if (response.statusCode != 201) {
        throw Exception('Refresh failed with status ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      await _session.updateTokens(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
      );

      logInfo('AuthenticatedClient: Token refreshed successfully');
      _refreshCompleter!.complete();
    } catch (e) {
      _refreshCompleter!.completeError(e);
      rethrow;
    } finally {
      _refreshCompleter = null;
    }
  }

  void _attachToken(http.BaseRequest request, String? token) {
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
  }

  /// Creates a copy of the original request so it can be retried.
  /// http.BaseRequest cannot be sent twice, so we must reconstruct it.
  http.BaseRequest _copyRequest(http.BaseRequest request) {
    final copy = http.Request(request.method, request.url);
    copy.headers.addAll(request.headers);
    if (request is http.Request) {
      copy.body = request.body;
    }
    return copy;
  }
}
