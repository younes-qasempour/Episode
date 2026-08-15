import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:episode/config/app_config.dart';
import 'package:episode/controllers/auth_controller.dart';
import 'package:episode/models/auth_models.dart';
import 'package:episode/repositories/auth_repository.dart';
import 'package:episode/screens/profile_tab.dart';
import 'package:episode/services/api_client.dart';
import 'package:episode/services/auth_token_storage.dart';
import 'package:episode/services/device_identity_service.dart';
import 'package:episode/theme/app_theme.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('BUG-003: ProfileTab Account Deletion Feedback Tests', () {
    const config = AppConfig(rawBaseUrl: 'http://localhost:8000');

    testWidgets('Displays success SnackBar on successful account deletion', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final tokenStorage = InMemoryAuthTokenStorage();
      await tokenStorage.saveTokens(
        AuthTokens(
          accessToken: 'mock_access',
          refreshToken: 'mock_refresh',
          expiresInSeconds: 900,
        ),
      );

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/users/me') && request.method == 'DELETE') {
          return http.Response(
            jsonEncode({'success': true}),
            200,
          );
        }
        if (request.url.path.contains('/users/me') && request.method == 'GET') {
          return http.Response(
            jsonEncode({'id': 'usr_1', 'email': 'tester@example.com'}),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(config: config, tokenStorage: tokenStorage, httpClient: mockClient);
      final authRepo = AuthRepository(
        apiClient: apiClient,
        tokenStorage: tokenStorage,
        deviceIdentityService: DeviceIdentityService(),
      );
      final authController = AuthController(authRepository: authRepo);
      await authController.restoreSession();
      expect(authController.isAuthenticated, isTrue);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ListenableBuilder(
            listenable: authController,
            builder: (context, _) => ProfileTab(
              currentThemeMode: ThemeMode.light,
              onThemeModeChanged: (_) {},
              authController: authController,
              onClearLibrary: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll until Delete Account tile is visible
      final deleteTile = find.widgetWithText(ListTile, 'Delete Account');
      await tester.scrollUntilVisible(
        deleteTile,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(deleteTile, findsOneWidget);
      await tester.tap(deleteTile);
      await tester.pumpAndSettle();

      // Enter password in dialog
      final passwordField = find.byType(TextFormField);
      expect(passwordField, findsOneWidget);
      await tester.enterText(passwordField, 'Secret123!');
      await tester.pumpAndSettle();

      // Tap confirm Delete Account
      final confirmDelete = find.widgetWithText(FilledButton, 'Delete Account');
      expect(confirmDelete, findsOneWidget);
      await tester.tap(confirmDelete);
      await tester.pumpAndSettle();

      // Success SnackBar must be displayed
      expect(find.text('Account and cloud data permanently deleted.'), findsOneWidget);
    });

    testWidgets('Displays error SnackBar on failed account deletion without success message', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final tokenStorage = InMemoryAuthTokenStorage();
      await tokenStorage.saveTokens(
        AuthTokens(
          accessToken: 'mock_access',
          refreshToken: 'mock_refresh',
          expiresInSeconds: 900,
        ),
      );

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/users/me') && request.method == 'DELETE') {
          return http.Response(
            jsonEncode({
              'error': {'code': 'INVALID_PASSWORD', 'message': 'Incorrect password provided.'}
            }),
            400,
          );
        }
        if (request.url.path.contains('/users/me') && request.method == 'GET') {
          return http.Response(
            jsonEncode({'id': 'usr_1', 'email': 'tester@example.com'}),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(config: config, tokenStorage: tokenStorage, httpClient: mockClient);
      final authRepo = AuthRepository(
        apiClient: apiClient,
        tokenStorage: tokenStorage,
        deviceIdentityService: DeviceIdentityService(),
      );
      final authController = AuthController(authRepository: authRepo);
      await authController.restoreSession();
      expect(authController.isAuthenticated, isTrue);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ListenableBuilder(
            listenable: authController,
            builder: (context, _) => ProfileTab(
              currentThemeMode: ThemeMode.light,
              onThemeModeChanged: (_) {},
              authController: authController,
              onClearLibrary: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final deleteTile = find.widgetWithText(ListTile, 'Delete Account');
      await tester.scrollUntilVisible(
        deleteTile,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(deleteTile, findsOneWidget);
      await tester.tap(deleteTile);
      await tester.pumpAndSettle();

      final passwordField = find.byType(TextFormField);
      await tester.enterText(passwordField, 'WrongPass');
      await tester.pumpAndSettle();

      final confirmDelete = find.widgetWithText(FilledButton, 'Delete Account');
      await tester.tap(confirmDelete);
      await tester.pumpAndSettle();

      // Error SnackBar must be displayed, success message must NOT be displayed
      expect(find.text('Incorrect password provided.'), findsOneWidget);
      expect(find.text('Account and cloud data permanently deleted.'), findsNothing);
    });
  });
}
