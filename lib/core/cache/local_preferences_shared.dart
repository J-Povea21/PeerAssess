import 'package:loggy/loggy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'i_local_preferences.dart';

class LocalPreferencesShared implements ILocalPreferences {
  final SharedPreferencesAsync prefs;

  LocalPreferencesShared({SharedPreferencesAsync? prefs})
      : prefs = prefs ?? SharedPreferencesAsync();

  @override
  Future<String?> getString(String key) async {
    try {
      return await prefs.getString(key);
    } catch (e, st) {
      logError('LocalPreferencesShared: error getting String for "$key": $e', e, st);
      return null;
    }
  }

  @override
  Future<void> setString(String key, String value) async {
    try {
      await prefs.setString(key, value);
    } catch (e, st) {
      logError('LocalPreferencesShared: error setting String for "$key": $e', e, st);
      rethrow;
    }
  }

  @override
  Future<int?> getInt(String key) async {
    try {
      return await prefs.getInt(key);
    } catch (e, st) {
      logError('LocalPreferencesShared: error getting int for "$key": $e', e, st);
      return null;
    }
  }

  @override
  Future<void> setInt(String key, int value) async {
    try {
      await prefs.setInt(key, value);
    } catch (e, st) {
      logError('LocalPreferencesShared: error setting int for "$key": $e', e, st);
      rethrow;
    }
  }

  @override
  Future<double?> getDouble(String key) async {
    try {
      return await prefs.getDouble(key);
    } catch (e, st) {
      logError('LocalPreferencesShared: error getting double for "$key": $e', e, st);
      return null;
    }
  }

  @override
  Future<void> setDouble(String key, double value) async {
    try {
      await prefs.setDouble(key, value);
    } catch (e, st) {
      logError('LocalPreferencesShared: error setting double for "$key": $e', e, st);
      rethrow;
    }
  }

  @override
  Future<bool?> getBool(String key) async {
    try {
      return await prefs.getBool(key);
    } catch (e, st) {
      logError('LocalPreferencesShared: error getting bool for "$key": $e', e, st);
      return null;
    }
  }

  @override
  Future<void> setBool(String key, bool value) async {
    try {
      await prefs.setBool(key, value);
    } catch (e, st) {
      logError('LocalPreferencesShared: error setting bool for "$key": $e', e, st);
      rethrow;
    }
  }

  @override
  Future<List<String>?> getStringList(String key) async {
    try {
      return await prefs.getStringList(key);
    } catch (e, st) {
      logError('LocalPreferencesShared: error getting List<String> for "$key": $e', e, st);
      return null;
    }
  }

  @override
  Future<void> setStringList(String key, List<String> value) async {
    try {
      await prefs.setStringList(key, value);
    } catch (e, st) {
      logError('LocalPreferencesShared: error setting List<String> for "$key": $e', e, st);
      rethrow;
    }
  }

  @override
  Future<void> remove(String key) async {
    try {
      await prefs.remove(key);
    } catch (e, st) {
      logError('LocalPreferencesShared: error removing key "$key": $e', e, st);
    }
  }

  @override
  Future<void> clear() async {
    try {
      await prefs.clear();
    } catch (e, st) {
      logError('LocalPreferencesShared: error clearing preferences: $e', e, st);
    }
  }
}
