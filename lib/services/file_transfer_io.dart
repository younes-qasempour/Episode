import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/data_transfer.dart';
import 'file_transfer_platform.dart';

PlatformFileTransfer createPlatformFileTransfer() =>
    const NativePlatformFileTransfer();

class NativePlatformFileTransfer implements PlatformFileTransfer {
  static const _channel = MethodChannel('otakulog/file_transfer');

  const NativePlatformFileTransfer();

  @override
  String get platformLabel {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      _ => 'other',
    };
  }

  @override
  Future<ImportSource?> pickFile({
    required List<String> allowedExtensions,
    required int maxBytes,
  }) async {
    _requireAndroid();
    final result = await _channel.invokeMapMethod<String, dynamic>('pickFile', {
      'allowedExtensions': allowedExtensions,
      'maxBytes': maxBytes,
    });
    if (result == null) {
      return null;
    }
    final bytes = result['bytes'];
    if (bytes is! Uint8List) {
      throw const DataTransferException(
        'The selected file could not be read.',
        code: 'file_read_failed',
      );
    }
    if (bytes.length > maxBytes) {
      throw DataTransferException(
        'The selected file exceeds the ${maxBytes ~/ (1024 * 1024)} MB limit.',
        code: 'file_too_large',
      );
    }
    return ImportSource(
      fileName: _safeName(result['name']?.toString() ?? 'import'),
      bytes: bytes,
      mimeType: result['mimeType']?.toString(),
    );
  }

  @override
  Future<bool> saveArtifact(ExportArtifact artifact) async {
    _requireAndroid();
    return await _channel.invokeMethod<bool>('saveFile', {
          'name': _safeName(artifact.fileName),
          'mimeType': artifact.mimeType,
          'bytes': artifact.bytes,
        }) ??
        false;
  }

  void _requireAndroid() {
    if (defaultTargetPlatform != TargetPlatform.android) {
      throw const DataTransferException(
        'File transfer is currently supported on Android and web.',
        code: 'platform_unsupported',
      );
    }
  }

  String _safeName(String input) {
    final name = input.split(RegExp(r'[/\\]')).last;
    return name.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_');
  }
}
