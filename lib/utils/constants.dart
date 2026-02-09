/// API Configuration Constants
class ApiConstants {
  // Base URL - Change this to your backend URL
  // For local development with emulator: use 10.0.2.2 instead of localhost
  static const String baseUrl = 'http://10.0.2.2:5000';
  static const String apiUrl = '$baseUrl/api';
  static const String socketUrl = baseUrl;

  // API Endpoints
  static const String auth = '/auth';
  static const String offers = '/offers';
  static const String reservations = '/reservations';
  static const String chat = '/chat';
  static const String health = '/health';

  // Auth Endpoints
  static const String login = '$auth/login';
  static const String register = '$auth/register';
  static const String me = '$auth/me';
  static const String updateProfile = '$auth/profile';
  static const String changePassword = '$auth/password';

  // Offer Endpoints
  static const String listOffers = offers;
  static const String createOffer = offers;
  static String offerDetail(String id) => '$offers/$id';
  static String updateOffer(String id) => '$offers/$id';
  static String deleteOffer(String id) => '$offers/$id';

  // Reservation Endpoints
  static const String listReservations = reservations;
  static const String bookReservation = reservations;
  static String cancelReservation(String id) => '$reservations/$id/cancel';

  // Chat Endpoints
  static String chatHistory(String offerId) => '$chat/$offerId';
  static const String conversations = '$chat/conversations';

  // Timeouts
  static const int connectTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
  static const int sendTimeout = 30000; // 30 seconds
}

/// App Constants
class AppConstants {
  // App Info
  static const String appName = 'Yatra Sathi';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Your Trusted Travel Companion';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String firstLaunchKey = 'first_launch';

  // Pagination
  static const int defaultPageSize = 10;

  // Image Upload
  static const int maxImageSizeMB = 5;
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png'];

  // Validation
  static const int minPasswordLength = 6;
  static const int maxNameLength = 50;
  static const int maxDescriptionLength = 500;
  static const int maxMessageLength = 1000;

  // Vehicle Types
  static const List<String> vehicleTypes = [
    'Car',
    'Jeep',
    'Van',
    'Motorcycle',
    'Micro Bus',
    'Bus',
  ];

  // Nepal Locations (Popular)
  static const List<String> popularLocations = [
    'Kathmandu',
    'Pokhara',
    'Lalitpur',
    'Bhaktapur',
    'Chitwan',
    'Lumbini',
    'Janakpur',
    'Birgunj',
    'Biratnagar',
    'Nepalgunj',
    'Dharan',
    'Butwal',
    'Hetauda',
    'Dhangadhi',
    'Itahari',
  ];
}

/// Nepal-specific Constants
class NepalConstants {
  // Country Code
  static const String countryCode = '+977';
  static const String currency = 'NPR';
  static const String currencySymbol = 'Rs.';

  // Phone Validation
  static const String phonePattern = r'^(\+977)?[9][6-9]\d{8}$';
  static const String phoneHint = '98XXXXXXXX';

  // Vehicle Number Pattern (Basic)
  static const String vehicleNumberPattern = r'^[A-Z]{2}\s?\d{1,2}\s?[A-Z]{1,3}\s?\d{1,4}$';

  // Date Format
  static const String dateFormat = 'yyyy-MM-dd';
  static const String timeFormat = 'hh:mm a';
  static const String dateTimeFormat = 'yyyy-MM-dd hh:mm a';
}

/// UI Constants
class UIConstants {
  // Colors (Nepal Theme)
  static const int primaryColor = 0xFF003893; // Nepal Blue
  static const int accentColor = 0xFFDC143C; // Nepal Crimson
  static const int secondaryColor = 0xFF1E88E5;
  static const int successColor = 0xFF4CAF50;
  static const int warningColor = 0xFFFF9800;
  static const int errorColor = 0xFFE53935;
  static const int backgroundColor = 0xFFF5F5F5;
  static const int surfaceColor = 0xFFFFFFFF;

  // Spacing
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  // Border Radius
  static const double defaultRadius = 12.0;
  static const double smallRadius = 8.0;
  static const double largeRadius = 16.0;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
}

/// Socket Events
class SocketEvents {
  // Connection
  static const String connect = 'connect';
  static const String disconnect = 'disconnect';
  static const String connectError = 'connect_error';

  // Chat Events - Client to Server
  static const String joinChat = 'join-chat';
  static const String leaveChat = 'leave-chat';
  static const String sendMessage = 'send-message';
  static const String typing = 'typing';
  static const String stopTyping = 'stop-typing';

  // Chat Events - Server to Client
  static const String newMessage = 'new-message';
  static const String userJoined = 'user-joined';
  static const String userTyping = 'user-typing';
  static const String userStopTyping = 'user-stop-typing';
  static const String messageNotification = 'message-notification';
  static const String error = 'error';
}
