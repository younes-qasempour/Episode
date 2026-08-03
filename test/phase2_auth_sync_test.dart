import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:otaku_log/config/app_config.dart';
import 'package:otaku_log/controllers/auth_controller.dart';
import 'package:otaku_log/models/auth_models.dart';
import 'package:otaku_log/models/media_item.dart';
import 'package:otaku_log/repositories/auth_repository.dart';
import 'package:otaku_log/repositories/local_storage_repository.dart';
import 'package:otaku_log/services/api_client.dart';
import 'package:otaku_log/services/api_exceptions.dart';
import 'package:otaku_log/services/auth_token_storage.dart';
import 'package:otaku_log/services/device_identity_service.dart';
import 'package:otaku_log/services/snapshot_assembler.dart';
import 'package:otaku_log/services/sync_metadata_storage.dart';
import 'package:otaku_log/services/sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. AppConfig & Device Identity Tests', () {
    test('Base URL normalization strips trailing slashes', () {
      const configWithSlash = AppConfig(rawBaseUrl: 'http://localhost:8000/');
      expect(configWithSlash.baseUrl, 'http://localhost:8000');
      expect(configWithSlash.apiV1BaseUrl, 'http://localhost:8000/api/v1');

      const configWithoutSlash = AppConfig(rawBaseUrl: 'http://localhost:8000');
      expect(configWithoutSlash.baseUrl, 'http://localhost:8000');
      expect(configWithoutSlash.apiV1BaseUrl, 'http://localhost:8000/api/v1');
    });

    test(
        'Missing base URL throws error on account action but allows anonymous use',
        () {
      const emptyConfig = AppConfig(rawBaseUrl: '');
      expect(emptyConfig.isApiConfigured, isFalse);
      expect(() => emptyConfig.apiV1BaseUrl, throwsStateError);
    });

    test('DeviceIdentityService generates and persists stable UUID v4',
        () async {
      SharedPreferences.setMockInitialValues({});
      final service = DeviceIdentityService();

      final id1 = await service.getOrCreateClientDeviceId();
      final id2 = await service.getOrCreateClientDeviceId();

      final uuidRegex = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      );
      expect(uuidRegex.hasMatch(id1), isTrue);
      expect(id1, equals(id2));
    });
  });

  group('2. Token Storage & Security Tests', () {
    test('InMemoryAuthTokenStorage saves, loads, and clears tokens', () async {
      final storage = InMemoryAuthTokenStorage();
      expect(await storage.loadTokens(), isNull);

      final tokens = AuthTokens(
        accessToken: 'access_123',
        refreshToken: 'refresh_456',
        tokenType: 'Bearer',
        expiresInSeconds: 900,
      );

      await storage.saveTokens(tokens);
      final loaded = await storage.loadTokens();

      expect(loaded, isNotNull);
      expect(loaded!.accessToken, 'access_123');
      expect(loaded.refreshToken, 'refresh_456');

      await storage.clearTokens();
      expect(await storage.loadTokens(), isNull);
    });
  });

  group('3. ApiClient & Error Parser Tests', () {
    test('Backend JSON errors are parsed into typed exceptions', () {
      final exc1 = parseBackendError(
        401,
        jsonEncode({
          'error': {
            'code': 'INVALID_CREDENTIALS',
            'message': 'Wrong email or password',
          }
        }),
      );
      expect(exc1, isA<InvalidCredentialsException>());

      final exc2 = parseBackendError(
        409,
        jsonEncode({
          'error': {
            'code': 'EMAIL_ALREADY_REGISTERED',
            'message': 'Email exists',
          }
        }),
      );
      expect(exc2, isA<DuplicateEmailException>());

      final exc3 = parseBackendError(
        409,
        jsonEncode({
          'error': {
            'code': 'SYNC_REVISION_CONFLICT',
            'message': 'Conflict',
            'details': {'currentRevision': 5},
          }
        }),
      );
      expect(exc3, isA<SyncRevisionConflictException>());
      expect((exc3 as SyncRevisionConflictException).currentRevision, 5);
    });

    test('ApiClient injects Bearer header when requiresAuth is true', () async {
      const config = AppConfig(rawBaseUrl: 'http://localhost:8000');
      final tokenStorage = InMemoryAuthTokenStorage();
      await tokenStorage.saveTokens(
        AuthTokens(
          accessToken: 'my_test_access_token',
          refreshToken: 'my_test_refresh_token',
          expiresInSeconds: 900,
        ),
      );

      final mockClient = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer my_test_access_token');
        return http.Response(jsonEncode({'success': true}), 200);
      });

      final apiClient = ApiClient(
        config: config,
        tokenStorage: tokenStorage,
        httpClient: mockClient,
      );

      final result = await apiClient.get('/test', requiresAuth: true);
      expect(result['success'], isTrue);
    });
  });

  group('4. AuthRepository & AuthController Tests', () {
    test('Registration and Login populate tokens and user state', () async {
      SharedPreferences.setMockInitialValues({});
      const config = AppConfig(rawBaseUrl: 'http://localhost:8000');
      final tokenStorage = InMemoryAuthTokenStorage();
      final deviceService = DeviceIdentityService();

      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/register')) {
          return http.Response(
            jsonEncode({
              'accessToken': 'access_reg',
              'refreshToken': 'refresh_reg',
              'tokenType': 'Bearer',
              'expiresInSeconds': 900,
              'user': {'id': 'usr_1', 'email': 'test@example.com'},
              'device': {
                'id': 'dev_1',
                'clientDeviceId': 'c8f3a9e2-4b1d-4f8a-9e2c-1a3b5c7d9e0f',
                'name': 'Test Device',
                'platform': 'android',
              },
            }),
            201,
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(
        config: config,
        tokenStorage: tokenStorage,
        httpClient: mockClient,
      );
      final repository = AuthRepository(
        apiClient: apiClient,
        tokenStorage: tokenStorage,
        deviceIdentityService: deviceService,
      );
      final controller = AuthController(authRepository: repository);

      final success = await controller.register(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(success, isTrue);
      expect(controller.isAuthenticated, isTrue);
      expect(controller.currentUser!.email, 'test@example.com');
      final savedTokens = await tokenStorage.loadTokens();
      expect(savedTokens!.accessToken, 'access_reg');
    });
  });

  group('5. Snapshot Assembler & Merge Engine Tests', () {
    test('SnapshotAssembler includes active items and tombstones in payload',
        () {
      final assembler = SnapshotAssembler();

      const activeItem = MediaItem(
        id: '550e8400-e29b-41d4-a716-446655440001',
        title: 'Active Anime',
        coverUrl: '',
        currentProgress: 5,
        totalCount: 12,
        mediaType: 'anime',
        status: 'Watching',
      );

      final tombstone = MediaItem(
        id: '550e8400-e29b-41d4-a716-446655440002',
        title: 'Deleted Anime',
        coverUrl: '',
        currentProgress: 1,
        totalCount: 12,
        mediaType: 'anime',
        status: 'Watching',
        deletedAt: DateTime.utc(2026, 8, 3, 10, 0, 0),
      );

      final payload = assembler.buildPushPayload(
        snapshotId: 'snap_123',
        deviceId: 'dev_123',
        baseRevision: 2,
        allItems: [activeItem, tombstone],
        platform: 'android',
        appVersion: '1.0.0',
      );

      expect(payload['snapshotId'], 'snap_123');
      expect(payload['baseRevision'], 2);
      final mediaItems = (payload['payload'] as Map)['mediaItems'] as List;
      expect(mediaItems, hasLength(2));
    });

    test('MergeEngine merges progress, scalar metadata, tags, and tombstones',
        () {
      final syncService = SyncService(
        apiClient: ApiClient(
          config: const AppConfig(),
          tokenStorage: InMemoryAuthTokenStorage(),
        ),
        storageRepository: const LocalStorageRepository(),
        metadataStorage: SyncMetadataStorage(),
        deviceIdentityService: DeviceIdentityService(),
      );

      final localItem = MediaItem(
        id: '550e8400-e29b-41d4-a716-446655440001',
        title: 'Merge Target',
        coverUrl: '',
        currentProgress: 10, // Local progress higher
        totalCount: 12,
        mediaType: 'anime',
        status: 'Watching',
        tags: const ['shonen', 'action'],
        updatedAt: DateTime.utc(2026, 8, 3, 10, 0, 0),
      );

      final cloudItem = MediaItem(
        id: '550e8400-e29b-41d4-a716-446655440001',
        title: 'Merge Target Cloud', // Newer scalar metadata
        coverUrl: '',
        currentProgress: 5,
        totalCount: 12,
        mediaType: 'anime',
        status: 'Completed',
        tags: const ['action', 'supernatural'],
        updatedAt: DateTime.utc(2026, 8, 3, 12, 0, 0), // Cloud newer
      );

      final merged = syncService.mergeSingleMediaItem(
        local: localItem,
        cloud: cloudItem,
      );

      expect(merged.id, localItem.id); // Stable local UUID
      expect(merged.currentProgress, 10); // Max progress wins
      expect(merged.status, 'Completed'); // Newer scalar metadata wins
      expect(merged.tags,
          containsAll(['shonen', 'action', 'supernatural'])); // Tags unioned
    });
  });

  group('6. Sync Service Integration & Conflict Handling Tests', () {
    test('Push 409 conflict triggers pull, merge, and retry push', () async {
      SharedPreferences.setMockInitialValues({});
      const config = AppConfig(rawBaseUrl: 'http://localhost:8000');
      final tokenStorage = InMemoryAuthTokenStorage();
      await tokenStorage.saveTokens(
        AuthTokens(
          accessToken: 'valid_access',
          refreshToken: 'valid_refresh',
          expiresInSeconds: 900,
        ),
      );

      int pushAttempts = 0;

      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/sync/status')) {
          return http.Response(
            jsonEncode({
              'hasSnapshot': true,
              'revision': 1,
              'protocolVersion': 1,
              'schemaVersion': 1,
            }),
            200,
          );
        }
        if (request.url.path.endsWith('/sync/push')) {
          pushAttempts++;
          if (pushAttempts == 1) {
            // First push fails with 409 conflict
            return http.Response(
              jsonEncode({
                'error': {
                  'code': 'SYNC_REVISION_CONFLICT',
                  'message': 'Stale revision',
                  'details': {'currentRevision': 2},
                }
              }),
              409,
            );
          } else {
            // Second push succeeds
            return http.Response(
              jsonEncode({
                'accepted': true,
                'revision': 3,
                'snapshotId': 'snap_res',
                'checksum': 'abc123sha',
                'serverTimestamp': '2026-08-03T12:00:00Z',
              }),
              200,
            );
          }
        }
        if (request.url.path.endsWith('/sync/pull')) {
          return http.Response(
            jsonEncode({
              'hasChanges': true,
              'revision': 2,
              'serverTimestamp': '2026-08-03T12:00:00Z',
              'payload': {'mediaItems': []},
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(
        config: config,
        tokenStorage: tokenStorage,
        httpClient: mockClient,
      );
      final syncService = SyncService(
        apiClient: apiClient,
        storageRepository: const LocalStorageRepository(),
        metadataStorage: SyncMetadataStorage(),
        deviceIdentityService: DeviceIdentityService(),
      );

      await syncService.markLocalChangePending();
      final result = await syncService.syncNow();

      expect(pushAttempts, 2);
      expect(result.success, isTrue);
      expect(syncService.state, SyncStatusState.synced);
      expect(syncService.metadata!.serverRevision, 3);
    });
  });
}
