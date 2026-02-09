import 'dart:io';
import 'package:dio/dio.dart';
import '../models/models.dart';
import '../utils/constants.dart';
import 'api_service.dart';
import 'storage_service.dart';

/// Auth Service
/// Handles all authentication-related API calls
class AuthService {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  /// Login user
  Future<LoginResponse> login(String email, String password) async {
    final request = LoginRequest(email: email, password: password);
    
    final response = await _api.post(
      ApiConstants.login,
      data: request.toJson(),
    );

    final loginResponse = LoginResponse.fromJson(response.data);
    
    if (loginResponse.success && loginResponse.token != null) {
      // Save token
      await _storage.saveToken(loginResponse.token!);
      
      // Save user data
      if (loginResponse.user != null) {
        await _storage.saveUser(loginResponse.user!);
      }
    }

    return loginResponse;
  }

  /// Register new user
  /// Note: For file upload, we need to use multipart form data
  Future<LoginResponse> register({
    required String name,
    required String gender,
    required String email,
    required String phone,
    required String password,
    File? photo,
  }) async {
    // If photo is provided, use multipart form data
    if (photo != null) {
      final formData = FormData.fromMap({
        'name': name,
        'gender': gender,
        'email': email,
        'phone': phone,
        'password': password,
        'photo': await MultipartFile.fromFile(photo.path),
      });

      final response = await _api.post(
        ApiConstants.register,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );

      final loginResponse = LoginResponse.fromJson(response.data);
      
      if (loginResponse.success && loginResponse.token != null) {
        await _storage.saveToken(loginResponse.token!);
        if (loginResponse.user != null) {
          await _storage.saveUser(loginResponse.user!);
        }
      }

      return loginResponse;
    } else {
      // No photo - use JSON
      final request = RegisterRequest(
        name: name,
        gender: gender,
        email: email,
        phone: phone,
        password: password,
      );

      final response = await _api.post(
        ApiConstants.register,
        data: request.toJson(),
      );

      final loginResponse = LoginResponse.fromJson(response.data);
      
      if (loginResponse.success && loginResponse.token != null) {
        await _storage.saveToken(loginResponse.token!);
        if (loginResponse.user != null) {
          await _storage.saveUser(loginResponse.user!);
        }
      }

      return loginResponse;
    }
  }

  /// Register with photo URL (when photo is uploaded to Cloudinary first)
  Future<LoginResponse> registerWithPhotoUrl({
    required String name,
    required String gender,
    required String email,
    required String phone,
    required String password,
    String? photoUrl,
    String? photoPublicId,
  }) async {
    final Map<String, dynamic> data = {
      'name': name,
      'gender': gender,
      'email': email,
      'phone': phone,
      'password': password,
    };

    if (photoUrl != null) {
      data['photo'] = photoUrl;
    }
    if (photoPublicId != null) {
      data['photoPublicId'] = photoPublicId;
    }

    final response = await _api.post(
      ApiConstants.register,
      data: data,
    );

    final loginResponse = LoginResponse.fromJson(response.data);
    
    if (loginResponse.success && loginResponse.token != null) {
      await _storage.saveToken(loginResponse.token!);
      if (loginResponse.user != null) {
        await _storage.saveUser(loginResponse.user!);
      }
    }

    return loginResponse;
  }

  /// Get current user profile
  Future<User?> getProfile() async {
    try {
      final response = await _api.get(ApiConstants.me);
      
      if (response.data['success'] == true && response.data['data'] != null) {
        final user = User.fromJson(response.data['data']);
        await _storage.saveUser(user);
        return user;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Update profile
  Future<User?> updateProfile(UpdateProfileRequest request) async {
    final response = await _api.put(
      ApiConstants.updateProfile,
      data: request.toJson(),
    );

    if (response.data['success'] == true && response.data['data'] != null) {
      final user = User.fromJson(response.data['data']);
      await _storage.saveUser(user);
      return user;
    }
    return null;
  }

  /// Update profile with photo
  Future<User?> updateProfileWithPhoto({
    String? name,
    String? phone,
    File? photo,
    String? photoUrl,
    String? photoPublicId,
  }) async {
    // If photo file is provided, upload as multipart
    if (photo != null) {
      final formData = FormData.fromMap({
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        'photo': await MultipartFile.fromFile(photo.path),
      });

      final response = await _api.put(
        ApiConstants.updateProfile,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        final user = User.fromJson(response.data['data']);
        await _storage.saveUser(user);
        return user;
      }
      return null;
    }

    // Otherwise use regular update
    final request = UpdateProfileRequest(
      name: name,
      phone: phone,
      photo: photoUrl,
      photoPublicId: photoPublicId,
    );

    return await updateProfile(request);
  }

  /// Change password
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    final request = ChangePasswordRequest(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );

    final response = await _api.put(
      ApiConstants.changePassword,
      data: request.toJson(),
    );

    return response.data['success'] == true;
  }

  /// Logout user
  Future<void> logout() async {
    await _storage.clearAll();
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await _storage.isLoggedIn();
  }

  /// Get stored user
  Future<User?> getStoredUser() async {
    return await _storage.getUser();
  }
}
