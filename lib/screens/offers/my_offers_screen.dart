import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/offer_card.dart';
import 'post_offer_screen.dart';
import 'offer_detail_screen.dart';

class MyOffersScreen extends StatefulWidget {
  const MyOffersScreen({super.key});

  @override
  State<MyOffersScreen> createState() => _MyOffersScreenState();
}

class _MyOffersScreenState extends State<MyOffersScreen> {
  @override
  void initState() {
    super.initState();
    _loadMyOffers();
  }

  Future<void> _loadMyOffers() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OfferProvider>(context, listen: false).loadMyOffers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Offers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMyOffers,
          ),
        ],
      ),
      body: Consumer<OfferProvider>(
        builder: (context, offerProvider, child) {
          if (offerProvider.isLoading && offerProvider.myOffers.isEmpty) {
            return const LoadingShimmer();
          }

          if (offerProvider.error != null && offerProvider.myOffers.isEmpty) {
            return _buildErrorView(offerProvider);
          }

          if (offerProvider.myOffers.isEmpty) {
            return _buildEmptyView();
          }

          return RefreshIndicator(
            onRefresh: _loadMyOffers,
            child: ListView.builder(
              padding: const EdgeInsets.all(UIConstants.defaultPadding),
              itemCount: offerProvider.myOffers.length,
              itemBuilder: (context, index) {
                final offer = offerProvider.myOffers[index];
                return _buildOfferCard(offer);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createNewOffer(),
        icon: const Icon(Icons.add),
        label: const Text('Post Ride'),
      ),
    );
  }

  Widget _buildErrorView(OfferProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Failed to load your offers',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _loadMyOffers,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_taxi_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No rides posted yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Post your first ride and start earning by sharing your journey',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _createNewOffer(),
            icon: const Icon(Icons.add),
            label: const Text('Post a Ride'),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard(VehicleOffer offer) {
    final isExpired = offer.isExpired;

    return Dismissible(
      key: Key(offer.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) => _confirmDelete(offer),
      onDismissed: (_) => _deleteOffer(offer),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () => _viewOfferDetails(offer),
          borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image with status overlay
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(UIConstants.defaultRadius),
                    ),
                    child: Image.network(
                      offer.vehiclePhoto,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 150,
                        color: Colors.grey[300],
                        child: const Icon(Icons.error),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isExpired ? Colors.red : Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isExpired ? 'EXPIRED' : 'ACTIVE',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Route
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            offer.fromLocation,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_forward, color: Colors.grey),
                        Expanded(
                          child: Text(
                            offer.toLocation,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Details row
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          Helpers.formatDate(offer.leaveTime),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.event_seat,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${offer.seatsAvailable}/${offer.seatsTotal} seats',
                          style: TextStyle(
                            color: offer.seatsAvailable > 0
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          Helpers.formatCurrency(offer.fare),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(UIConstants.primaryColor),
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: isExpired ? null : () => _editOffer(offer),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmAndDelete(offer),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _createNewOffer() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PostOfferScreen()),
    );
  }

  void _viewOfferDetails(VehicleOffer offer) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OfferDetailScreen(offer: offer),
      ),
    );
  }

  void _editOffer(VehicleOffer offer) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PostOfferScreen(offerToEdit: offer),
      ),
    );
  }

  Future<bool> _confirmDelete(VehicleOffer offer) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Offer'),
        content: Text(
          'Are you sure you want to delete the ride from ${offer.fromLocation} to ${offer.toLocation}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _confirmAndDelete(VehicleOffer offer) async {
    final confirmed = await _confirmDelete(offer);
    if (confirmed) {
      _deleteOffer(offer);
    }
  }

  Future<void> _deleteOffer(VehicleOffer offer) async {
    final provider = Provider.of<OfferProvider>(context, listen: false);
    final success = await provider.deleteOffer(offer.id);

    if (mounted) {
      if (success) {
        Helpers.showSnackBar(context, 'Ride deleted successfully');
      } else {
        Helpers.showSnackBar(
          context,
          provider.error ?? 'Failed to delete ride',
          isError: true,
        );
      }
    }
  }
}
