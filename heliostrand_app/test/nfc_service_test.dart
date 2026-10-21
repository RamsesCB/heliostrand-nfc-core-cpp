import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heliostrand_app/services/nfc_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_nfc_kit/method');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const slot = '9301647882915A5C0F0A026A485301FE';

  for (final invalid in [false, true]) {
    test(
      invalid
          ? 'rejects foreign tags before writing'
          : 'keeps newer commands queued during a write',
      () async {
        final service = NfcService();
        final writes = <String>[];
        final done = Completer<void>();
        Future<void>? stopping;
        var polls = 0;
        final errors = service.onError.listen((message) {
          if (invalid && !done.isCompleted) {
            stopping = service.stopScan();
            done.complete();
          }
        });
        messenger.setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'poll') {
            polls++;
            return jsonEncode({
              'type': 'mifare_ultralight',
              'id': '04ABCDEF123456',
              'standard': 'ISO 14443-3A',
            });
          }
          if (call.method == 'transceive') {
            final command = (call.arguments as Map)['data'] as String;
            if (command == '3003') return invalid ? '00000000' : 'E1101200';
            if (command == '3004') return slot;
            if (command == '3008') return '00000000000000000000000000000000';
            if (command.startsWith('A20C')) {
              writes.add(command);
              if (writes.length == 1) {
                service.queueServoCommand(100, 120);
              } else {
                stopping = service.stopScan();
                done.complete();
              }
              return '0A';
            }
          }
          return null;
        });
        service.queueServoCommand(90, 90);
        final scan = service.startContinuousScan();
        expect(identical(scan, service.startContinuousScan()), isTrue);
        try {
          await done.future.timeout(const Duration(seconds: 6));
          await stopping;
          await scan;
          if (invalid) {
            expect(writes, isEmpty);
            expect(polls, 1);
          } else {
            expect(writes, ['A20C535A5A53', 'A20C5364784F']);
            expect(polls, 2);
          }
        } finally {
          await service.dispose();
          await errors.cancel();
          messenger.setMockMethodCallHandler(channel, null);
        }
      },
    );
  }
}
