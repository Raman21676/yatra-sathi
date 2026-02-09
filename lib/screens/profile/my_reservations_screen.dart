import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/loading_shimmer.dart';
import '../chat/chat_screen.dart';
import '../offers/offer_detail_screen.dart';

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({super.key});

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReservationProvider>(context, listen: false)
          .loadReservations();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reservations'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: Consumer<ReservationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.reservations.isEmpty) {
            return const LoadingShimmer();
          }

          if (provider.error != null && provider.reservations.isEmpty) {
            return _buildErrorView(provider);
          }

          return TabBarView(
            controller: _tabController,
            children: [
              // Active Tab
              _buildReservationsList(
                provider.activeReservations,
                isActive: true,
              ),
              // History Tab
              _buildReservationsList(
                provider.pastReservations,
                isActive: false,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorView(ReservationProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Failed to load reservations',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _loadReservations,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationsList(List<Reservation> reservations,
      {required bool isActive}) {
    if (reservations.isEmpty) {
      return _buildEmptyView(isActive: isActive);
    }

    return RefreshIndicator(
      onRefresh: _loadReservations,
      child: ListView.builder(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        itemCount: reservations.length,
        itemBuilder: (context, index) {
          return _buildReservationCard(reservations[index], isActive: isActive);
        },
      ),
    );
  }

  Widget _buildEmptyView({required bool isActive}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isActive ? Icons.event_seat_outlined : Icons.history,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            isActive ? 'No active reservations' : 'No reservation history',
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
              isActive
                  ? 'Book seats on available rides to see them here'
                  : 'Your completed and cancelled reservations will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ),
          if (isActive) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.search),
              label: const Text('Find Rides'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReservationCard(Reservation reservation, {required bool isActive}) {
    final offer = reservation.offer;

    if (offer == null) {
      return const SizedBox.shrink();
    }

    final isExpired = offer.isExpired;
    final isCancelled = reservation.status == 'cancelled';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showReservationDetails(reservation),
        borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isCancelled
                          ? Colors.red
                          : isExpired
                              ? Colors.grey
                              : const Color(UIConstants.successColor),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isCancelled
                          ? 'CANCELLED'
                          : isExpired
                              ? 'COMPLETED'
                              : 'CONFIRMED',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Booked ${Helpers.getRelativeTime(reservation.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
              // Date & Time
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    Helpers.formatDate(offer.leaveTime),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    Helpers.formatTime(offer.leaveTime),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              const Divider(height: 24),
              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${reservation.seatsReserved} seat(s)',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'Total: ${Helpers.formatCurrency(reservation.totalFare)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(UIConstants.primaryColor),
                        ),
                      ),
                    ],
                  ),
                  if (isActive && !isExpired && !isCancelled)
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _chatWithDriver(reservation),
                          icon: const Icon(Icons.chat, size: 18),
                          label: const Text('Chat'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _cancelReservation(reservation),
                          icon: const Icon(Icons.cancel, size: 18),
                          label: const Text('Cancel'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReservationDetails(Reservation reservation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(UIConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Reservation Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (reservation.offer != null) ...[
                  ListTile(
                    leading: const Icon(Icons.directions_car),
                    title: const Text('Vehicle'),
                    subtitle: Text(
                      '${reservation.offer!.vehicleType} - ${reservation.offer!.vehicleNumber}',
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.route),
                    title: const Text('Route'),
                    subtitle: Text(
                      '${reservation.offer!.fromLocation} → ${reservation.offer!.toLocation}',
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Departure'),
                    subtitle: Text(
                      Helpers.formatDateTime(reservation.offer!.leaveTime),
                    ),
                  ),
                ],
                ListTile(
                  leading: const Icon(Icons.event_seat),
                  title: const Text('Seats Booked'),
                  subtitle: Text('${reservation.seatsReserved}'),
                ),
                ListTile(
                  leading: const Icon(Icons.money),
                  title: const Text('Total Fare'),
                  subtitle: Text(
                    Helpers.formatCurrency(reservation.totalFare),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(UIConstants.primaryColor),
                    ),
                  ),
                ),
                if (reservation.offer?.owner != null)
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Driver'),
                    subtitle: Text(reservation.offer!.owner!.name),
                    trailing: IconButton(
                      icon: const Icon(Icons.phone),
                      onPressed: () {
                        // Call driver
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _chatWithDriver(Reservation reservation) {
    if (reservation.offer != null && reservation.offer!.owner != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            offer: reservation.offer!,
            receiver: reservation.offer!.owner!,
          ),
        ),
      );
    }
  }

  Future<void> _cancelReservation(Reservation reservation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Reservation'),
        content: const Text(
          'Are you sure you want to cancel this reservation? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Reservation'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Cancel Reservation'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = Provider.of<ReservationProvider>(context, listen: false);
      final success = await provider.cancelReservation(reservation.id);

      if (mounted) {
        if (success) {
          Helpers.showSnackBar(context, 'Reservation cancelled');
        } else {
          Helpers.showSnackBar(
            context,
            'Failed to cancel reservation',
            isError: true,
          );
        }
      }
    }
  }
}
