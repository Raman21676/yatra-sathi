import 'user_model.dart';

/// Vehicle Offer Model
/// Represents a ride offer posted by a vehicle owner
class VehicleOffer {
  final String id;
  final String ownerId;
  final User? owner;
  final String vehicleType;
  final String vehicleNumber;
  final String vehiclePhoto;
  final String? vehiclePhotoPublicId;
  final String? seatPhoto;
  final String? seatPhotoPublicId;
  final int seatsTotal;
  final int seatsAvailable;
  final double fare;
  final String fromLocation;
  final String toLocation;
  final DateTime leaveTime;
  final DateTime reachTime;
  final String? description;
  final String contactNumber;
  final String status;
  final DateTime expiresAt;
  final DateTime createdAt;

  VehicleOffer({
    required this.id,
    required this.ownerId,
    this.owner,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.vehiclePhoto,
    this.vehiclePhotoPublicId,
    this.seatPhoto,
    this.seatPhotoPublicId,
    required this.seatsTotal,
    required this.seatsAvailable,
    required this.fare,
    required this.fromLocation,
    required this.toLocation,
    required this.leaveTime,
    required this.reachTime,
    this.description,
    required this.contactNumber,
    this.status = 'active',
    required this.expiresAt,
    required this.createdAt,
  });

