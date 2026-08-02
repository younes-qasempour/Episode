import '../models/data_transfer.dart';
import 'file_transfer_platform.dart';

PlatformFileTransfer createPlatformFileTransfer() =>
    const UnsupportedPlatformFileTransfer();

class UnsupportedPlatformFileTransfer implements PlatformFileTransfer {
  const UnsupportedPlatformFileTransfer();

  @override
  String get platformLabel => 'other';

  @override
  Future<ImportSource?> pickFile({
    required List<String> allowedExtensions,
    required int maxBytes,
  }) {
    throw const DataTransferException(
      'File import is not supported on this platform.',
      code: 'platform_unsupported',
    );
  }

  @override
  Future<bool> saveArtifact(ExportArtifact artifact) {
    throw const DataTransferException(
      'File export is not supported on this platform.',
      code: 'platform_unsupported',
    );
  }
}
