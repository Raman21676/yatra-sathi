import 'user_model.dart';
import 'vehicle_offer_model.dart';

/// Reservation Model
/// Represents a seat reservation made by a passenger
class Reservation {
  final String id;
  final String offerId;
  final VehicleOffer? offer;
  final String userId;
  final User? user;
  final int seatsReserved;
  final String status;
  final DateTime createdAt;

  Reservation({
    required this.id,
    required this.offerId,
    this.offer,
    required this.userId,
    this.user,
    required this.seatsReserved,
    this.status = 'confirmed',
    required this.createdAt,
  });

  /// Create Reservation from JSON
  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['_id'] ?? json['id'] ?? '',
      offerId: json['offerId'] is Map 
          ? json['offerId']['_id'] ?? '' 
          : json['offerId'] ?? '',
      offer: json['offerId'] is Map 
          ? VehicleOffer.fromJson(json['offerId']) 
          : (json['offer'] != null ? VehicleOffer.fromJson(json['offer']) : null),
      userId: json['userId'] is Map 
          ? json['userId']['_id'] ?? '' 
          : json['userId'] ?? '',
      user: json['user'] != null 
          ? User.fromJson(json['user']) 
          : (json['userId'] is Map ? User.fromJson(json['userId']) : null),
      seatsReserved: json['seatsReserved'] ?? 1,
      status: json['status'] ?? 'confirmed',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }

  /// Convert Reservation to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'offerId': offerId,
      'userId': userId,
      'seatsReserved': seatsReserved,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create a copy of Reservation with updated fields
  Reservation copyWith({
    String? id,
    String? offerId,
    VehicleOffer? offer,
    String? userId,
    User? user,
    int? seatsReserved,
    String? status,
    DateTime? createdAt,
  }) {
    return Reservation(
      id: id ?? this.id,
      offerId: offerId ?? this.offerId,
      offer: offer ?? this.offer,
      userId: userId ?? this.userId,
      user: user ?? this.user,
      seatsReserved: seatsReserved ?? this.seatsReserved,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Check if reservation can be cancelled
  bool get canCancel {
    return status == 'confirmed';
  }

  /// Get total fare for reservation
  double get totalFare {
    if (offer != null) {
      return offer!.fare * seatsReserved;
    }
    return 0;
  }

  @override
  String toString() {
    return 'Reservation(id: $id, offerId: $offerId, seats: $seatsReserved, status: $status)';
  }
}

/// Book Reservation Request Model
class BookReservationRequest {
  final String offerId;
  final int seatsReserved;

  BookReservationRequest({
    required this.offerId,
    required this.seatsReserved,
  });

  Map<String, dynamic> toJson() {
    return {
      'offerId': offerId,
      'seatsReserved': seatsReserved,
    };
  }
}

/// Reservation Response Model
class ReservationResponse {
  final bool success;
  final String message;
  final Reservation? reservation;

  ReservationResponse({
    required this.success,
    required this.message,
    this.reservation,
  });

  factory ReservationResponse.fromJson(Map<String, dynamic> json) {
    return ReservationResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      reservation: json['reservation'] != null 
          ? Reservation.fromJson(json['reservation']) 
          : null,
    );
  }
}
