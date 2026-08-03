import '../models/auth_models.dart';
import '../services/api_client.dart';
import '../services/auth_token_storage.dart';
import '../services/device_identity_service.dart';

class AuthRepository {
  final ApiClient apiClient;
  final AuthTokenStorage tokenStorage;
  final DeviceIdentityService deviceIdentityService;

  AuthRepository({
    required this.apiClient,
    required this.tokenStorage,
    required this.deviceIdentityService,
  });

  Future<AuthSessionResult> register({
    required String email,
    required String password,
  }) async {
    final deviceInfo = await deviceIdentityService.getDeviceInfo();
    final response = await apiClient.post(
      '/auth/register',
      body: {
        'email': email.trim(),
        'password': password,
        'device': {
          'clientDeviceId': deviceInfo['clientDeviceId'],
          'name': deviceInfo['name'],
          'platform': deviceInfo['platform'],
          'appVersion': deviceInfo['appVersion'],
        },
      },
    );

    final result = AuthSessionResult.fromMap(
      Map<String, dynamic>.from(response as Map),
    );
    await tokenStorage.saveTokens(result.tokens);
    return result;
  }

  Future<AuthSessionResult> login({
    required String email,
    required String password,
  }) async {
    final deviceInfo = await deviceIdentityService.getDeviceInfo();
    final response = await apiClient.post(
      '/auth/login',
      body: {
        'email': email.trim(),
        'password': password,
        'device': {
          'clientDeviceId': deviceInfo['clientDeviceId'],
          'name': deviceInfo['name'],
          'platform': deviceInfo['platform'],
          'appVersion': deviceInfo['appVersion'],
        },
      },
    );

    final result = AuthSessionResult.fromMap(
      Map<String, dynamic>.from(response as Map),
    );
    await tokenStorage.saveTokens(result.tokens);
    return result;
  }

  Future<AuthenticatedUser?> getCurrentUser() async {
    try {
      final response = await apiClient.get('/users/me', requiresAuth: true);
      if (response != null && response is Map) {
        return AuthenticatedUser.fromMap(Map<String, dynamic>.from(response));
      }
    } catch (_) {
      rethrow;
    }
    return null;
  }

  Future<void> logout() async {
    final tokens = await tokenStorage.loadTokens();
    if (tokens != null && tokens.refreshToken.isNotEmpty) {
      try {
        await apiClient.post(
          '/auth/logout',
          body: {'refreshToken': tokens.refreshToken},
          requiresAuth: false,
        );
      } catch (_) {
        // Idempotent logout: even if server call fails, clear local tokens
      }
    }
    await tokenStorage.clearTokens();
  }

  Future<void> logoutAll() async {
    try {
      await apiClient.post('/auth/logout-all', requiresAuth: true);
    } catch (_) {
      // Clear local tokens even if server call fails
    }
    await tokenStorage.clearTokens();
  }

  Future<void> deleteAccount({required String password}) async {
    await apiClient.delete(
      '/users/me',
      body: {'password': password},
      requiresAuth: true,
    );
    await tokenStorage.clearTokens();
  }

  Future<List<DeviceSummary>> getDevices() async {
    final response = await apiClient.get('/devices', requiresAuth: true);
    if (response is List) {
      return response
          .whereType<Map>()
          .map((item) => DeviceSummary.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    }
    return [];
  }

  Future<void> revokeDevice(String deviceId) async {
    await apiClient.delete('/devices/$deviceId', requiresAuth: true);
  }
}
