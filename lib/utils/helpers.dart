import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'constants.dart';

/// Helper class for common utilities
class Helpers {
  /// Format date to readable string
  static String formatDate(DateTime date, {String format = NepalConstants.dateFormat}) {
    return DateFormat(format).format(date);
  }

  /// Format time to readable string
  static String formatTime(DateTime time, {String format = NepalConstants.timeFormat}) {
    return DateFormat(format).format(time);
  }

  /// Format date and time together
  static String formatDateTime(DateTime dateTime) {
    return DateFormat(NepalConstants.dateTimeFormat).format(dateTime);
  }

  /// Format relative time (e.g., "2 hours ago")
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  /// Format currency in NPR
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      symbol: '${NepalConstants.currencySymbol} ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  /// Format number with commas
  static String formatNumber(int number) {
    return NumberFormat('#,###').format(number);
  }

  /// Validate Nepal phone number
  static bool isValidNepalPhone(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
    final regExp = RegExp(NepalConstants.phonePattern);
    return regExp.hasMatch(cleanPhone);
  }

  /// Format phone number to standard format
  static String formatPhoneNumber(String phone) {
    String cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    
    // Remove country code if present
    if (cleanPhone.startsWith('977')) {
      cleanPhone = cleanPhone.substring(3);
    }
    
    // Ensure it starts with 9
    if (!cleanPhone.startsWith('9')) {
      return phone; // Return as-is if invalid
    }
    
    // Format: +977 98X XXX XXXX
    if (cleanPhone.length == 10) {
      return '${NepalConstants.countryCode} ${cleanPhone.substring(0, 3)} ${cleanPhone.substring(3, 6)} ${cleanPhone.substring(6)}';
    }
    
    return '${NepalConstants.countryCode} $cleanPhone';
  }

  /// Validate email
  static bool isValidEmail(String email) {
    final regExp = RegExp(r'^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$');
    return regExp.hasMatch(email);
  }

  /// Validate password
  static bool isValidPassword(String password) {
    return password.length >= AppConstants.minPasswordLength;
  }

  /// Validate vehicle number (Nepal format)
  static bool isValidVehicleNumber(String number) {
    final regExp = RegExp(NepalConstants.vehicleNumberPattern);
    return regExp.hasMatch(number.toUpperCase().trim());
  }

  /// Get greeting based on time of day
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  /// Show snackbar
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(UIConstants.errorColor) : const Color(UIConstants.successColor),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.defaultRadius),
        ),
        margin: const EdgeInsets.all(UIConstants.defaultPadding),
      ),
    );
  }

  /// Show loading dialog
  static void showLoadingDialog(BuildContext context, {String message = 'Loading...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Text(message),
          ],
        ),
      ),
    );
  }

  /// Hide loading dialog
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  /// Calculate ride duration
  static String calculateDuration(DateTime leaveTime, DateTime reachTime) {
    final duration = reachTime.difference(leaveTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }

  /// Check if ride is expired
  static bool isRideExpired(DateTime leaveTime) {
    return leaveTime.isBefore(DateTime.now());
  }

  /// Get vehicle icon based on type
  static IconData getVehicleIcon(String vehicleType) {
    switch (vehicleType.toLowerCase()) {
      case 'car':
        return Icons.directions_car;
      case 'jeep':
        return Icons.local_taxi;
      case 'van':
        return Icons.airport_shuttle;
      case 'motorcycle':
        return Icons.motorcycle;
      case 'micro bus':
        return Icons.bus_alert;
      case 'bus':
        return Icons.directions_bus;
      default:
        return Icons.directions_car;
    }
  }

  /// Get status color
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'confirmed':
        return const Color(UIConstants.successColor);
      case 'cancelled':
      case 'expired':
        return const Color(UIConstants.errorColor);
      case 'pending':
        return const Color(UIConstants.warningColor);
      default:
        return Colors.grey;
    }
  }

  /// Capitalize first letter
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Truncate text with ellipsis
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}

/// Extension methods for DateTime
extension DateTimeExtension on DateTime {
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year && month == tomorrow.month && day == tomorrow.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }
}

/// Extension methods for String
extension StringExtension on String {
  String get capitalizeFirst {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }

  String get toTitleCase {
    return split(' ').map((word) => word.capitalizeFirst).join(' ');
  }
}
