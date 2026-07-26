import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'storage_service.dart';

/// Service that connects to Google Health Connect (Android) or Apple HealthKit
/// (iOS) and fetches steps, distance, sleep, and exercise data.
class HealthSyncService {
  final StorageService _storage;

  // The health plugin is a singleton
  final Health _health = Health();

  static const _settingKeyEnabled = 'healthSyncEnabled';
  static const _settingKeySyncOnStart = 'healthSyncOnStart';
  static const _settingKeyLastSync = 'healthLastSyncMs';

  /// Data types we request read access for.
  static const List<HealthDataType> _readTypes = [
    HealthDataType.STEPS,
    HealthDataType.DISTANCE_DELTA,
    HealthDataType.SLEEP_SESSION,
    HealthDataType.WORKOUT,
  ];

  HealthSyncService(this._storage);

  // ---------------------------------------------------------------------------
  // Settings helpers
  // ---------------------------------------------------------------------------

  bool get isEnabled => _storage.settingsBox.get(_settingKeyEnabled, defaultValue: false) as bool;

  set isEnabled(bool value) => _storage.settingsBox.put(_settingKeyEnabled, value);

  bool get syncOnStart => _storage.settingsBox.get(_settingKeySyncOnStart, defaultValue: false) as bool;

  set syncOnStart(bool value) => _storage.settingsBox.put(_settingKeySyncOnStart, value);

