import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';

/// Offer Provider
/// Manages ride offers state
class OfferProvider extends ChangeNotifier {
  final OfferService _offerService = OfferService();

  // State
  List<VehicleOffer> _offers = [];
  List<VehicleOffer> _myOffers = [];
  VehicleOffer? _selectedOffer;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  OfferFilter? _currentFilter;

  // Getters
  List<VehicleOffer> get offers => _offers;
  List<VehicleOffer> get myOffers => _myOffers;
  VehicleOffer? get selectedOffer => _selectedOffer;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  OfferFilter? get currentFilter => _currentFilter;

  /// Load all offers with optional filter
  Future<void> loadOffers({OfferFilter? filter, bool refresh = false}) async {
    if (refresh) {
      _setLoading(true);
    } else if (_isLoading) {
      return; // Prevent concurrent requests
    }
    
    _error = null;
    _currentFilter = filter;

    try {
      final offers = await _offerService.getOffers(filter: filter);
      _offers = offers;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Load user's own offers
  Future<void> loadMyOffers() async {
    _setLoading(true);
    _error = null;

    try {
      final offers = await _offerService.getMyOffers();
      _myOffers = offers;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Get single offer by ID
  Future<VehicleOffer?> getOffer(String id) async {
    // Check if already loaded
    final cachedOffer = _offers.firstWhere(
      (o) => o.id == id,
      orElse: () => _myOffers.firstWhere(
        (o) => o.id == id,
        orElse: () => null as VehicleOffer,
      ),
    );
    
    if (cachedOffer.id == id) {
      _selectedOffer = cachedOffer;
      notifyListeners();
      return cachedOffer;
    }

    // Fetch from server
    _setLoading(true);
    _error = null;

    try {
      final offer = await _offerService.getOffer(id);
      _selectedOffer = offer;
      notifyListeners();
      return offer;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Create new offer
  Future<bool> createOffer(CreateOfferRequest request) async {
    _setLoading(true);
    _error = null;

    try {
      final offer = await _offerService.createOffer(request);
      
      if (offer != null) {
        _offers.insert(0, offer);
        _myOffers.insert(0, offer);
        _error = null;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to create offer';
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

  /// Update existing offer
  Future<bool> updateOffer(String id, UpdateOfferRequest request) async {
    _setLoading(true);
    _error = null;

    try {
      final offer = await _offerService.updateOffer(id, request);
      
      if (offer != null) {
        // Update in lists
        final offerIndex = _offers.indexWhere((o) => o.id == id);
        if (offerIndex != -1) {
          _offers[offerIndex] = offer;
        }
        
        final myOfferIndex = _myOffers.indexWhere((o) => o.id == id);
        if (myOfferIndex != -1) {
          _myOffers[myOfferIndex] = offer;
        }
        
        _selectedOffer = offer;
        _error = null;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to update offer';
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

  /// Delete offer
  Future<bool> deleteOffer(String id) async {
    _setLoading(true);
    _error = null;

    try {
      final success = await _offerService.deleteOffer(id);
      
      if (success) {
        _offers.removeWhere((o) => o.id == id);
        _myOffers.removeWhere((o) => o.id == id);
        
        if (_selectedOffer?.id == id) {
          _selectedOffer = null;
        }
        
        _error = null;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to delete offer';
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

  /// Search offers by route
  Future<void> searchOffers({
    String? fromLocation,
    String? toLocation,
    DateTime? date,
    String? vehicleType,
  }) async {
    final filter = OfferFilter(
      fromLocation: fromLocation,
      toLocation: toLocation,
      date: date,
      vehicleType: vehicleType,
    );
    
    await loadOffers(filter: filter);
  }

  /// Clear filter and reload all offers
  Future<void> clearFilter() async {
    _currentFilter = null;
    await loadOffers(refresh: true);
  }

  /// Check if user can reserve seats
  Future<bool> canReserve(String offerId, int seats) async {
    return await _offerService.canReserveOffer(offerId, seats);
  }

  /// Update available seats locally (after reservation)
  void updateAvailableSeats(String offerId, int seatsChange) {
    // Update in offers list
    final offerIndex = _offers.indexWhere((o) => o.id == offerId);
    if (offerIndex != -1) {
      final offer = _offers[offerIndex];
      final newAvailable = offer.seatsAvailable + seatsChange;
      _offers[offerIndex] = offer.copyWith(seatsAvailable: newAvailable);
    }

    // Update in my offers list
    final myOfferIndex = _myOffers.indexWhere((o) => o.id == offerId);
    if (myOfferIndex != -1) {
      final offer = _myOffers[myOfferIndex];
      final newAvailable = offer.seatsAvailable + seatsChange;
      _myOffers[myOfferIndex] = offer.copyWith(seatsAvailable: newAvailable);
    }

    // Update selected offer
    if (_selectedOffer?.id == offerId) {
      final newAvailable = _selectedOffer!.seatsAvailable + seatsChange;
      _selectedOffer = _selectedOffer!.copyWith(seatsAvailable: newAvailable);
    }

    notifyListeners();
  }

  /// Clear selected offer
  void clearSelectedOffer() {
    _selectedOffer = null;
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
