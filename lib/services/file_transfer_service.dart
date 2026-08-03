import '../models/data_transfer.dart';
import 'file_transfer_platform.dart';
import 'file_transfer_stub.dart'
    if (dart.library.html) 'file_transfer_web.dart'
    if (dart.library.io) 'file_transfer_io.dart' as platform;

class FileTransferService {
  final PlatformFileTransfer _delegate;

  FileTransferService({PlatformFileTransfer? delegate})
      : _delegate = delegate ?? platform.createPlatformFileTransfer();

  String get platformLabel => _delegate.platformLabel;

  Future<ImportSource?> pickImportFile({
    List<String> allowedExtensions = const ['json', 'xml', 'gz'],
    int maxBytes = 10 * 1024 * 1024,
  }) {
    return _delegate.pickFile(
      allowedExtensions: allowedExtensions,
      maxBytes: maxBytes,
    );
  }

  Future<bool> saveArtifact(ExportArtifact artifact) {
    return _delegate.saveArtifact(artifact);
  }
}
