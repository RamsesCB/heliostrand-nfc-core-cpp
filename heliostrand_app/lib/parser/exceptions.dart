class CorruptedPayloadException implements Exception {
  final String message;
  const CorruptedPayloadException(this.message);

  @override
  String toString() => 'CorruptedPayloadException: $message';
}

class NfcDeviceException implements Exception {
  final String message;
  final dynamic cause;
  const NfcDeviceException(this.message, [this.cause]);

  @override
  String toString() => 'NfcDeviceException: $message${cause != null ? " (Causa: $cause)" : ""}';
}