  /// Create VehicleOffer from JSON
  factory VehicleOffer.fromJson(Map<String, dynamic> json) {
    return VehicleOffer(
      id: json['_id'] ?? json['id'] ?? '',
      ownerId: json['ownerId'] is Map 
          ? json['ownerId']['_id'] ?? '' 
          : json['ownerId'] ?? '',
      owner: json['owner'] != null 
          ? User.fromJson(json['owner']) 
          : (json['ownerId'] is Map ? User.fromJson(json['ownerId']) : null),
      vehicleType: json['vehicleType'] ?? 'Car',
      vehicleNumber: json['vehicleNumber'] ?? '',
      vehiclePhoto: json['vehiclePhoto'] ?? '',
      vehiclePhotoPublicId: json['vehiclePhotoPublicId'],
      seatPhoto: json['seatPhoto'],
      seatPhotoPublicId: json['seatPhotoPublicId'],
      seatsTotal: json['seatsTotal'] ?? 0,
      seatsAvailable: json['seatsAvailable'] ?? 0,
      fare: (json['fare'] ?? 0).toDouble(),
      fromLocation: json['fromLocation'] ?? '',
      toLocation: json['toLocation'] ?? '',
      leaveTime: json['leaveTime'] != null 
          ? DateTime.parse(json['leaveTime']) 
          : DateTime.now(),
      reachTime: json['reachTime'] != null 
          ? DateTime.parse(json['reachTime']) 
          : DateTime.now(),
      description: json['description'],
      contactNumber: json['contactNumber'] ?? '',
      status: json['status'] ?? 'active',
      expiresAt: json['expiresAt'] != null 
          ? DateTime.parse(json['expiresAt']) 
          : DateTime.now(),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }

  /// Convert VehicleOffer to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'ownerId': ownerId,
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
      'vehiclePhoto': vehiclePhoto,
      'vehiclePhotoPublicId': vehiclePhotoPublicId,
      'seatPhoto': seatPhoto,
      'seatPhotoPublicId': seatPhotoPublicId,
      'seatsTotal': seatsTotal,
      'seatsAvailable': seatsAvailable,
      'fare': fare,
      'fromLocation': fromLocation,
      'toLocation': toLocation,
      'leaveTime': leaveTime.toIso8601String(),
      'reachTime': reachTime.toIso8601String(),
      'description': description,
      'contactNumber': contactNumber,
      'status': status,
      'expiresAt': expiresAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create a copy of VehicleOffer with updated fields
  VehicleOffer copyWith({
    String? id,
    String? ownerId,
    User? owner,
    String? vehicleType,
    String? vehicleNumber,
    String? vehiclePhoto,
    String? vehiclePhotoPublicId,
    String? seatPhoto,
    String? seatPhotoPublicId,
    int? seatsTotal,
    int? seatsAvailable,
    double? fare,
    String? fromLocation,
    String? toLocation,
    DateTime? leaveTime,
    DateTime? reachTime,
    String? description,
    String? contactNumber,
    String? status,
    DateTime? expiresAt,
    DateTime? createdAt,
  }) {
    return VehicleOffer(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      owner: owner ?? this.owner,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      vehiclePhoto: vehiclePhoto ?? this.vehiclePhoto,
      vehiclePhotoPublicId: vehiclePhotoPublicId ?? this.vehiclePhotoPublicId,
      seatPhoto: seatPhoto ?? this.seatPhoto,
      seatPhotoPublicId: seatPhotoPublicId ?? this.seatPhotoPublicId,
      seatsTotal: seatsTotal ?? this.seatsTotal,
      seatsAvailable: seatsAvailable ?? this.seatsAvailable,
      fare: fare ?? this.fare,
      fromLocation: fromLocation ?? this.fromLocation,
      toLocation: toLocation ?? this.toLocation,
      leaveTime: leaveTime ?? this.leaveTime,
      reachTime: reachTime ?? this.reachTime,
      description: description ?? this.description,
      contactNumber: contactNumber ?? this.contactNumber,
      status: status ?? this.status,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Check if seats can be reserved
  bool canReserve(int numSeats) {
    return seatsAvailable >= numSeats && status == 'active' && !isExpired;
  }

  /// Check if offer is expired
  bool get isExpired {
    return DateTime.now().isAfter(expiresAt) || status == 'expired';
  }

  @override
  String toString() {
    return 'VehicleOffer(id: $id, from: $fromLocation, to: $toLocation, available: $seatsAvailable)';
  }
}

/// Create Offer Request Model
class CreateOfferRequest {
  final String vehicleType;
  final String vehicleNumber;
  final String? vehiclePhoto;
  final String? seatPhoto;
  final int seatsTotal;
  final double fare;
  final String fromLocation;
  final String toLocation;
  final DateTime leaveTime;
  final DateTime reachTime;
  final String? description;
  final String contactNumber;

  CreateOfferRequest({
    required this.vehicleType,
    required this.vehicleNumber,
    this.vehiclePhoto,
    this.seatPhoto,
    required this.seatsTotal,
    required this.fare,
    required this.fromLocation,
    required this.toLocation,
    required this.leaveTime,
    required this.reachTime,
    this.description,
    required this.contactNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber.toUpperCase(),
      'vehiclePhoto': vehiclePhoto,
      'seatPhoto': seatPhoto,
      'seatsTotal': seatsTotal,
      'fare': fare,
      'fromLocation': fromLocation,
      'toLocation': toLocation,
      'leaveTime': leaveTime.toIso8601String(),
      'reachTime': reachTime.toIso8601String(),
      'description': description,
      'contactNumber': contactNumber,
    };
  }
}

/// Update Offer Request Model
class UpdateOfferRequest {
  final String? vehicleType;
  final String? vehicleNumber;
  final String? vehiclePhoto;
  final String? seatPhoto;
  final int? seatsTotal;
  final double? fare;
  final String? fromLocation;
  final String? toLocation;
  final DateTime? leaveTime;
  final DateTime? reachTime;
  final String? description;
  final String? contactNumber;

  UpdateOfferRequest({
    this.vehicleType,
    this.vehicleNumber,
    this.vehiclePhoto,
    this.seatPhoto,
    this.seatsTotal,
    this.fare,
    this.fromLocation,
    this.toLocation,
    this.leaveTime,
    this.reachTime,
    this.description,
    this.contactNumber,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (vehicleType != null) data['vehicleType'] = vehicleType;
    if (vehicleNumber != null) data['vehicleNumber'] = vehicleNumber?.toUpperCase();
    if (vehiclePhoto != null) data['vehiclePhoto'] = vehiclePhoto;
    if (seatPhoto != null) data['seatPhoto'] = seatPhoto;
    if (seatsTotal != null) data['seatsTotal'] = seatsTotal;
    if (fare != null) data['fare'] = fare;
    if (fromLocation != null) data['fromLocation'] = fromLocation;
    if (toLocation != null) data['toLocation'] = toLocation;
    if (leaveTime != null) data['leaveTime'] = leaveTime?.toIso8601String();
    if (reachTime != null) data['reachTime'] = reachTime?.toIso8601String();
    if (description != null) data['description'] = description;
    if (contactNumber != null) data['contactNumber'] = contactNumber;
    return data;
  }
}

/// Offer Filter Model
class OfferFilter {
  final String? fromLocation;
  final String? toLocation;
  final DateTime? date;
  final String? vehicleType;
  final double? minFare;
  final double? maxFare;

  OfferFilter({
    this.fromLocation,
    this.toLocation,
    this.date,
    this.vehicleType,
    this.minFare,
    this.maxFare,
  });

  Map<String, dynamic> toQueryParams() {
    final Map<String, dynamic> params = {};
    if (fromLocation != null && fromLocation!.isNotEmpty) {
      params['from'] = fromLocation;
    }
    if (toLocation != null && toLocation!.isNotEmpty) {
      params['to'] = toLocation;
    }
    if (date != null) {
      params['date'] = date!.toIso8601String().split('T')[0];
    }
    if (vehicleType != null && vehicleType!.isNotEmpty) {
      params['vehicleType'] = vehicleType;
    }
    if (minFare != null) {
      params['minFare'] = minFare.toString();
    }
    if (maxFare != null) {
      params['maxFare'] = maxFare.toString();
    }
    return params;
  }
}