  DateTime? get lastSyncTime {
    final ms = _storage.settingsBox.get(_settingKeyLastSync) as int?;
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  void _updateLastSync() {
    _storage.settingsBox.put(
      _settingKeyLastSync,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  // ---------------------------------------------------------------------------
  // Authorization
  // ---------------------------------------------------------------------------

  /// Check Health Connect SDK status on Android.
  Future<HealthConnectSdkStatus?> checkSdkStatus() async {
    if (Platform.isAndroid) {
      try {
        await _health.configure();
        final status = await _health.getHealthConnectSdkStatus();
        debugPrint('[HealthSync] Health Connect SDK status: $status');
        return status;
      } catch (e) {
        debugPrint('[HealthSync] Error checking SDK status: $e');
        return null;
      }
    }
    return null;
  }

  /// Request authorization and configure the health plugin.
  /// Returns true if access to at least core health types (steps/distance) is granted.
  Future<bool> requestAuthorization() async {
    try {
      await _health.configure();

      if (Platform.isAndroid) {
        final status = await _health.getHealthConnectSdkStatus();
        if (status == HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired) {
          debugPrint('[HealthSync] Health Connect update required, prompting install...');
          await _health.installHealthConnect();
          return false;
        } else if (status == HealthConnectSdkStatus.sdkUnavailable) {
          debugPrint('[HealthSync] Health Connect SDK unavailable on this device');
          return false;
        }
      }

      final granted = await _health.requestAuthorization(
        _readTypes,
        permissions: _readTypes.map((_) => HealthDataAccess.READ).toList(),
      );
      debugPrint('[HealthSync] Authorization granted (all requested types): $granted');

      if (!granted) {
        final core = await hasCorePermissions();
        debugPrint('[HealthSync] Partial permission check — core types granted: $core');
        return core;
      }
      return true;
    } catch (e) {
      debugPrint('[HealthSync] Authorization error: $e');
      return await hasCorePermissions();
    }
  }

  /// Check whether permissions for ALL requested types are granted.
  Future<bool> hasPermissions() async {
    try {
      await _health.configure();
      final result = await _health.hasPermissions(
        _readTypes,
        permissions: _readTypes.map((_) => HealthDataAccess.READ).toList(),
      );
      if (result == true) return true;
      return await hasCorePermissions();
    } catch (e) {
      debugPrint('[HealthSync] hasPermissions error: $e');
      return await hasCorePermissions();
    }
  }

  /// Check whether permissions for core types (STEPS / DISTANCE) are granted.
  Future<bool> hasCorePermissions() async {
    try {
      await _health.configure();
      final stepsPerm = await _health.hasPermissions(
        [HealthDataType.STEPS],
        permissions: [HealthDataAccess.READ],
      );
      final distPerm = await _health.hasPermissions(
        [HealthDataType.DISTANCE_DELTA],
        permissions: [HealthDataAccess.READ],
      );
      return (stepsPerm ?? false) || (distPerm ?? false);
    } catch (e) {
      debugPrint('[HealthSync] hasCorePermissions error: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Data fetching
  // ---------------------------------------------------------------------------

  /// Fetch aggregated steps for a given [date] (midnight to midnight).
  Future<int> fetchStepsForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
    try {
      final steps = await _health.getTotalStepsInInterval(start, end);
      return steps ?? 0;
    } catch (e) {
      debugPrint('[HealthSync] fetchSteps error for $date: $e');
      return 0;
    }
  }

  /// Fetch total walking/running distance (in km) for a given [date].
  Future<double> fetchDistanceForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
    try {
      final data = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: [HealthDataType.DISTANCE_DELTA],
      );
      // Sum all distance data points; values are in metres.
      double totalMetres = 0;
      for (final dp in data) {
        final val = dp.value;
        if (val is NumericHealthValue) {
          totalMetres += val.numericValue.toDouble();
        }
      }
      return totalMetres / 1000.0; // convert to km
    } catch (e) {
      debugPrint('[HealthSync] fetchDistance error for $date: $e');
      return 0.0;
    }
  }

  /// Convenience: Fetch steps + distance for the last [days] days.
  /// Returns a list of records: `{ date, steps, distanceKm }`.
  Future<List<Map<String, dynamic>>> fetchStepsAndDistance({int days = 2}) async {
    final results = <Map<String, dynamic>>[];
    final now = DateTime.now();
    for (int i = 0; i < days; i++) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final steps = await fetchStepsForDate(date);
      final distance = await fetchDistanceForDate(date);
      results.add({
        'date': date,
        'steps': steps,
        'distanceKm': distance,
      });
    }
    return results;
  }

  // ---------------------------------------------------------------------------
  // Sync coordinator
  // ---------------------------------------------------------------------------

  /// Run a full sync, fetching data for the given number of [days].
  /// Returns the number of day-logs updated.
  ///
  /// If [throttleHours] > 0, the sync is skipped when the last sync was
  /// less than [throttleHours] hours ago (unless [force] is true).
  Future<int> sync({
    int days = 7,
    int throttleHours = 0,
    bool force = false,
  }) async {
    if (!isEnabled && !force) {
      debugPrint('[HealthSync] sync skipped — not enabled');
      return 0;
    }

    // Throttle check
    if (!force && throttleHours > 0) {
      final last = lastSyncTime;
      if (last != null &&
          DateTime.now().difference(last).inHours < throttleHours) {
        debugPrint('[HealthSync] sync throttled — last sync ${DateTime.now().difference(last).inMinutes}m ago');
        return 0;
      }
    }

    final hasPerm = await hasPermissions();
    if (!hasPerm) {
      debugPrint('[HealthSync] sync skipped — no permissions');
      return 0;
    }

    debugPrint('[HealthSync] Starting sync for $days days...');
    final records = await fetchStepsAndDistance(days: days);

    int updated = 0;
    for (final record in records) {
      final date = record['date'] as DateTime;
      final steps = record['steps'] as int;
      final distanceKm = record['distanceKm'] as double;

      if (steps > 0 || distanceKm > 0) {
        debugPrint(
          '[HealthSync] Found steps: $steps, distance: ${distanceKm.toStringAsFixed(2)} km on $date',
        );
        updated++;
      }
    }

    _updateLastSync();
    debugPrint('[HealthSync] Sync complete. $updated days with data.');
    return updated;
  }

  /// Startup sync — narrow 2-day window, 2-hour throttle.
  /// Returns fetched records for the caller to persist.
  Future<List<Map<String, dynamic>>> startupSync() async {
    if (!syncOnStart || !isEnabled) return [];

    final last = lastSyncTime;
    if (last != null && DateTime.now().difference(last).inHours < 2) {
      debugPrint('[HealthSync] startup sync throttled');
      return [];
    }

    final hasPerm = await hasPermissions();
    if (!hasPerm) return [];

    debugPrint('[HealthSync] Running startup sync (2 days)...');
    final records = await fetchStepsAndDistance(days: 2);
    _updateLastSync();
    return records;
  }

  /// Manual sync — full 7-day window, no throttle.
  Future<List<Map<String, dynamic>>> manualSync() async {
    final hasPerm = await hasPermissions();
    if (!hasPerm) {
      final granted = await requestAuthorization();
      if (!granted) {
        debugPrint('[HealthSync] Permission check returned false, attempting direct fetch fallback...');
      }
    }

    debugPrint('[HealthSync] Running manual sync (7 days)...');
    final records = await fetchStepsAndDistance(days: 7);
    _updateLastSync();
    return records;
  }
}
