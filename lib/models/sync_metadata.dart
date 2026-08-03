class SyncMetadata {
  final String? boundUserId;
  final String clientDeviceId;
  final int serverRevision;
  final String? lastSyncedSnapshotId;
  final String? lastSyncedChecksum;
  final DateTime? lastSuccessfulSyncAt;
  final bool syncPending;
  final String? lastSyncErrorCode;
  final DateTime? lastSyncAttemptAt;

  const SyncMetadata({
    this.boundUserId,
    required this.clientDeviceId,
    this.serverRevision = 0,
    this.lastSyncedSnapshotId,
    this.lastSyncedChecksum,
    this.lastSuccessfulSyncAt,
    this.syncPending = false,
    this.lastSyncErrorCode,
    this.lastSyncAttemptAt,
  });

  SyncMetadata copyWith({
    String? boundUserId,
    bool clearBoundUserId = false,
    String? clientDeviceId,
    int? serverRevision,
    String? lastSyncedSnapshotId,
    bool clearLastSyncedSnapshotId = false,
    String? lastSyncedChecksum,
    bool clearLastSyncedChecksum = false,
    DateTime? lastSuccessfulSyncAt,
    bool clearLastSuccessfulSyncAt = false,
    bool? syncPending,
    String? lastSyncErrorCode,
    bool clearLastSyncErrorCode = false,
    DateTime? lastSyncAttemptAt,
    bool clearLastSyncAttemptAt = false,
  }) {
    return SyncMetadata(
      boundUserId: clearBoundUserId ? null : (boundUserId ?? this.boundUserId),
      clientDeviceId: clientDeviceId ?? this.clientDeviceId,
      serverRevision: serverRevision ?? this.serverRevision,
      lastSyncedSnapshotId: clearLastSyncedSnapshotId
          ? null
          : (lastSyncedSnapshotId ?? this.lastSyncedSnapshotId),
      lastSyncedChecksum: clearLastSyncedChecksum
          ? null
          : (lastSyncedChecksum ?? this.lastSyncedChecksum),
      lastSuccessfulSyncAt: clearLastSuccessfulSyncAt
          ? null
          : (lastSuccessfulSyncAt ?? this.lastSuccessfulSyncAt),
      syncPending: syncPending ?? this.syncPending,
      lastSyncErrorCode: clearLastSyncErrorCode
          ? null
          : (lastSyncErrorCode ?? this.lastSyncErrorCode),
      lastSyncAttemptAt: clearLastSyncAttemptAt
          ? null
          : (lastSyncAttemptAt ?? this.lastSyncAttemptAt),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'boundUserId': boundUserId,
      'clientDeviceId': clientDeviceId,
      'serverRevision': serverRevision,
      'lastSyncedSnapshotId': lastSyncedSnapshotId,
      'lastSyncedChecksum': lastSyncedChecksum,
      'lastSuccessfulSyncAt': lastSuccessfulSyncAt?.toUtc().toIso8601String(),
      'syncPending': syncPending,
      'lastSyncErrorCode': lastSyncErrorCode,
      'lastSyncAttemptAt': lastSyncAttemptAt?.toUtc().toIso8601String(),
    };
  }

  factory SyncMetadata.fromMap(Map<String, dynamic> map,
      {required String fallbackDeviceId}) {
    return SyncMetadata(
      boundUserId: map['boundUserId']?.toString(),
      clientDeviceId: map['clientDeviceId']?.toString() ?? fallbackDeviceId,
      serverRevision: (map['serverRevision'] as num?)?.toInt() ?? 0,
      lastSyncedSnapshotId: map['lastSyncedSnapshotId']?.toString(),
      lastSyncedChecksum: map['lastSyncedChecksum']?.toString(),
      lastSuccessfulSyncAt: map['lastSuccessfulSyncAt'] != null
          ? DateTime.tryParse(map['lastSuccessfulSyncAt'].toString())?.toUtc()
          : null,
      syncPending: map['syncPending'] == true,
      lastSyncErrorCode: map['lastSyncErrorCode']?.toString(),
      lastSyncAttemptAt: map['lastSyncAttemptAt'] != null
          ? DateTime.tryParse(map['lastSyncAttemptAt'].toString())?.toUtc()
          : null,
    );
  }
}
