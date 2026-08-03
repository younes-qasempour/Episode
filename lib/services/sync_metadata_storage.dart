import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sync_metadata.dart';

class SyncMetadataStorage {
  static const String keySyncMetadata = 'otaku_log_sync_metadata_v1';

  final SharedPreferences? _prefs;

  SyncMetadataStorage({SharedPreferences? prefs}) : _prefs = prefs;

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ?? await SharedPreferences.getInstance();
  }

  Future<SyncMetadata> loadMetadata({required String fallbackDeviceId}) async {
    try {
      final prefs = await _getPrefs();
      final raw = prefs.getString(keySyncMetadata);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return SyncMetadata.fromMap(
            Map<String, dynamic>.from(decoded),
            fallbackDeviceId: fallbackDeviceId,
          );
        }
      }
    } catch (_) {}

    return SyncMetadata(clientDeviceId: fallbackDeviceId);
  }

  Future<void> saveMetadata(SyncMetadata metadata) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(keySyncMetadata, jsonEncode(metadata.toMap()));
    } catch (_) {}
  }

  Future<void> clearMetadata({required String fallbackDeviceId}) async {
    try {
      final prefs = await _getPrefs();
      await prefs.remove(keySyncMetadata);
    } catch (_) {}
  }
}
