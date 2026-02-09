import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/offer_card.dart';
import '../../widgets/loading_shimmer.dart';

class OffersListScreen extends StatelessWidget {
  const OffersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OfferProvider>(
      builder: (context, offerProvider, child) {
        if (offerProvider.isLoading && offerProvider.offers.isEmpty) {
          return const LoadingShimmer();
        }

        if (offerProvider.error != null && offerProvider.offers.isEmpty) {
          return _buildErrorView(context, offerProvider);
        }

        if (offerProvider.offers.isEmpty) {
          return _buildEmptyView(context);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(UIConstants.defaultPadding),
          itemCount: offerProvider.offers.length,
          itemBuilder: (context, index) {
            final offer = offerProvider.offers[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OfferCard(
                offer: offer,
                onTap: () => _navigateToDetail(context, offer),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildErrorView(BuildContext context, OfferProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.error ?? 'Failed to load offers',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => provider.loadOffers(refresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_taxi_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No rides available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to post a ride!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed('/post-offer');
              },
              icon: const Icon(Icons.add),
              label: const Text('Post a Ride'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, VehicleOffer offer) {
    // Navigate to offer detail
    Navigator.of(context).pushNamed('/offer-detail', arguments: offer);
  }
}
