enum AuthState {
  unknown,
  anonymous,
  authenticated,
  authenticatedOffline,
  refreshing,
  sessionExpired,
}

class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresInSeconds;
  final DateTime savedAt;

  AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'Bearer',
    required this.expiresInSeconds,
    DateTime? savedAt,
  }) : savedAt = (savedAt ?? DateTime.now()).toUtc();

  bool get isExpired {
    final now = DateTime.now().toUtc();
    final expireTime = savedAt.add(Duration(seconds: expiresInSeconds - 30));
    return now.isAfter(expireTime);
  }

  Map<String, dynamic> toMap() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'tokenType': tokenType,
      'expiresInSeconds': expiresInSeconds,
      'savedAt': savedAt.toUtc().toIso8601String(),
    };
  }

  factory AuthTokens.fromMap(Map<String, dynamic> map) {
    return AuthTokens(
      accessToken: map['accessToken']?.toString() ?? '',
      refreshToken: map['refreshToken']?.toString() ?? '',
      tokenType: map['tokenType']?.toString() ?? 'Bearer',
      expiresInSeconds: (map['expiresInSeconds'] as num?)?.toInt() ?? 900,
      savedAt: map['savedAt'] != null
          ? DateTime.tryParse(map['savedAt'].toString())?.toUtc()
          : null,
    );
  }
}

class AuthenticatedUser {
  final String id;
  final String email;
  final DateTime? createdAt;

  const AuthenticatedUser({
    required this.id,
    required this.email,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'createdAt': createdAt?.toUtc().toIso8601String(),
    };
  }

  factory AuthenticatedUser.fromMap(Map<String, dynamic> map) {
    return AuthenticatedUser(
      id: map['id']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString())?.toUtc()
          : null,
    );
  }
}

class TokenDeviceView {
  final String id;
  final String clientDeviceId;
  final String name;
  final String platform;

  const TokenDeviceView({
    required this.id,
    required this.clientDeviceId,
    required this.name,
    required this.platform,
  });

  factory TokenDeviceView.fromMap(Map<String, dynamic> map) {
    return TokenDeviceView(
      id: map['id']?.toString() ?? '',
      clientDeviceId: map['clientDeviceId']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      platform: map['platform']?.toString() ?? '',
    );
  }
}

class DeviceSummary {
  final String id;
  final String clientDeviceId;
  final String name;
  final String platform;
  final String? appVersion;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastSeenAt;
  final DateTime? revokedAt;
  final bool isActive;

  const DeviceSummary({
    required this.id,
    required this.clientDeviceId,
    required this.name,
    required this.platform,
    this.appVersion,
    required this.createdAt,
    required this.updatedAt,
    required this.lastSeenAt,
    this.revokedAt,
    required this.isActive,
  });

  factory DeviceSummary.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now().toUtc();
    final revoked = map['revokedAt'] != null
        ? DateTime.tryParse(map['revokedAt'].toString())?.toUtc()
        : null;
    final isActiveExplicit = map['isActive'] as bool?;

    return DeviceSummary(
      id: map['id']?.toString() ?? '',
      clientDeviceId: map['clientDeviceId']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      platform: map['platform']?.toString() ?? '',
      appVersion: map['appVersion']?.toString(),
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '')?.toUtc() ?? now,
      updatedAt:
          DateTime.tryParse(map['updatedAt']?.toString() ?? '')?.toUtc() ?? now,
      lastSeenAt:
          DateTime.tryParse(map['lastSeenAt']?.toString() ?? '')?.toUtc() ??
              now,
      revokedAt: revoked,
      isActive: isActiveExplicit ?? (revoked == null),
    );
  }
}

class AuthSessionResult {
  final AuthTokens tokens;
  final AuthenticatedUser user;
  final TokenDeviceView device;

  const AuthSessionResult({
    required this.tokens,
    required this.user,
    required this.device,
  });

  factory AuthSessionResult.fromMap(Map<String, dynamic> map) {
    return AuthSessionResult(
      tokens: AuthTokens.fromMap(map),
      user: AuthenticatedUser.fromMap(
        map['user'] is Map ? Map<String, dynamic>.from(map['user']) : {},
      ),
      device: TokenDeviceView.fromMap(
        map['device'] is Map ? Map<String, dynamic>.from(map['device']) : {},
      ),
    );
  }
}
