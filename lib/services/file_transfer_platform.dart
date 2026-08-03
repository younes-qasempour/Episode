import '../models/data_transfer.dart';

abstract interface class PlatformFileTransfer {
  String get platformLabel;

  Future<ImportSource?> pickFile({
    required List<String> allowedExtensions,
    required int maxBytes,
  });

  Future<bool> saveArtifact(ExportArtifact artifact);
}
