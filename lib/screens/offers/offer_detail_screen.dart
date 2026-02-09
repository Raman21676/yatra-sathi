import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../chat/chat_screen.dart';

class OfferDetailScreen extends StatefulWidget {
  final VehicleOffer offer;

  const OfferDetailScreen({super.key, required this.offer});

  @override
  State<OfferDetailScreen> createState() => _OfferDetailScreenState();
}

class _OfferDetailScreenState extends State<OfferDetailScreen> {
  int _seatsToBook = 1;
  bool _isCheckingReservation = true;
  bool _hasReservation = false;
  Reservation? _existingReservation;

  @override
  void initState() {
    super.initState();
    _checkExistingReservation();
  }

  Future<void> _checkExistingReservation() async {
    final reservationProvider = Provider.of<ReservationProvider>(
      context,
      listen: false,
    );
    
    await reservationProvider.checkExistingReservation(widget.offer.id);
    
    if (mounted) {
      setState(() {
        _hasReservation = reservationProvider.hasExistingReservation;
        _existingReservation = reservationProvider.getReservationForOffer(
          widget.offer.id,
        );
        _isCheckingReservation = false;
      });
    }
  }

  Future<void> _bookSeats() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final reservationProvider = Provider.of<ReservationProvider>(
      context,
      listen: false,
    );
    final offerProvider = Provider.of<OfferProvider>(context, listen: false);

    // Check if user is logged in
    if (authProvider.user == null) {
      Helpers.showSnackBar(
        context,
        'Please login to book seats',
        isError: true,
      );
      return;
    }

    // Check if user is the owner
    if (widget.offer.ownerId == authProvider.user!.id) {
      Helpers.showSnackBar(
        context,
        'You cannot book your own ride',
        isError: true,
      );
      return;
    }

