# Episode Flutter Backend Setup & Configuration Guide

This document describes how to configure the Episode Flutter client to connect
to its companion backend. The repository/deployment slug
`otakulog-backend` is retained as a stable legacy identifier and is not
user-facing product copy.

## Compile-Time Configuration

The backend API URL is configured at compile/run time using
`--dart-define=EPISODE_API_BASE_URL=...`. `AppConfig` ignores the former
`OTAKULOG_API_BASE_URL` name.

### 1. Local Development (FastAPI on localhost:8000)

```bash
# Android Emulator
flutter run --dart-define=EPISODE_API_BASE_URL=http://10.0.2.2:8000

# Physical Android Device over LAN
flutter run --dart-define=EPISODE_API_BASE_URL=http://192.168.1.50:8000

# Flutter Web / Desktop
flutter run -d chrome --dart-define=EPISODE_API_BASE_URL=http://localhost:8000

# Windows Desktop
flutter run -d windows --dart-define=EPISODE_API_BASE_URL=http://localhost:8000
```

### 2. Production Deployment

Production deployments require HTTPS:

```bash
flutter build apk --release \
  --dart-define=EPISODE_API_BASE_URL=https://api.example.com
```

### Production endpoint note

Replace `https://api.example.com` with the owner-approved HTTPS deployment.
If an existing deployment still uses an `otakulog-*` slug or hostname, treat
that value as a stable legacy deployment identifier rather than product copy.

## CORS Expectations for Web

When running Flutter Web against the FastAPI backend, ensure the backend
includes CORS headers allowing the web origin (for example,
`http://localhost:5000` or the production domain).
