import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeviceIdentityService {
  static const String keyDeviceId = 'otaku_log_client_device_id_v1';
  static const _uuid = Uuid();

  final SharedPreferences? _prefs;
  final DeviceInfoPlugin? _deviceInfoPlugin;

  DeviceIdentityService({
    SharedPreferences? prefs,
    DeviceInfoPlugin? deviceInfoPlugin,
  })  : _prefs = prefs,
        _deviceInfoPlugin = deviceInfoPlugin;

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ?? await SharedPreferences.getInstance();
  }

  Future<String> getOrCreateClientDeviceId() async {
    final prefs = await _getPrefs();
    final existing = prefs.getString(keyDeviceId);
    if (existing != null && existing.trim().isNotEmpty) {
      return existing.trim();
    }
    final newId = _uuid.v4();
    await prefs.setString(keyDeviceId, newId);
    return newId;
  }

  Future<Map<String, String>> getDeviceInfo() async {
    String platformName = 'unknown';
    String deviceName = 'Episode Device';
    String appVersion = '1.0.0';

    try {
      if (kIsWeb) {
        platformName = 'web';
        deviceName = 'Web Browser';
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        platformName = 'android';
        final plugin = _deviceInfoPlugin ?? DeviceInfoPlugin();
        final androidInfo = await plugin.androidInfo;
        deviceName = '${androidInfo.manufacturer} ${androidInfo.model}'.trim();
        if (deviceName.isEmpty) deviceName = 'Android Device';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        platformName = 'ios';
        final plugin = _deviceInfoPlugin ?? DeviceInfoPlugin();
        final iosInfo = await plugin.iosInfo;
        deviceName = iosInfo.name.isNotEmpty ? iosInfo.name : 'iPhone/iPad';
      } else if (defaultTargetPlatform == TargetPlatform.macOS) {
        platformName = 'macos';
        deviceName = 'Mac Device';
      } else if (defaultTargetPlatform == TargetPlatform.windows) {
        platformName = 'windows';
        deviceName = 'Windows Device';
      } else if (defaultTargetPlatform == TargetPlatform.linux) {
        platformName = 'linux';
        deviceName = 'Linux Device';
      }
    } catch (_) {
      // Fall back safely if platform device info is unavailable
    }

    try {
      final pkgInfo = await PackageInfo.fromPlatform();
      if (pkgInfo.version.isNotEmpty) {
        appVersion = pkgInfo.version;
      }
    } catch (_) {
      // Fall back safely if package info is unavailable
    }

    final clientDeviceId = await getOrCreateClientDeviceId();

    return {
      'clientDeviceId': clientDeviceId,
      'name': deviceName,
      'platform': platformName,
      'appVersion': appVersion,
    };
  }
}
