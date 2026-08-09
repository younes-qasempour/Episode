class AppConfig {
  static const String _envBaseUrl = String.fromEnvironment(
    'EPISODE_API_BASE_URL',
    defaultValue: '',
  );

  final String rawBaseUrl;

  const AppConfig({this.rawBaseUrl = _envBaseUrl});

  bool get isApiConfigured {
    final trimmed = rawBaseUrl.trim();
    return trimmed.isNotEmpty;
  }

  String get baseUrl {
    final trimmed = rawBaseUrl.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  String get apiV1BaseUrl {
    if (!isApiConfigured) {
      throw StateError(
        'EPISODE_API_BASE_URL is not configured. Account and sync features require '
        '--dart-define=EPISODE_API_BASE_URL=http://<host>:<port>',
      );
    }
    final base = baseUrl;
    if (base.endsWith('/api/v1')) {
      return base;
    }
    return '$base/api/v1';
  }
}
