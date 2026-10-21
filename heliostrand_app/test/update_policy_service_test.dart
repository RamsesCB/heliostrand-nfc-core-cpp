import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:heliostrand_app/services/update_policy_service.dart';

void main() {
  test('policy body limits bytes while receiving', () async {
    expect(
      await readVersionPolicyBody(
        Stream.value(utf8.encode('{"min_required_version_code":4}')),
      ),
      '{"min_required_version_code":4}',
    );
    expect(
      () => readVersionPolicyBody(
        Stream.fromIterable([
          List.filled(4096, 65),
          [66],
        ]),
      ),
      throwsFormatException,
    );
  });

  group('version gating policy parser', () {
    test('lee versionCode numerico minimo', () {
      expect(parseMinimumRequiredVersion({'min_required_version': 3}), 3);
      expect(parseMinimumRequiredVersion({'min_required_version_code': 5}), 5);
    });

    test('acepta version minima enviada como string numerico', () {
      expect(parseMinimumRequiredVersion({'min_required_version': '12'}), 12);
    });

    test('rechaza configuraciones invalidas', () {
      expect(parseMinimumRequiredVersion({'min_required_version': 0}), isNull);
      expect(
        parseMinimumRequiredVersion({'min_required_version': 'abc'}),
        isNull,
      );
      expect(parseMinimumRequiredVersion({'other': 3}), isNull);
      expect(parseMinimumRequiredVersion([]), isNull);
    });
  });
}
