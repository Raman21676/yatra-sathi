import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import '../utils/constants.dart';

/// Cloudinary Service
/// Handles image uploads to Cloudinary
/// Uses unsigned uploads (frontend only) - requires upload preset configuration
class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;
  CloudinaryService._internal();

  final Dio _dio = Dio();

  // Cloudinary configuration - UPDATE THESE WITH YOUR VALUES
  static const String _cloudName = 'YOUR_CLOUD_NAME'; // TODO: Replace with your cloud name
  static const String _uploadPreset = 'yatra_sathi_unsigned'; // TODO: Create unsigned preset in Cloudinary
  static const String _apiKey = 'YOUR_API_KEY'; // TODO: Replace if using signed uploads
  static const String _apiSecret = 'YOUR_API_SECRET'; // TODO: Replace if using signed uploads

  static const String _uploadUrl = 'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  /// Upload image to Cloudinary
  /// Returns a map with 'url' and 'public_id' on success
  Future<Map<String, dynamic>?> uploadImage(
    File imageFile, {
    String? folder,
    void Function(double progress)? onProgress,
  }) async {
    try {
      // Validate file
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      // Check file size (max 5MB)
      final fileSize = await imageFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        throw Exception('Image size must be less than 5MB');
      }

      // Create form data
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
        'upload_preset': _uploadPreset,
        if (folder != null) 'folder': folder,
        // Optional: Add transformation on upload
        'quality': 'auto:good',
        'fetch_format': 'auto',
      });

      // Upload with progress tracking
      final response = await _dio.post(
        _uploadUrl,
        data: formData,
        onSendProgress: (sent, total) {
          if (onProgress != null && total > 0) {
            onProgress(sent / total);
          }
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return {
          'url': data['secure_url'],
          'public_id': data['public_id'],
          'width': data['width'],
          'height': data['height'],
          'format': data['format'],
        };
      } else {
        throw Exception('Upload failed with status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('Cloudinary upload error: ${e.message}');
      if (e.response != null) {
        debugPrint('Response data: ${e.response?.data}');
      }
      throw Exception(_parseCloudinaryError(e));
    } catch (e) {
      debugPrint('Unexpected upload error: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Upload multiple images
  Future<List<Map<String, dynamic>>> uploadMultipleImages(
    List<File> imageFiles, {
    String? folder,
    void Function(int current, int total)? onProgress,
  }) async {
    final results = <Map<String, dynamic>>[];
    
    for (int i = 0; i < imageFiles.length; i++) {
      try {
        final result = await uploadImage(
          imageFiles[i],
          folder: folder,
        );
        
        if (result != null) {
          results.add(result);
        }
        
        if (onProgress != null) {
          onProgress(i + 1, imageFiles.length);
        }
      } catch (e) {
        debugPrint('Failed to upload image ${i + 1}: $e');
        // Continue with other images
      }
    }
    
    return results;
  }

  /// Delete image from Cloudinary
  /// Note: Requires backend API for signed deletion (recommended)
  /// or you can use Cloudinary admin API (less secure)
  Future<bool> deleteImage(String publicId) async {
    try {
      // For unsigned uploads, you typically can't delete from frontend
      // This should be handled by your backend
      // But we'll provide the structure here
      
      // Option 1: Call your backend API
      // await ApiService().delete('/cloudinary/delete', data: {'public_id': publicId});
      
      // Option 2: Direct Cloudinary API (requires admin API key - NOT RECOMMENDED for frontend)
      // This is just a placeholder - implement based on your security requirements
      
      debugPrint('Image deletion should be handled by backend: $publicId');
      return true;
    } catch (e) {
      debugPrint('Failed to delete image: $e');
      return false;
    }
  }

  /// Get optimized image URL with transformations
  String getOptimizedImageUrl(
    String originalUrl, {
    int? width,
    int? height,
    String quality = 'auto',
    String format = 'auto',
  }) {
    // Parse the URL and add transformations
    // Cloudinary URL format: https://res.cloudinary.com/cloud_name/image/upload/v123456/public_id.jpg
    
    try {
      final uri = Uri.parse(originalUrl);
      final pathSegments = List<String>.from(uri.pathSegments);
      
      // Find 'upload' segment and add transformations after it
      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex != -1) {
        final transformations = <String>[];
        
        if (width != null) transformations.add('w_$width');
        if (height != null) transformations.add('h_$height');
        transformations.add('c_fit'); // Crop mode
        transformations.add('q_$quality');
        transformations.add('f_$format');
        
        // Insert transformations after 'upload'
        pathSegments.insert(uploadIndex + 1, transformations.join(','));
      }
      
      return uri.replace(pathSegments: pathSegments).toString();
    } catch (e) {
      // Return original URL if parsing fails
      return originalUrl;
    }
  }

  /// Parse Cloudinary error messages
  String _parseCloudinaryError(DioException error) {
    if (error.response?.data != null) {
      final data = error.response!.data;
      if (data is Map) {
        if (data['error'] != null) {
          final errorData = data['error'];
          if (errorData is Map) {
            return errorData['message'] ?? 'Upload failed';
          }
          return errorData.toString();
        }
      }
    }
    return 'Failed to upload image. Please try again.';
  }

  /// Compress image before upload
  /// Returns compressed file path
  Future<File> compressImage(
    File file, {
    int quality = 85,
    int maxWidth = 1200,
    int maxHeight = 1200,
  }) async {
    // For actual compression, you'd use flutter_image_compress package
    // This is a placeholder that returns the original file
    // TODO: Add flutter_image_compress for production
    
    // Example with flutter_image_compress:
    // final compressed = await FlutterImageCompress.compressWithFile(
    //   file.absolute.path,
    //   quality: quality,
    //   minWidth: maxWidth,
    //   minHeight: maxHeight,
    // );
    
    return file;
  }

  /// Validate image before upload
  bool validateImage(File file) {
    // Check file extension
    final validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    final extension = file.path.toLowerCase().substring(
      file.path.lastIndexOf('.'),
    );
    
    if (!validExtensions.contains(extension)) {
      return false;
    }
    
    // Check file size (would need to be async for actual size check)
    // This is a basic check
    return true;
  }
}

/// Configuration helper for Cloudinary
class CloudinaryConfig {
  /// Setup instructions:
  /// 
  /// 1. Go to https://cloudinary.com/console
  /// 2. Get your Cloud Name from Dashboard
  /// 3. Go to Settings > Upload
  /// 4. Scroll to "Upload presets" and click "Add upload preset"
  /// 5. Set:
  ///    - Name: yatra_sathi_unsigned
  ///    - Signing Mode: Unsigned
  ///    - Folder: yatra_sathi (optional)
  ///    - Allowed formats: jpg, png, gif, webp
  ///    - Max file size: 5000000 (5MB)
  ///    - Quality: auto
  /// 6. Save and use the preset name in CloudinaryService
  ///
  /// For signed uploads (more secure):
  /// - Generate signature on your backend
  /// - Pass timestamp, signature, api_key along with file
  static const String setupInstructions = '''
Cloudinary Setup Instructions:

1. Replace YOUR_CLOUD_NAME in cloudinary_service.dart
2. Create an unsigned upload preset named "yatra_sathi_unsigned"
3. (Optional) For signed uploads, implement backend signature generation

Note: Unsigned uploads are suitable for development and most production use cases.
For enhanced security, use signed uploads with backend signature generation.
''';
}
