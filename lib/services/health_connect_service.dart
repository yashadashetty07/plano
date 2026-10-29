import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum HealthSdkStatus {
  available,
  notSupported,
  notInstalled,
}

class HealthConnectService {
  static const MethodChannel _channel = MethodChannel('com.plano.app/health_connect');

  static bool get isSupportedPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<HealthSdkStatus> checkAvailability() async {
    if (!isSupportedPlatform) {
      return HealthSdkStatus.notSupported;
    }
    try {
      final status = await _channel.invokeMethod<String>('checkAvailability');
      switch (status) {
        case 'AVAILABLE':
          return HealthSdkStatus.available;
        case 'NOT_INSTALLED':
          return HealthSdkStatus.notInstalled;
        default:
          return HealthSdkStatus.notSupported;
      }
    } catch (e) {
      debugPrint('HealthConnect checkAvailability error: $e');
      return HealthSdkStatus.notSupported;
    }
  }

  Future<List<String>> getGrantedPermissions() async {
    if (!isSupportedPlatform) return [];
    try {
      final list = await _channel.invokeListMethod<String>('getGrantedPermissions');
      return list ?? [];
    } catch (e) {
      debugPrint('HealthConnect getGrantedPermissions error: $e');
      return [];
    }
  }

  Future<bool> openSettings() async {
    if (!isSupportedPlatform) return false;
    try {
      final res = await _channel.invokeMethod<bool>('openSettings');
      return res ?? false;
    } catch (e) {
      debugPrint('HealthConnect openSettings error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getDailySummaries({
    required DateTime start,
    required DateTime end,
  }) async {
    if (!isSupportedPlatform) {
      return {
        'steps': 0,
        'workoutMinutes': 0,
        'source': 'Health Connect (Web / Unavailable)',
      };
    }
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>(
        'getDailySummaries',
        {
          'startEpochMs': start.millisecondsSinceEpoch,
          'endEpochMs': end.millisecondsSinceEpoch,
        },
      );
      return res ?? {};
    } catch (e) {
      debugPrint('HealthConnect getDailySummaries error: $e');
      return {'steps': 0, 'workoutMinutes': 0, 'error': e.toString()};
    }
  }
}
