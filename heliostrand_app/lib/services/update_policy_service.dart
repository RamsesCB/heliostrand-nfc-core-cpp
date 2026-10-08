import 'dart:convert';
import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Se configura durante build: --dart-define=VERSION_POLICY_URL=https://...
const versionPolicyUrl = String.fromEnvironment('VERSION_POLICY_URL');
const _minimumVersionCacheKey = 'minimum_android_version_code';

/// El servidor debe responder: {"min_required_version": 3}.
int? parseMinimumRequiredVersion(Object? response) {
  if (response is! Map<String, dynamic>) return null;
  final value =
      response['min_required_version_code'] ?? response['min_required_version'];
  final number = value is int ? value : int.tryParse(value?.toString() ?? '');
  return number != null && number > 0 ? number : null;
}

class UpdatePolicyService {
  const UpdatePolicyService();

  Future<bool> requiresUpdate() async {
    final info = await PackageInfo.fromPlatform();
    final currentVersionCode = int.tryParse(info.buildNumber);
    if (currentVersionCode == null) {
      throw const FormatException('Android versionCode no es numerico');
    }

    final preferences = SharedPreferencesAsync();
    var requiredVersionCode =
        await preferences.getInt(_minimumVersionCacheKey) ?? 0;

    if (versionPolicyUrl.isNotEmpty) {
      final uri = Uri.tryParse(versionPolicyUrl);
      if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
        throw const FormatException('VERSION_POLICY_URL debe ser HTTPS');
      }

      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 5);
      try {
        final request = await client
            .getUrl(uri)
            .timeout(const Duration(seconds: 7));
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');
        final response = await request.close().timeout(
          const Duration(seconds: 7),
        );
        if (response.statusCode != HttpStatus.ok) {
          throw HttpException(
            'Version policy HTTP ${response.statusCode}',
            uri: uri,
          );
        }
        final body = await utf8.decoder
            .bind(response)
            .join()
            .timeout(const Duration(seconds: 7));
        if (body.length > 4096) {
          throw const FormatException('Version policy demasiado grande');
        }
        final remoteMinimum = parseMinimumRequiredVersion(jsonDecode(body));
        if (remoteMinimum == null) {
          throw const FormatException(
            'min_required_version ausente o invalida',
          );
        }
        requiredVersionCode = remoteMinimum;
        await preferences.setInt(_minimumVersionCacheKey, remoteMinimum);
      } catch (error, stackTrace) {
        // Si no hay red, se aplica la ultima politica remota validada y guardada.
        if (const String.fromEnvironment('SENTRY_DSN').isNotEmpty) {
          await Sentry.captureException(error, stackTrace: stackTrace);
        }
      } finally {
        client.close(force: true);
      }
    }

    return currentVersionCode < requiredVersionCode;
  }
}
