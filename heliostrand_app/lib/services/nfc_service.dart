import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';

import '../models/robot_telemetry.dart';
import '../parser/exceptions.dart';
import '../parser/theo_jansen_data_parser.dart';

/// Servicio de gestión de hardware NFC móvil mediante flutter_nfc_kit.
/// Incluye terminación coordinada en dispose() y validación estricta de tramas hexadecimales.
class NfcService {
  final TheoJansenDataParser _parser = TheoJansenDataParser();
  bool _isScanning = false;
  bool _isDisposed = false;

  final StreamController<RobotTelemetry> _telemetryController =
      StreamController<RobotTelemetry>.broadcast();
  final StreamController<String> _statusController =
      StreamController<String>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  Stream<RobotTelemetry> get onTelemetryReceived => _telemetryController.stream;
  Stream<String> get onStatusChanged => _statusController.stream;
  Stream<String> get onError => _errorController.stream;

  bool get isScanning => _isScanning;

  /// Verifica si el hardware NFC está disponible en el dispositivo móvil
  Future<bool> isNfcAvailable() async {
    try {
      if (!Platform.isAndroid && !Platform.isIOS) {
        return false;
      }
      final availability = await FlutterNfcKit.nfcAvailability;
      return availability == NFCAvailability.available;
    } catch (_) {
      return false;
    }
  }

  /// Inicia el escaneo continuo de tags NFC
  Future<void> startContinuousScan() async {
    if (_isScanning || _isDisposed) return;
    _isScanning = true;
    _emitStatus('Acerca el tag NFC del robot Theo Jansen...');

    while (_isScanning && !_isDisposed) {
      try {
        final NFCTag tag = await FlutterNfcKit.poll(
          timeout: const Duration(seconds: 10),
          iosAlertMessage: 'Acerca el robot para leer telemetría',
        );

        if (!_isScanning || _isDisposed) {
          await FlutterNfcKit.finish();
          break;
        }

        _emitStatus('Tag detectado: ${tag.id}. Leyendo memoria...');

        Uint8List? rawBytes;

        try {
          final String hexResponse = await FlutterNfcKit.transceive('FFB000040C');
          rawBytes = _hexToBytes(hexResponse);
        } catch (_) {
          try {
            final String rawRead = await FlutterNfcKit.transceive('3004');
            rawBytes = _hexToBytes(rawRead);
          } catch (e) {
            throw NfcDeviceException('No se pudo leer el bloque 4 del tag NFC', e);
          }
        }

        if (rawBytes.length == 12) {
          final telemetry = _parser.decodeTelemetryPayload(rawBytes, tag.id);
          _emitTelemetry(telemetry);
          _emitStatus('Telemetría recibida con éxito.');
        } else if (rawBytes.length > 12) {
          // Extraer los 12 bytes exactos si el lector devolvió páginas adicionales
          final payload = rawBytes.sublist(0, 12);
          final telemetry = _parser.decodeTelemetryPayload(payload, tag.id);
          _emitTelemetry(telemetry);
          _emitStatus('Telemetría recibida con éxito.');
        } else {
          _emitError('Trama NFC incompleta (${rawBytes.length} bytes recibidos, se esperaban 12).');
        }

        await FlutterNfcKit.finish(iosAlertMessage: 'Lectura completada.');
        await Future.delayed(const Duration(milliseconds: 1500));
      } catch (e) {
        if (_isScanning && !_isDisposed) {
          _emitError(e.toString());
          try {
            await FlutterNfcKit.finish(iosErrorMessage: 'Error de lectura');
          } catch (_) {}
          await Future.delayed(const Duration(milliseconds: 1000));
        }
      }
    }
  }

  /// Detiene el escaneo
  Future<void> stopScan() async {
    _isScanning = false;
    _emitStatus('Escaneo detenido.');
    try {
      await FlutterNfcKit.finish();
    } catch (_) {}
  }

  /// Conversión estricta de cadena hexadecimal a bytes.
  /// Lanza FormatException si contiene caracteres no válidos o longitud impar.
  Uint8List _hexToBytes(String hex) {
    final cleanHex = hex.trim();
    if (cleanHex.length % 2 != 0) {
      throw const FormatException('Longitud de cadena hexadecimal impar.');
    }
    final bytes = Uint8List(cleanHex.length ~/ 2);
    for (int i = 0; i < cleanHex.length; i += 2) {
      final byteStr = cleanHex.substring(i, i + 2);
      final val = int.tryParse(byteStr, radix: 16);
      if (val == null) {
        throw FormatException('Carácter hexadecimal inválido en: $byteStr');
      }
      bytes[i ~/ 2] = val;
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

  /// Cierre seguro de recursos evitando condiciones de carrera
  Future<void> dispose() async {
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
