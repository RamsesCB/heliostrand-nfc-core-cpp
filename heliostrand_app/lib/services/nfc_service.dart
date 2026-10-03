import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';

import '../models/robot_telemetry.dart';
import '../parser/exceptions.dart';
import '../parser/theo_jansen_data_parser.dart';

/// Servicio de gestión de hardware NFC móvil mediante flutter_nfc_kit.
class NfcService {
  final TheoJansenDataParser _parser = TheoJansenDataParser();
  bool _isScanning = false;

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
    if (_isScanning) return;
    _isScanning = true;
    _statusController.add('Acerca el tag NFC del robot Theo Jansen...');

    while (_isScanning) {
      try {
        final NFCTag tag = await FlutterNfcKit.poll(
          timeout: const Duration(seconds: 10),
          iosAlertMessage: 'Acerca el robot para leer telemetría',
        );

        _statusController.add('Tag detectado: ${tag.id}. Leyendo memoria...');

        // Comando APDU estándar de lectura binaria:
        // FF B0 00 [Bloque 0x04] [Longitud 12 bytes (0x0C)]
        // Equivale al APDU utilizado en el core de Java: FF B0 00 04 0C
        Uint8List? rawBytes;

        try {
          final String hexResponse = await FlutterNfcKit.transceive('FFB000040C');
          rawBytes = _hexToBytes(hexResponse);
        } catch (_) {
          // Si el transceptor opera bajo protocolo NTAG / Mifare Ultralight
          // comando READ estándar de bloque 04 (0x30 0x04)
          try {
            final String rawRead = await FlutterNfcKit.transceive('3004');
            rawBytes = _hexToBytes(rawRead);
          } catch (e) {
            throw NfcDeviceException('No se pudo leer el bloque 4 del tag NFC', e);
          }
        }

        if (rawBytes.length >= 12) {
          // Tomar los 12 bytes del payload
          final payload = rawBytes.sublist(0, 12);
          final telemetry = _parser.decodeTelemetryPayload(payload, tag.id);
          _telemetryController.add(telemetry);
          _statusController.add('Telemetría recibida con éxito.');
        } else {
          _errorController.add('Trama NFC incompleta (${rawBytes.length} bytes recibidos).');
        }

        await FlutterNfcKit.finish(iosAlertMessage: 'Lectura completada.');
        await Future.delayed(const Duration(milliseconds: 1500));
      } catch (e) {
        if (_isScanning) {
          _errorController.add(e.toString());
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
    _statusController.add('Escaneo detenido.');
    try {
      await FlutterNfcKit.finish();
    } catch (_) {}
  }

  Uint8List _hexToBytes(String hex) {
    final cleanHex = hex.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '');
    final bytes = <int>[];
    for (int i = 0; i < cleanHex.length; i += 2) {
      if (i + 2 <= cleanHex.length) {
        bytes.add(int.parse(cleanHex.substring(i, i + 2), radix: 16));
      }
    }
    return Uint8List.fromList(bytes);
  }

  void dispose() {
    stopScan();
    _telemetryController.close();
    _statusController.close();
    _errorController.close();
  }
}
