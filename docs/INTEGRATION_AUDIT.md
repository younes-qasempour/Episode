# INTEGRATION_AUDIT.md

## Overview
This document provides a comprehensive integration audit between `OtakuLog-mobile` (Flutter Frontend) and `otakulog-backend` (FastAPI Backend).

## Endpoint & Contract Inventory

| ID | Feature | Frontend Call | Backend Route | Method | Request Model | Response Model | Auth | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| INT-01 | Register | `AuthRepository.register` | `/api/v1/auth/register` | POST | `RegisterRequest` | `TokenResponse` | No | Connected |
| INT-02 | Login | `AuthRepository.login` | `/api/v1/auth/login` | POST | `LoginRequest` | `TokenResponse` | No | Connected |
| INT-03 | Token Refresh | `ApiClient._performSingleFlightRefresh` | `/api/v1/auth/refresh` | POST | `RefreshRequest` | `TokenResponse` | No | Fixed |
| INT-04 | Logout | `AuthRepository.logout` | `/api/v1/auth/logout` | POST | `LogoutRequest` | 204 No Content | No | Connected |
| INT-05 | Logout All | `AuthRepository.logoutAll` | `/api/v1/auth/logout-all` | POST | None | 204 No Content | Yes | Connected |
| INT-06 | Current User | `AuthRepository.getCurrentUser` | `/api/v1/users/me` | GET | None | `CurrentUserResponse` | Yes | Connected |
| INT-07 | Delete Account | `AuthRepository.deleteAccount` | `/api/v1/users/me` | DELETE | `DeleteAccountRequest` | 204 No Content | Yes | Connected |
| INT-08 | List Devices | `AuthRepository.getDevices` | `/api/v1/devices` | GET | None | `list[DeviceSummary]` | Yes | Connected |
| INT-09 | Revoke Device | `AuthRepository.revokeDevice` | `/api/v1/devices/{id}` | DELETE | None | 204 No Content | Yes | Connected |
| INT-10 | Sync Status | `SyncService._executeSyncProcess` | `/api/v1/sync/status` | GET | None | `SyncStatusResponse` | Yes | Connected |
| INT-11 | Pull Snapshot | `SyncService._pullAndReplace` | `/api/v1/sync/pull` | GET | `knownRevision` | `SyncPullResponse` | Yes | Connected |
| INT-12 | Push Snapshot | `SyncService._pushSnapshot` | `/api/v1/sync/push` | POST | `SyncPushRequest` | `SyncPushResponse` | Yes | Connected |
| INT-13 | Health Check | N/A (System) | `/health` | GET | None | `{"status":"ok"}` | No | Backend Only |

## Confirmed Problems & Fixes

| ID | Feature | Frontend | Backend | Problem | Severity | Fix | Status |
| -- | ------- | -------- | ------- | ------- | -------- | --- | ------ |
| PRB-01 | Token Refresh | `ApiClient._performSingleFlightRefresh` | `/api/v1/auth/refresh` | `clientDeviceId` was sent as `''` instead of a valid UUID v4, triggering 422 validation errors on FastAPI. | Critical | Injected `DeviceIdentityService` into `ApiClient` to pass the valid UUID. | Fixed |
| PRB-02 | CORS Preflight | `ApiClient` | `app/main.py` | `allow_headers` in FastAPI `CORSMiddleware` lacked `"Accept"` and `"x-request-id"`, breaking web browser CORS preflight. | High | Added `"Accept"` and `"x-request-id"` to `allow_headers` in `app/main.py`. | Fixed |
| PRB-03 | Android Native Network | `AndroidManifest.xml` | N/A | Missing `<uses-permission android:name="android.permission.INTERNET"/>` and cleartext HTTP setting. | High | Added `INTERNET` permission to main manifest and `android:usesCleartextTraffic="true"` to debug manifest. | Fixed |
| PRB-04 | Environment Config | `AppConfig` | `.env.example` | Missing local `.env` configuration for backend integration testing. | Medium | Created `.env` file in `otakulog-backend` based on `.env.example`. | Fixed |

## Android Native Build Audit (OTAKU-001)
- **Debug APK Build**: **SUCCESS** (`build/app/outputs/flutter-apk/app-debug.apk`).
- **Profile APK Build**: **SUCCESS** (`build/app/outputs/flutter-apk/app-profile.apk`, 72.6MB).
- **Release APK Build**: Release engine artifact download from Google Storage (`arm64_v8a_release`) is subject to TLS/network restrictions without a proxy configured.
- **Cleartext Traffic Policy**: `android:usesCleartextTraffic="true"` is restricted exclusively to `android/app/src/debug/AndroidManifest.xml`. Release manifest enforces HTTPS.

## Model & Serialization Audit
- All model keys use camelCase naming via FastAPI's `CamelModel` / `ForwardCompatibleCamelModel`.
- ISO-8601 UTC timestamps are enforced on both sides.
- Enum values (`anime`, `manga`, `series`, `movie`) match between frontend and backend.
- Error payloads are standardized to `{"error": {"code": "...", "message": "...", "details": {}}}`.
