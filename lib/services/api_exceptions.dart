import 'dart:convert';

class ApiException implements Exception {
  final String code;
  final String message;
  final int statusCode;
  final Map<String, dynamic> details;
  final String? requestId;

  const ApiException({
    required this.code,
    required this.message,
    required this.statusCode,
    this.details = const {},
    this.requestId,
  });

  @override
  String toString() => message;
}

class NetworkUnavailableException extends ApiException {
  const NetworkUnavailableException({
    super.message = 'No network connection available.',
  }) : super(code: 'NETWORK_UNAVAILABLE', statusCode: 0);
}

class RequestTimeoutException extends ApiException {
  const RequestTimeoutException({
    super.message = 'The server request timed out. Please try again.',
  }) : super(code: 'REQUEST_TIMEOUT', statusCode: 408);
}

class AuthenticationRequiredException extends ApiException {
  const AuthenticationRequiredException({
    super.message = 'Authentication credentials are invalid or missing.',
    super.details,
    super.requestId,
  }) : super(code: 'AUTHENTICATION_REQUIRED', statusCode: 401);
}

class InvalidCredentialsException extends ApiException {
  const InvalidCredentialsException({
    super.message = 'The email or password is incorrect.',
    super.details,
    super.requestId,
  }) : super(code: 'INVALID_CREDENTIALS', statusCode: 401);
}

class DuplicateEmailException extends ApiException {
  const DuplicateEmailException({
    super.message = 'An account with this email already exists.',
    super.details,
    super.requestId,
  }) : super(code: 'EMAIL_ALREADY_REGISTERED', statusCode: 409);
}

class ValidationApiException extends ApiException {
  const ValidationApiException({
    required super.message,
    super.details,
    super.requestId,
  }) : super(code: 'VALIDATION_ERROR', statusCode: 422);
}

class ForbiddenApiException extends ApiException {
  const ForbiddenApiException({
    super.message = 'The requested operation is not allowed.',
    super.details,
    super.requestId,
  }) : super(code: 'FORBIDDEN', statusCode: 403);
}

class DeviceRevokedException extends ApiException {
  const DeviceRevokedException({
    super.message = 'This device session has been revoked.',
    super.details,
    super.requestId,
  }) : super(code: 'DEVICE_REVOKED', statusCode: 403);
}

class SyncRevisionConflictException extends ApiException {
  final int? currentRevision;
  final String? serverChecksum;
  final String? serverSnapshotId;

  const SyncRevisionConflictException({
    super.message = 'The cloud snapshot changed after your local revision.',
    this.currentRevision,
    this.serverChecksum,
    this.serverSnapshotId,
    super.details = const {},
    super.requestId,
  }) : super(code: 'SYNC_REVISION_CONFLICT', statusCode: 409);
}

class PayloadTooLargeException extends ApiException {
  const PayloadTooLargeException({
    super.message = 'The request payload exceeds the server size limit.',
    super.details,
    super.requestId,
  }) : super(code: 'PAYLOAD_TOO_LARGE', statusCode: 413);
}

class UnsupportedProtocolException extends ApiException {
  const UnsupportedProtocolException({
    super.message = 'The sync protocol version is not supported by the server.',
    super.details,
    super.requestId,
  }) : super(code: 'UNSUPPORTED_SYNC_PROTOCOL', statusCode: 426);
}

class UnsupportedSchemaException extends ApiException {
  const UnsupportedSchemaException({
    super.message = 'The snapshot schema version is not supported.',
    super.details,
    super.requestId,
  }) : super(code: 'UNSUPPORTED_SNAPSHOT_SCHEMA', statusCode: 426);
}

class ServerUnavailableException extends ApiException {
  const ServerUnavailableException({
    super.message = 'The server database is temporarily unavailable.',
    super.details,
    super.requestId,
  }) : super(code: 'DATABASE_UNAVAILABLE', statusCode: 503);
}

class UnexpectedApiException extends ApiException {
  const UnexpectedApiException({
    required super.message,
    required super.statusCode,
    super.code = 'UNEXPECTED_ERROR',
    super.details,
    super.requestId,
  });
}

ApiException parseBackendError(
  int statusCode,
  String body, {
  String? requestId,
}) {
  String code = 'UNKNOWN_ERROR';
  String message = 'An unexpected backend error occurred.';
  Map<String, dynamic> details = {};

  try {
    if (body.trim().isNotEmpty) {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] is Map) {
        final err = Map<String, dynamic>.from(decoded['error'] as Map);
        code = err['code']?.toString() ?? code;
        message = err['message']?.toString() ?? message;
        if (err['details'] is Map) {
          details = Map<String, dynamic>.from(err['details'] as Map);
        }
      }
    }
  } catch (_) {}

  switch (code) {
    case 'INVALID_CREDENTIALS':
      return InvalidCredentialsException(
        message: message,
        details: details,
        requestId: requestId,
      );
    case 'EMAIL_ALREADY_REGISTERED':
      return DuplicateEmailException(
        message: message,
        details: details,
        requestId: requestId,
      );
    case 'AUTHENTICATION_REQUIRED':
    case 'INVALID_REFRESH_TOKEN':
    case 'SESSION_REVOKED':
      return AuthenticationRequiredException(
        message: message,
        details: details,
        requestId: requestId,
      );
    case 'DEVICE_REVOKED':
      return DeviceRevokedException(
        message: message,
        details: details,
        requestId: requestId,
      );
    case 'FORBIDDEN':
      return ForbiddenApiException(
        message: message,
        details: details,
        requestId: requestId,
      );
    case 'SYNC_REVISION_CONFLICT':
      return SyncRevisionConflictException(
        message: message,
        currentRevision: (details['currentRevision'] as num?)?.toInt(),
        serverChecksum: details['checksum']?.toString(),
        serverSnapshotId: details['snapshotId']?.toString(),
        details: details,
        requestId: requestId,
      );
    case 'PAYLOAD_TOO_LARGE':
      return PayloadTooLargeException(
        message: message,
        details: details,
        requestId: requestId,
      );
    case 'UNSUPPORTED_SYNC_PROTOCOL':
      return UnsupportedProtocolException(
        message: message,
        details: details,
        requestId: requestId,
      );
    case 'UNSUPPORTED_SNAPSHOT_SCHEMA':
      return UnsupportedSchemaException(
        message: message,
        details: details,
        requestId: requestId,
      );
    case 'DATABASE_UNAVAILABLE':
      return ServerUnavailableException(
        message: message,
        details: details,
        requestId: requestId,
      );
    default:
      if (statusCode == 401) {
        return AuthenticationRequiredException(
          message: message,
          details: details,
          requestId: requestId,
        );
      }
      if (statusCode == 422) {
        return ValidationApiException(
          message: message,
          details: details,
          requestId: requestId,
        );
      }
      return UnexpectedApiException(
        code: code,
        message: message,
        statusCode: statusCode,
        details: details,
        requestId: requestId,
      );
  }
}
