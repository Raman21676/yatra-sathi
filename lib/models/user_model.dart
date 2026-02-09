/// User Model
/// Represents a registered user in the Yatra Sathi platform
class User {
  final String id;
  final String name;
  final String gender;
  final String email;
  final String phone;
  final String photo;
  final String? photoPublicId;
  final bool verified;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.name,
    required this.gender,
    required this.email,
    required this.phone,
    required this.photo,
    this.photoPublicId,
    this.verified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      gender: json['gender'] ?? 'other',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      photo: json['photo'] ?? '',
      photoPublicId: json['photoPublicId'],
      verified: json['verified'] ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
    );
  }

  /// Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'gender': gender,
      'email': email,
      'phone': phone,
      'photo': photo,
      'photoPublicId': photoPublicId,
      'verified': verified,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of User with updated fields
  User copyWith({
    String? id,
    String? name,
    String? gender,
    String? email,
    String? phone,
    String? photo,
    String? photoPublicId,
    bool? verified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photo: photo ?? this.photo,
      photoPublicId: photoPublicId ?? this.photoPublicId,
      verified: verified ?? this.verified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email)';
  }
}

/// Login Request Model
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

/// Register Request Model
class RegisterRequest {
  final String name;
  final String gender;
  final String email;
  final String phone;
  final String password;

  RegisterRequest({
    required this.name,
    required this.gender,
    required this.email,
    required this.phone,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'gender': gender,
      'email': email,
      'phone': phone,
      'password': password,
    };
  }
}

/// Login Response Model
class LoginResponse {
  final bool success;
  final String message;
  final String? token;
  final User? user;

  LoginResponse({
    required this.success,
    required this.message,
    this.token,
    this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      token: json['token'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }
}

/// Update Profile Request Model
class UpdateProfileRequest {
  final String? name;
  final String? phone;
  final String? photo;
  final String? photoPublicId;

  UpdateProfileRequest({
    this.name,
    this.phone,
    this.photo,
    this.photoPublicId,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (phone != null) data['phone'] = phone;
    if (photo != null) data['photo'] = photo;
    if (photoPublicId != null) data['photoPublicId'] = photoPublicId;
    return data;
  }
}

/// Change Password Request Model
class ChangePasswordRequest {
  final String currentPassword;
  final String newPassword;

  ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    };
  }
}
