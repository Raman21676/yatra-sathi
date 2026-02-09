import '../models/models.dart';
import '../utils/constants.dart';
import 'api_service.dart';

/// Reservation Service
/// Handles all reservation-related API calls
class ReservationService {
  final ApiService _api = ApiService();

  /// Book a reservation
  Future<ReservationResponse> bookReservation({
    required String offerId,
    required int seatsReserved,
  }) async {
    final request = BookReservationRequest(
      offerId: offerId,
      seatsReserved: seatsReserved,
    );

    final response = await _api.post(
      ApiConstants.bookReservation,
      data: request.toJson(),
    );

    return ReservationResponse.fromJson(response.data);
  }

  /// Get my reservations
  Future<List<Reservation>> getMyReservations() async {
    final response = await _api.get(ApiConstants.listReservations);

    if (response.data['success'] == true && response.data['data'] != null) {
      final List<dynamic> reservationsJson = response.data['data'];
      return reservationsJson.map((json) => Reservation.fromJson(json)).toList();
    }
    
    return [];
  }

  /// Cancel a reservation
  Future<bool> cancelReservation(String reservationId) async {
    final response = await _api.put(
      ApiConstants.cancelReservation(reservationId),
    );

    return response.data['success'] == true;
  }

  /// Get reservation details
  Future<Reservation?> getReservation(String reservationId) async {
    final reservations = await getMyReservations();
    try {
      return reservations.firstWhere((r) => r.id == reservationId);
    } catch (e) {
      return null;
    }
  }

  /// Check if user has already reserved this offer
  Future<bool> hasReservedOffer(String offerId) async {
    final reservations = await getMyReservations();
    return reservations.any((r) => 
      r.offerId == offerId && r.status == 'confirmed'
    );
  }

  /// Get active reservations (confirmed and not expired)
  Future<List<Reservation>> getActiveReservations() async {
    final reservations = await getMyReservations();
    return reservations.where((r) {
      if (r.status != 'confirmed') return false;
      if (r.offer == null) return true; // Include if offer not loaded
      return !r.offer!.isExpired;
    }).toList();
  }

  /// Get past reservations (cancelled or expired)
  Future<List<Reservation>> getPastReservations() async {
    final reservations = await getMyReservations();
    return reservations.where((r) {
      if (r.status == 'cancelled') return true;
      if (r.offer == null) return false;
      return r.offer!.isExpired;
    }).toList();
  }

  /// Get total seats reserved by user across all offers
  Future<int> getTotalSeatsReserved() async {
    final reservations = await getMyReservations();
    return reservations
        .where((r) => r.status == 'confirmed')
        .fold(0, (sum, r) => sum + r.seatsReserved);
  }

  /// Calculate total fare for user's reservations
  Future<double> getTotalFare() async {
    final reservations = await getMyReservations();
    return reservations
        .where((r) => r.status == 'confirmed')
        .fold(0.0, (sum, r) => sum + r.totalFare);
  }
}
