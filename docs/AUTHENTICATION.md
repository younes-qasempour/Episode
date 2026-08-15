# Episode Authentication & Security Architecture

This document describes Flutter client authentication, token lifecycle
management, and security protocols in Episode.

## Overview

Accounts in Episode are **optional** and **additive**. The app operates fully
offline without an account. Registering or logging in enables multi-device
cloud snapshot backup and synchronization.

## Token Lifecycle & Storage

1. **Storage**: Access and refresh tokens are stored securely via `AuthTokenStorage` (`SecureAuthTokenStorage` backed by `flutter_secure_storage`).
2. **Exclusions**: Tokens are NEVER written to `episode_media_items`, Episode
   native backup JSON files, sync snapshot payloads, or application logs.
   `otaku_log_access_token_v1`, `otaku_log_refresh_token_v1`, and
   `otaku_log_token_meta_v1` remain stable legacy-named secure-storage keys so
   existing sessions are not invalidated by the product rename.
3. **Rotation**: On HTTP `401 Unauthorized` responses, `ApiClient` executes a single-flight refresh operation via `POST /api/v1/auth/refresh`. When successful, new tokens are persisted atomically, and the original request is retried once.
4. **Session Expiry**: Unrecoverable refresh failures clear local tokens and transition the app to `sessionExpired` state without deleting local media library data.

## Auth Endpoints

- `POST /api/v1/auth/register` — Creates user, initial sync state (rev 0), registers client device, and returns token pair.
- `POST /api/v1/auth/login` — Validates credentials, registers/updates client device, and returns token pair.
- `POST /api/v1/auth/refresh` — Atomically revokes refresh session and returns new token pair.
- `POST /api/v1/auth/logout` — Idempotently revokes matching refresh session and clears local tokens.
- `POST /api/v1/auth/logout-all` — Revokes all sessions for current user across all devices.
- `GET /api/v1/users/me` — Fetches current user profile.
- `DELETE /api/v1/users/me` — Re-authenticates password and cascade-deletes cloud account. Local library remains preserved on device as an anonymous library.
