import '../models/models.dart';
import '../utils/constants.dart';
import 'api_service.dart';

/// Offer Service
/// Handles all ride offer-related API calls
class OfferService {
  final ApiService _api = ApiService();

  /// Get all offers with optional filters
  Future<List<VehicleOffer>> getOffers({OfferFilter? filter}) async {
    final queryParams = filter?.toQueryParams() ?? {};
    
    final response = await _api.get(
      ApiConstants.listOffers,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response.data['success'] == true && response.data['data'] != null) {
      final List<dynamic> offersJson = response.data['data'];
      return offersJson.map((json) => VehicleOffer.fromJson(json)).toList();
    }
    
    return [];
  }

  /// Get single offer by ID
  Future<VehicleOffer?> getOffer(String id) async {
    final response = await _api.get(ApiConstants.offerDetail(id));

    if (response.data['success'] == true && response.data['data'] != null) {
      return VehicleOffer.fromJson(response.data['data']);
    }
    
    return null;
  }

  /// Create new offer
  Future<VehicleOffer?> createOffer(CreateOfferRequest request) async {
    final response = await _api.post(
      ApiConstants.createOffer,
      data: request.toJson(),
    );

    if (response.data['success'] == true && response.data['data'] != null) {
      return VehicleOffer.fromJson(response.data['data']);
    }
    
    return null;
  }

  /// Update existing offer
  Future<VehicleOffer?> updateOffer(String id, UpdateOfferRequest request) async {
    final response = await _api.put(
      ApiConstants.updateOffer(id),
      data: request.toJson(),
    );

    if (response.data['success'] == true && response.data['data'] != null) {
      return VehicleOffer.fromJson(response.data['data']);
    }
    
    return null;
  }

  /// Delete offer
  Future<bool> deleteOffer(String id) async {
    final response = await _api.delete(ApiConstants.deleteOffer(id));
    return response.data['success'] == true;
  }

  /// Get my offers (offers created by current user)
  Future<List<VehicleOffer>> getMyOffers() async {
    // The backend should filter by owner based on auth token
    // If not, we can fetch all and filter locally
    final response = await _api.get(ApiConstants.listOffers);

    if (response.data['success'] == true && response.data['data'] != null) {
      final List<dynamic> offersJson = response.data['data'];
      return offersJson.map((json) => VehicleOffer.fromJson(json)).toList();
    }
    
    return [];
  }

  /// Search offers by route
  Future<List<VehicleOffer>> searchOffers({
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
    
    return await getOffers(filter: filter);
  }

  /// Get popular routes
  /// Returns a map of route pairs with count
  Future<Map<String, int>> getPopularRoutes() async {
    // This would typically be a backend endpoint
    // For now, return hardcoded popular routes in Nepal
    return {
      'Kathmandu - Pokhara': 150,
      'Kathmandu - Chitwan': 120,
      'Kathmandu - Lumbini': 80,
      'Kathmandu - Birgunj': 100,
      'Kathmandu - Janakpur': 70,
      'Pokhara - Chitwan': 50,
      'Kathmandu - Dharan': 90,
    };
  }

  /// Check if offer can be reserved
  Future<bool> canReserveOffer(String offerId, int seats) async {
    final offer = await getOffer(offerId);
    if (offer == null) return false;
    return offer.canReserve(seats);
  }
}
