import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';

import '../models/robot_telemetry.dart';
import '../parser/exceptions.dart';
import '../parser/theo_jansen_data_parser.dart';

class _NfcSlot {
  final Uint8List payload;
  final int generation;

  const _NfcSlot(this.payload, this.generation);
}

class NfcService {
  static const int _slotABasePage = 4;
  static const int _slotBBasePage = 8;

  final TheoJansenDataParser _parser = TheoJansenDataParser();
  final Map<String, int> _lastSequenceByTag = <String, int>{};

  bool _isScanning = false;
  bool _isDisposed = false;

  final StreamController<RobotTelemetry> _telemetryController =
      StreamController<RobotTelemetry>.broadcast();
  final StreamController<String> _statusController =
      StreamController<String>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  Stream<RobotTelemetry> get onTelemetryReceived =>
      _telemetryController.stream;
  Stream<String> get onStatusChanged => _statusController.stream;
  Stream<String> get onError => _errorController.stream;

  bool get isScanning => _isScanning;

  Future<bool> isNfcAvailable() async {
    try {
      if (!Platform.isAndroid && !Platform.isIOS) return false;
      return await FlutterNfcKit.nfcAvailability == NFCAvailability.available;
    } catch (_) {
      return false;
    }
  }

  Future<void> startContinuousScan() async {
    if (_isScanning || _isDisposed) return;
    _isScanning = true;
    _emitStatus('Acerca el tag NTAG213 del robot...');

    while (_isScanning && !_isDisposed) {
      try {
        final tag = await FlutterNfcKit.poll(
          timeout: const Duration(seconds: 10),
          iosAlertMessage: 'Acerca el tag NTAG213 para leer telemetría',
        );

        if (!_isScanning || _isDisposed) {
          await FlutterNfcKit.finish();
          break;
        }

        _emitStatus('Tag detectado: ${tag.id}. Leyendo slots...');

        final slotA = await _readSlot(_slotABasePage);
        final slotB = await _readSlot(_slotBBasePage);
        final telemetry = _decodeNewestValidSlot(slotA, slotB, tag.id);

        if (_isFreshForTag(telemetry)) {
          _emitTelemetry(telemetry);
          _emitStatus('Telemetría V2 nueva recibida.');
        } else {
          _emitStatus(
            'El tag sigue en la secuencia ${telemetry.sequenceNumber}; no hay muestra NFC nueva.',
          );
        }

        await FlutterNfcKit.finish(iosAlertMessage: 'Lectura completada.');
        await Future<void>.delayed(const Duration(milliseconds: 1500));
      } catch (e) {
        if (_isScanning && !_isDisposed) {
          _emitError(e.toString());
          try {
            await FlutterNfcKit.finish(iosErrorMessage: 'Error de lectura');
          } catch (_) {}
          await Future<void>.delayed(const Duration(milliseconds: 1000));
        }
      }
    }
  }

  Future<_NfcSlot?> _readSlot(int basePage) async {
    final baseHex =
        basePage.toRadixString(16).padLeft(2, '0').toUpperCase();

    Uint8List rawBytes;
    try {
      rawBytes = _hexToBytes(
        await FlutterNfcKit.transceive('30$baseHex'),
      );
    } catch (_) {
      try {
        rawBytes = _hexToBytes(
          await FlutterNfcKit.transceive('FFB000${baseHex}10'),
        );
      } catch (_) {
        return null;
      }
    }

    if (rawBytes.length < 16) return null;

    final magic0 = rawBytes[12];
    final magic1 = rawBytes[13];
    final generation = rawBytes[14];
    final complement = rawBytes[15];

    if (magic0 != 0x48 ||
        magic1 != 0x53 ||
        complement != ((~generation) & 0xFF)) {
      return null;
    }

    final payload = Uint8List.fromList(rawBytes.sublist(0, 12));
    if (!_parser.verifyCrc8(payload, payload[11])) return null;

    return _NfcSlot(payload, generation);
  }

  RobotTelemetry _decodeNewestValidSlot(
    _NfcSlot? slotA,
    _NfcSlot? slotB,
    String tagId,
  ) {
    if (slotA == null && slotB == null) {
      throw const NfcDeviceException(
        'No existe ningún slot Heliostrand válido en el NTAG213.',
      );
    }

    final _NfcSlot primary;
    final _NfcSlot? fallback;

    if (slotA == null) {
      primary = slotB!;
      fallback = null;
    } else if (slotB == null) {
      primary = slotA;
      fallback = null;
    } else if (_generationNewer(slotA.generation, slotB.generation)) {
      primary = slotA;
      fallback = slotB;
    } else {
      primary = slotB;
      fallback = slotA;
    }

    try {
      return _parser.decodeTelemetryPayload(primary.payload, tagId);
    } catch (_) {
      if (fallback != null) {
        return _parser.decodeTelemetryPayload(fallback.payload, tagId);
      }
      rethrow;
    }
  }

  bool _generationNewer(int candidate, int reference) {
    final diff = (candidate - reference) & 0xFF;
    return diff != 0 && diff < 128;
  }

  bool _isFreshForTag(RobotTelemetry telemetry) {
    final previous = _lastSequenceByTag[telemetry.tagUid];
    _lastSequenceByTag[telemetry.tagUid] = telemetry.sequenceNumber;
    return previous == null || previous != telemetry.sequenceNumber;
  }

  Future<void> stopScan() async {
    _isScanning = false;
    _emitStatus('Escaneo detenido.');
    try {
      await FlutterNfcKit.finish();
    } catch (_) {}
  }

  Uint8List _hexToBytes(String hex) {
    final cleanHex = hex.trim();
    if (cleanHex.length.isOdd) {
      throw const FormatException('Longitud de cadena hexadecimal impar.');
    }

    final bytes = Uint8List(cleanHex.length ~/ 2);
    for (var i = 0; i < cleanHex.length; i += 2) {
      final byteStr = cleanHex.substring(i, i + 2);
      final value = int.tryParse(byteStr, radix: 16);
      if (value == null) {
        throw FormatException('Carácter hexadecimal inválido en: $byteStr');
      }
      bytes[i ~/ 2] = value;
    }
    return bytes;
  }

  void _emitTelemetry(RobotTelemetry telemetry) {
    if (!_isDisposed && !_telemetryController.isClosed) {
      _telemetryController.add(telemetry);
    }
  }

  void _emitStatus(String status) {
    if (!_isDisposed && !_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  void _emitError(String error) {
    if (!_isDisposed && !_errorController.isClosed) {
      _errorController.add(error);
    }
  }

  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    _isScanning = false;

    try {
      await FlutterNfcKit.finish();
    } catch (_) {}

    await _telemetryController.close();
    await _statusController.close();
    await _errorController.close();
  }
}
