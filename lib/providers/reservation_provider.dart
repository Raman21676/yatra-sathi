import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';

/// Reservation Provider
/// Manages seat reservations state
class ReservationProvider extends ChangeNotifier {
  final ReservationService _reservationService = ReservationService();

  // State
  List<Reservation> _reservations = [];
  List<Reservation> _activeReservations = [];
  List<Reservation> _pastReservations = [];
  Reservation? _selectedReservation;
  bool _isLoading = false;
  String? _error;
  bool _hasExistingReservation = false;

  // Getters
  List<Reservation> get reservations => _reservations;
  List<Reservation> get activeReservations => _activeReservations;
  List<Reservation> get pastReservations => _pastReservations;
  Reservation? get selectedReservation => _selectedReservation;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasExistingReservation => _hasExistingReservation;

  /// Load all user reservations
  Future<void> loadReservations() async {
    _setLoading(true);
    _error = null;

    try {
      final reservations = await _reservationService.getMyReservations();
      _reservations = reservations;
      
      // Separate active and past reservations
      _activeReservations = reservations.where((r) {
        if (r.status != 'confirmed') return false;
        if (r.offer == null) return true;
        return !r.offer!.isExpired;
      }).toList();

      _pastReservations = reservations.where((r) {
        if (r.status == 'cancelled') return true;
        if (r.offer == null) return false;
        return r.offer!.isExpired;
      }).toList();

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Book a reservation
  Future<bool> bookReservation({
    required String offerId,
    required int seatsReserved,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _reservationService.bookReservation(
        offerId: offerId,
        seatsReserved: seatsReserved,
      );

      if (response.success && response.reservation != null) {
        final reservation = response.reservation!;
        _reservations.insert(0, reservation);
        
        if (reservation.status == 'confirmed') {
          _activeReservations.insert(0, reservation);
        }
        
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

  /// Cancel a reservation
  Future<bool> cancelReservation(String reservationId) async {
    _setLoading(true);
    _error = null;

    try {
      final success = await _reservationService.cancelReservation(reservationId);

      if (success) {
        // Update local state
        final index = _reservations.indexWhere((r) => r.id == reservationId);
        if (index != -1) {
          _reservations[index] = _reservations[index].copyWith(status: 'cancelled');
        }

        // Move from active to past
        _activeReservations.removeWhere((r) => r.id == reservationId);
        
        final cancelledReservation = _reservations.firstWhere(
          (r) => r.id == reservationId,
          orElse: () => null as Reservation,
        );
        
        if (cancelledReservation.id == reservationId) {
          _pastReservations.insert(0, cancelledReservation);
        }

        if (_selectedReservation?.id == reservationId) {
          _selectedReservation = _selectedReservation!.copyWith(status: 'cancelled');
        }

        _error = null;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to cancel reservation';
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

  /// Check if user has already reserved an offer
  Future<bool> checkExistingReservation(String offerId) async {
    try {
      _hasExistingReservation = await _reservationService.hasReservedOffer(offerId);
      notifyListeners();
      return _hasExistingReservation;
    } catch (e) {
      return false;
    }
  }

  /// Get reservation by ID
  Reservation? getReservationById(String id) {
    try {
      return _reservations.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get reservation for a specific offer
  Reservation? getReservationForOffer(String offerId) {
    try {
      return _reservations.firstWhere(
        (r) => r.offerId == offerId && r.status == 'confirmed',
      );
    } catch (e) {
      return null;
    }
  }

  /// Calculate total fare of all active reservations
  double get totalActiveFare {
    return _activeReservations.fold(0.0, (sum, r) => sum + r.totalFare);
  }

  /// Get total seats reserved in active reservations
  int get totalSeatsReserved {
    return _activeReservations.fold(0, (sum, r) => sum + r.seatsReserved);
  }

  /// Clear selected reservation
  void clearSelectedReservation() {
    _selectedReservation = null;
    notifyListeners();
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
