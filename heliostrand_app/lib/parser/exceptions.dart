class CorruptedPayloadException implements Exception {
  final String message;
  const CorruptedPayloadException(this.message);

  @override
  String toString() => 'CorruptedPayloadException: $message';
}

class InvalidTelemetryException implements Exception {
  final String message;
  const InvalidTelemetryException(this.message);

  @override
  String toString() => 'InvalidTelemetryException: $message';
}

class UnsupportedProtocolVersionException extends InvalidTelemetryException {
  final int receivedVersion;

  const UnsupportedProtocolVersionException(this.receivedVersion)
      : super('Versión de protocolo no soportada. Este cliente acepta únicamente V2.');

  @override
  String toString() =>
      'UnsupportedProtocolVersionException: versión $receivedVersion; se requiere V2';
}

class NfcDeviceException implements Exception {
  final String message;
  final dynamic cause;
  const NfcDeviceException(this.message, [this.cause]);

  @override
  String toString() =>
      'NfcDeviceException: $message${cause != null ? " (Causa: $cause)" : ""}';
}
