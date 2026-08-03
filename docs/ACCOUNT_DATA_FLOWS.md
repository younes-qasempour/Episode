# OtakuLog Account Data Flows & User Choices

This document explains user account transitions, anonymous-to-account migrations, and device switching flows.

## Anonymous App Startup

- New installations start in `anonymous` mode.
- Local items are created with client-generated UUID v4 IDs and stored under `otaku_log_media_items` (schema v2 envelope).

## Anonymous-to-Account Migration

When registering or logging in with local anonymous data:
1. **New Account (Cloud Empty)**: Local library is uploaded automatically as `baseRevision = 0`.
2. **Existing Account (Cloud Snapshot Present)**:
   - User is prompted with options:
     - **Merge (Recommended)**: Pulls cloud snapshot, creates local safety backup, merges locally, and pushes merged snapshot.
     - **Keep Offline**: Preserves local items and postpones sync binding.

## New Device Account Restore

Logging into an existing cloud account on a fresh installation:
1. Pulls latest cloud snapshot.
2. Validates snapshot structure.
3. Replaces empty local library atomically.
4. Renders restored library.

## Logout & Device Revocation

- Logging out revokes the refresh token on the server and clears local auth tokens.
- **Data Safety**: Local media items, tombstones, and local safety backups are NEVER deleted upon logout. The library remains accessible on the device.
- Account deletion cascade-deletes cloud snapshots on the server while preserving the local library on device as an offline library.
