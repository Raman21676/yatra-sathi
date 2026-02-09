import 'dart:io';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';

/// Auth Provider
/// Manages authentication state and user data
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storage = StorageService();

  // State
  User? _user;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  /// Initialize provider - check if user is logged in
  Future<void> initialize() async {
    _setLoading(true);
    
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      
      if (isLoggedIn) {
        // Try to get stored user first
        _user = await _authService.getStoredUser();
        
        // Then fetch fresh data from server
        try {
          final freshUser = await _authService.getProfile();
          if (freshUser != null) {
            _user = freshUser;
          }
        } catch (e) {
          // If server fetch fails, use stored user
          debugPrint('Failed to fetch fresh user data: $e');
        }
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Auth initialization error: $e');
    } finally {
      _isInitialized = true;
      _setLoading(false);
    }
  }

  /// Login user
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _authService.login(email, password);
      
      if (response.success && response.user != null) {
        _user = response.user;
        _error = null;
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Register user
  Future<bool> register({
    required String name,
    required String gender,
    required String email,
    required String phone,
    required String password,
    File? photo,
    String? photoUrl,
    String? photoPublicId,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      LoginResponse response;

      if (photo != null) {
        // Register with photo file
        response = await _authService.register(
          name: name,
          gender: gender,
          email: email,
          phone: phone,
          password: password,
          photo: photo,
        );
      } else if (photoUrl != null) {
        // Register with photo URL (already uploaded to Cloudinary)
        response = await _authService.registerWithPhotoUrl(
          name: name,
          gender: gender,
          email: email,
          phone: phone,
          password: password,
          photoUrl: photoUrl,
          photoPublicId: photoPublicId,
        );
      } else {
        // Register without photo
        response = await _authService.register(
          name: name,
          gender: gender,
          email: email,
          phone: phone,
          password: password,
        );
      }

      if (response.success && response.user != null) {
        _user = response.user;
        _error = null;
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh user profile
  Future<void> refreshProfile() async {
    try {
      final user = await _authService.getProfile();
      if (user != null) {
        _user = user;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to refresh profile: $e');
    }
  }

  /// Update profile
  Future<bool> updateProfile({
    String? name,
    String? phone,
    File? photo,
    String? photoUrl,
    String? photoPublicId,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final updatedUser = await _authService.updateProfileWithPhoto(
        name: name,
        phone: phone,
        photo: photo,
        photoUrl: photoUrl,
        photoPublicId: photoPublicId,
      );

      if (updatedUser != null) {
        _user = updatedUser;
        _error = null;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to update profile';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Change password
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _setLoading(true);
    _error = null;

    try {
      final success = await _authService.changePassword(currentPassword, newPassword);
      
      if (!success) {
        _error = 'Failed to change password';
      }
      
      notifyListeners();
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Logout user
  Future<void> logout() async {
    _setLoading(true);
    
    try {
      await _authService.logout();
      _user = null;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
