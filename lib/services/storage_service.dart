import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../utils/constants.dart';

/// Storage Service
/// Handles local data persistence using SharedPreferences and SecureStorage
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  SharedPreferences? _prefs;

  /// Initialize SharedPreferences
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ==================== TOKEN STORAGE ====================

  /// Save auth token securely
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: AppConstants.tokenKey, value: token);
  }

  /// Get auth token
  Future<String?> getToken() async {
    return await _secureStorage.read(key: AppConstants.tokenKey);
  }

  /// Delete auth token
  Future<void> deleteToken() async {
    await _secureStorage.delete(key: AppConstants.tokenKey);
  }

  /// Clear all secure storage
  Future<void> clearToken() async {
    await _secureStorage.deleteAll();
  }

  // ==================== USER STORAGE ====================

  /// Save user data
  Future<void> saveUser(User user) async {
    final userJson = jsonEncode(user.toJson());
    await _prefs?.setString(AppConstants.userKey, userJson);
  }

  /// Get user data
  Future<User?> getUser() async {
    final userJson = _prefs?.getString(AppConstants.userKey);
    if (userJson != null) {
      try {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        return User.fromJson(userMap);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Delete user data
  Future<void> deleteUser() async {
    await _prefs?.remove(AppConstants.userKey);
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ==================== APP SETTINGS ====================

  /// Check if it's first launch
  Future<bool> isFirstLaunch() async {
    return _prefs?.getBool(AppConstants.firstLaunchKey) ?? true;
  }

  /// Set first launch completed
  Future<void> setFirstLaunchComplete() async {
    await _prefs?.setBool(AppConstants.firstLaunchKey, false);
  }

  // ==================== SEARCH HISTORY ====================

  /// Save search locations history
  Future<void> saveSearchHistory(List<String> locations) async {
    await _prefs?.setStringList('search_history', locations);
  }

  /// Get search locations history
  List<String> getSearchHistory() {
    return _prefs?.getStringList('search_history') ?? [];
  }

  /// Add to search history
  Future<void> addToSearchHistory(String location) async {
    final history = getSearchHistory();
    // Remove if already exists (to move to top)
    history.remove(location);
    // Add to beginning
    history.insert(0, location);
    // Keep only last 10 searches
    if (history.length > 10) {
      history.removeLast();
    }
    await saveSearchHistory(history);
  }

  /// Clear search history
  Future<void> clearSearchHistory() async {
    await _prefs?.remove('search_history');
  }

  // ==================== NOTIFICATIONS ====================

  /// Get notification settings
  bool getNotificationsEnabled() {
    return _prefs?.getBool('notifications_enabled') ?? true;
  }

  /// Set notification settings
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs?.setBool('notifications_enabled', enabled);
  }

  // ==================== THEME ====================

  /// Get theme mode (true = dark, false = light)
  bool getDarkMode() {
    return _prefs?.getBool('dark_mode') ?? false;
  }

  /// Set theme mode
  Future<void> setDarkMode(bool isDark) async {
    await _prefs?.setBool('dark_mode', isDark);
  }

  // ==================== CACHE ====================

  /// Save cached offers
  Future<void> cacheOffers(List<VehicleOffer> offers) async {
    final offersJson = offers.map((o) => jsonEncode(o.toJson())).toList();
    await _prefs?.setStringList('cached_offers', offersJson);
    await _prefs?.setInt('cached_offers_time', DateTime.now().millisecondsSinceEpoch);
  }

  /// Get cached offers
  List<VehicleOffer> getCachedOffers() {
    final offersJson = _prefs?.getStringList('cached_offers') ?? [];
    return offersJson.map((json) {
      try {
        return VehicleOffer.fromJson(jsonDecode(json));
      } catch (e) {
        return null;
      }
    }).whereType<VehicleOffer>().toList();
  }

  /// Check if cache is valid (less than 5 minutes old)
  bool isCacheValid() {
    final cachedTime = _prefs?.getInt('cached_offers_time') ?? 0;
    final cacheAge = DateTime.now().millisecondsSinceEpoch - cachedTime;
    return cacheAge < 5 * 60 * 1000; // 5 minutes
  }

  /// Clear all cache
  Future<void> clearCache() async {
    await _prefs?.remove('cached_offers');
    await _prefs?.remove('cached_offers_time');
  }

  // ==================== CLEAR ALL ====================

  /// Clear all data (logout)
  Future<void> clearAll() async {
    await clearToken();
    await deleteUser();
    await clearCache();
    // Keep settings like theme, notification preferences
  }
}
