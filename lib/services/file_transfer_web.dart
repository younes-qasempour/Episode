import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import '../models/data_transfer.dart';
import 'file_transfer_platform.dart';

PlatformFileTransfer createPlatformFileTransfer() =>
    const WebPlatformFileTransfer();

class WebPlatformFileTransfer implements PlatformFileTransfer {
  const WebPlatformFileTransfer();

  @override
  String get platformLabel => 'web';

  @override
  Future<ImportSource?> pickFile({
    required List<String> allowedExtensions,
    required int maxBytes,
  }) {
    final input = web.document.createElement('input') as web.HTMLInputElement
      ..type = 'file'
      ..accept = allowedExtensions.map((extension) => '.$extension').join(',');
    input.style.display = 'none';
    web.document.body?.appendChild(input);
    final completer = Completer<ImportSource?>();

    void cleanup() => input.remove();

    void completeCancelled() {
      if (!completer.isCompleted) {
        cleanup();
        completer.complete(null);
      }
    }

    input.addEventListener(
      'cancel',
      ((web.Event _) => completeCancelled()).toJS,
    );
    input.addEventListener(
      'change',
      ((web.Event _) {
        final files = input.files;
        final file = files == null || files.length == 0 ? null : files.item(0);
        if (file == null) {
          completeCancelled();
          return;
        }
        if (file.size > maxBytes) {
          cleanup();
          completer.completeError(
            DataTransferException(
              'The selected file exceeds the '
              '${maxBytes ~/ (1024 * 1024)} MB limit.',
              code: 'file_too_large',
            ),
          );
          return;
        }
        () async {
          try {
            final buffer = await file.arrayBuffer().toDart;
            cleanup();
            completer.complete(
              ImportSource(
                fileName: _safeName(file.name),
                bytes: Uint8List.view(buffer.toDart),
                mimeType: file.type.isEmpty ? null : file.type,
              ),
            );
          } catch (_) {
            cleanup();
            completer.completeError(
              const DataTransferException(
                'The selected file could not be read.',
                code: 'file_read_failed',
              ),
            );
          }
        }();
      }).toJS,
    );
    input.click();
    return completer.future;
  }

  @override
  Future<bool> saveArtifact(ExportArtifact artifact) async {
    final parts = <web.BlobPart>[artifact.bytes.toJS].toJS;
    final blob = web.Blob(
      parts,
      web.BlobPropertyBag(type: artifact.mimeType),
    );
    final url = web.URL.createObjectURL(blob);
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = url
      ..download = _safeName(artifact.fileName);
    anchor.style.display = 'none';
    web.document.body?.appendChild(anchor);
    try {
      anchor.click();
      return true;
    } finally {
      anchor.remove();
      web.URL.revokeObjectURL(url);
    }
  }
}

String _safeName(String input) {
  final name = input.split(RegExp(r'[/\\]')).last;
  return name.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_');
}
