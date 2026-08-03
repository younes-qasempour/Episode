# OtakuLog Flutter Backend Setup & Configuration Guide

This document describes how to configure the Flutter client to connect to `otakulog-backend`.

## Compile-Time Configuration

The backend API URL is configured at compile/run time using `--dart-define=OTAKULOG_API_BASE_URL=...`.

### 1. Local Development (FastAPI on localhost:8000)

```bash
# Android Emulator
flutter run --dart-define=OTAKULOG_API_BASE_URL=http://10.0.2.2:8000

# Physical Android Device over LAN
flutter run --dart-define=OTAKULOG_API_BASE_URL=http://192.168.1.50:8000

# Flutter Web / Desktop
flutter run -d chrome --dart-define=OTAKULOG_API_BASE_URL=http://localhost:8000
```

### 2. Production Deployment

Production deployments require HTTPS:

```bash
flutter build apk --release --dart-define=OTAKULOG_API_BASE_URL=https://api.otakulog.app
```

## CORS Expectations for Web

When running Flutter Web against a FastAPI backend, ensure `otakulog-backend` includes CORS headers allowing the web origin (e.g. `http://localhost:5000` or production domain).