    // Check if enough seats available
    if (_seatsToBook > widget.offer.seatsAvailable) {
      Helpers.showSnackBar(
        context,
        'Only ${widget.offer.seatsAvailable} seats available',
        isError: true,
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Seats: $_seatsToBook'),
            Text(
              'Total: ${Helpers.formatCurrency(widget.offer.fare * _seatsToBook)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Note: This is a reservation. Payment will be handled directly with the driver.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Book the seats
    final response = await reservationProvider.bookReservation(
      offerId: widget.offer.id,
      seatsReserved: _seatsToBook,
    );

    if (!mounted) return;

    if (response.success) {
      // Update available seats locally
      offerProvider.updateAvailableSeats(widget.offer.id, -_seatsToBook);
      
      setState(() {
        _hasReservation = true;
        _existingReservation = response.reservation;
      });

      Helpers.showSnackBar(context, 'Booking confirmed!');
    } else {
      Helpers.showSnackBar(
        context,
        response.message,
        isError: true,
      );
    }
  }

  Future<void> _cancelReservation() async {
    if (_existingReservation == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text(
          'Are you sure you want to cancel this booking?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final reservationProvider = Provider.of<ReservationProvider>(
      context,
      listen: false,
    );
    final offerProvider = Provider.of<OfferProvider>(context, listen: false);

    final success = await reservationProvider.cancelReservation(
      _existingReservation!.id,
    );

    if (!mounted) return;

    if (success) {
      // Update available seats locally
      offerProvider.updateAvailableSeats(
        widget.offer.id,
        _existingReservation!.seatsReserved,
      );

      setState(() {
        _hasReservation = false;
        _existingReservation = null;
      });

      Helpers.showSnackBar(context, 'Booking cancelled');
    } else {
      Helpers.showSnackBar(
        context,
        'Failed to cancel booking',
        isError: true,
      );
    }
  }

  void _startChat() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.user == null) {
      Helpers.showSnackBar(
        context,
        'Please login to chat',
        isError: true,
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          offer: widget.offer,
          receiver: widget.offer.owner,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isOwner = widget.offer.ownerId == authProvider.user?.id;
    final isExpired = widget.offer.isExpired;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: CachedNetworkImage(
                imageUrl: widget.offer.vehiclePhoto,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.error),
                ),
              ),
            ),
            actions: [
              if (isOwner)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // Navigate to edit screen
                  },
                ),
            ],
          ),
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(UIConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isExpired
                              ? Colors.red
                              : const Color(UIConstants.successColor),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isExpired ? 'EXPIRED' : 'ACTIVE',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(UIConstants.primaryColor)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Helpers.getVehicleIcon(widget.offer.vehicleType),
                              size: 16,
                              color: const Color(UIConstants.primaryColor),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.offer.vehicleType,
                              style: const TextStyle(
                                color: Color(UIConstants.primaryColor),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Route
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.offer.fromLocation,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Departure',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(UIConstants.primaryColor)
                                  .withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward,
                              color: Color(UIConstants.primaryColor),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            Helpers.calculateDuration(
                              widget.offer.leaveTime,
                              widget.offer.reachTime,
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              widget.offer.toLocation,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Destination',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  // Date & Time
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.calendar_today,
                          title: 'Date',
                          value: Helpers.formatDate(widget.offer.leaveTime),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.access_time,
                          title: 'Departure',
                          value: Helpers.formatTime(widget.offer.leaveTime),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.schedule,
                          title: 'Arrival',
                          value: Helpers.formatTime(widget.offer.reachTime),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.event_seat,
                          title: 'Available Seats',
                          value: '${widget.offer.seatsAvailable}/${widget.offer.seatsTotal}',
                          valueColor: widget.offer.seatsAvailable > 0
                              ? const Color(UIConstants.successColor)
                              : const Color(UIConstants.errorColor),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  // Price
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(UIConstants.primaryColor)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        UIConstants.defaultRadius,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Fare per seat',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              Helpers.formatCurrency(widget.offer.fare),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(UIConstants.primaryColor),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(UIConstants.primaryColor),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.offer.vehicleNumber,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Description
                  if (widget.offer.description != null &&
                      widget.offer.description!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.offer.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Driver Info
                  if (widget.offer.owner != null) ...[
                    const Text(
                      'Driver Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: widget.offer.owner!.photo.isNotEmpty
                              ? NetworkImage(widget.offer.owner!.photo)
                              : null,
                          child: widget.offer.owner!.photo.isEmpty
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(widget.offer.owner!.name),
                        subtitle: Text(
                          'Contact: ${Helpers.formatPhoneNumber(widget.offer.contactNumber)}',
                        ),
                        trailing: !isOwner
                            ? IconButton(
                                icon: const Icon(Icons.chat),
                                onPressed: _startChat,
                              )
                            : null,
                      ),
                    ),
                  ],
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      // Bottom Booking Bar
      bottomNavigationBar: _buildBottomBar(isOwner, isExpired),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(UIConstants.smallRadius),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: valueColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isOwner, bool isExpired) {
    if (isOwner) {
      return SafeArea(
        child: Container(
          padding: const EdgeInsets.all(UIConstants.defaultPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Edit offer
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // View bookings
                  },
                  icon: const Icon(Icons.people),
                  label: const Text('View Bookings'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isExpired) {
      return SafeArea(
        child: Container(
          padding: const EdgeInsets.all(UIConstants.defaultPadding),
          color: Colors.red[50],
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text(
                'This ride has expired',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      );
    }

    if (_isCheckingReservation) {
      return const SizedBox.shrink();
    }

    if (_hasReservation && _existingReservation != null) {
      return SafeArea(
        child: Container(
          padding: const EdgeInsets.all(UIConstants.defaultPadding),
          decoration: BoxDecoration(
            color: const Color(UIConstants.successColor).withOpacity(0.1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(UIConstants.successColor),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You have booked ${_existingReservation!.seatsReserved} seat(s)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(UIConstants.successColor),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _startChat,
                      icon: const Icon(Icons.chat),
                      label: const Text('Chat with Driver'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _cancelReservation,
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      label: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // No reservation - show booking UI
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.offer.seatsAvailable > 0) ...[
              Row(
                children: [
                  const Text(
                    'Seats to book:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: _seatsToBook > 1
                              ? () => setState(() => _seatsToBook--)
                              : null,
                        ),
                        Text(
                          '$_seatsToBook',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: _seatsToBook < widget.offer.seatsAvailable
                              ? () => setState(() => _seatsToBook++)
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Total: ${Helpers.formatCurrency(widget.offer.fare * _seatsToBook)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.offer.seatsAvailable > 0
                    ? _bookSeats
                    : null,
                child: Text(
                  widget.offer.seatsAvailable > 0
                      ? 'Book Now'
                      : 'No Seats Available',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
