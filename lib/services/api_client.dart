import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/auth_models.dart';
import 'api_exceptions.dart';
import 'auth_token_storage.dart';

class ApiClient {
  final AppConfig config;
  final AuthTokenStorage tokenStorage;
  final http.Client _client;
  final Duration timeout;

  Completer<AuthTokens?>? _refreshCompleter;

  ApiClient({
    required this.config,
    required this.tokenStorage,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 20),
  }) : _client = httpClient ?? http.Client();

  Future<Map<String, String>> _buildHeaders({
    required bool requiresAuth,
    AuthTokens? overrideTokens,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final tokens = overrideTokens ?? await tokenStorage.loadTokens();
      if (tokens != null && tokens.accessToken.isNotEmpty) {
        headers['Authorization'] = '${tokens.tokenType} ${tokens.accessToken}';
      }
    }
    return headers;
  }

  Future<dynamic> request({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    bool requiresAuth = false,
    bool isRefreshAttempt = false,
    Duration? customTimeout,
  }) async {
    final baseUrl = config.apiV1BaseUrl;
    var uri = Uri.parse('$baseUrl$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    final headers = await _buildHeaders(requiresAuth: requiresAuth);
    final requestBody = body != null ? jsonEncode(body) : null;
    final effTimeout = customTimeout ?? timeout;

    http.Response response;
    try {
      final req = http.Request(method, uri)..headers.addAll(headers);
      if (requestBody != null) {
        req.body = requestBody;
      }
      final streamedResponse = await _client.send(req).timeout(effTimeout);
      response = await http.Response.fromStream(streamedResponse);
    } on TimeoutException {
      throw const RequestTimeoutException();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw const NetworkUnavailableException();
    }

    final requestId =
        response.headers['x-request-id'] ?? response.headers['X-Request-Id'];

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty || response.statusCode == 204) {
        return null;
      }
      return jsonDecode(response.body);
    }

    // Handle 401 & single-flight refresh retry
    if (response.statusCode == 401 &&
        requiresAuth &&
        !isRefreshAttempt &&
        !path.startsWith('/auth/')) {
      final newTokens = await _performSingleFlightRefresh();
      if (newTokens != null) {
        // Retry original request once with new token
        return request(
          method: method,
          path: path,
          body: body,
          queryParams: queryParams,
          requiresAuth: true,
          isRefreshAttempt: true,
          customTimeout: customTimeout,
        );
      } else {
        await tokenStorage.clearTokens();
        throw parseBackendError(response.statusCode, response.body,
            requestId: requestId);
      }
    }

    throw parseBackendError(response.statusCode, response.body,
        requestId: requestId);
  }

  Future<AuthTokens?> _performSingleFlightRefresh() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    final completer = Completer<AuthTokens?>();
    _refreshCompleter = completer;

    try {
      final currentTokens = await tokenStorage.loadTokens();
      if (currentTokens == null || currentTokens.refreshToken.isEmpty) {
        completer.complete(null);
        return null;
      }

      // We cannot call request() recursively here to prevent loops
      final baseUrl = config.apiV1BaseUrl;
      final uri = Uri.parse('$baseUrl/auth/refresh');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      final body = jsonEncode({
        'refreshToken': currentTokens.refreshToken,
        'clientDeviceId':
            '', // Backend extracts device from refresh session or client device ID if sent
      });

      final response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final newTokens = AuthTokens.fromMap(decoded);
        await tokenStorage.saveTokens(newTokens);
        completer.complete(newTokens);
        return newTokens;
      } else {
        await tokenStorage.clearTokens();
        completer.complete(null);
        return null;
      }
    } catch (_) {
      completer.complete(null);
      return null;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParams,
    bool requiresAuth = false,
    Duration? timeout,
  }) {
    return request(
      method: 'GET',
      path: path,
      queryParams: queryParams,
      requiresAuth: requiresAuth,
      customTimeout: timeout,
    );
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
    Duration? timeout,
  }) {
    return request(
      method: 'POST',
      path: path,
      body: body,
      requiresAuth: requiresAuth,
      customTimeout: timeout,
    );
  }

  Future<dynamic> delete(
    String path, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
    Duration? timeout,
  }) {
    return request(
      method: 'DELETE',
      path: path,
      body: body,
      requiresAuth: requiresAuth,
      customTimeout: timeout,
    );
  }
}
