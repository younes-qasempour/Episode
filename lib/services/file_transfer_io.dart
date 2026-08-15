import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/data_transfer.dart';
import 'file_transfer_platform.dart';

PlatformFileTransfer createPlatformFileTransfer() =>
    const NativePlatformFileTransfer();

class NativePlatformFileTransfer implements PlatformFileTransfer {
  static const _channel = MethodChannel('episode/file_transfer');

  const NativePlatformFileTransfer();

  @override
  String get platformLabel {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.windows => 'windows',
      TargetPlatform.iOS => 'ios',
      _ => 'other',
    };
  }

  @override
  Future<ImportSource?> pickFile({
    required List<String> allowedExtensions,
    required int maxBytes,
  }) async {
    _requireSupportedNative();
    final Map<String, dynamic>? result;
    try {
      result = await _channel.invokeMapMethod<String, dynamic>('pickFile', {
        'allowedExtensions': allowedExtensions,
        'maxBytes': maxBytes,
      });
    } on PlatformException catch (error) {
      throw _dataTransferError(error, operation: 'read');
    }
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
    _requireSupportedNative();
    try {
      return await _channel.invokeMethod<bool>('saveFile', {
            'name': _safeName(artifact.fileName),
            'mimeType': artifact.mimeType,
            'bytes': artifact.bytes,
          }) ??
          false;
    } on PlatformException catch (error) {
      throw _dataTransferError(error, operation: 'save');
    }
  }

  void _requireSupportedNative() {
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.windows) {
      throw const DataTransferException(
        'File transfer is currently supported on Android, web, and Windows.',
        code: 'platform_unsupported',
      );
    }
  }

  DataTransferException _dataTransferError(
    PlatformException error, {
    required String operation,
  }) {
    final message = switch (error.code) {
      'file_too_large' => 'The selected file exceeds the allowed size limit.',
      'file_read_failed' => 'The selected file could not be read.',
      'file_write_failed' => 'The selected file could not be saved.',
      'file_dialog_failed' => 'The Windows file dialog could not be opened.',
      _ => 'The file could not be $operation on this device.',
    };
    return DataTransferException(message, code: error.code);
  }

  String _safeName(String input) {
    final name = input.split(RegExp(r'[/\\]')).last;
    return name.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_');
  }
}
