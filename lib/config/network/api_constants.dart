class ApiConstants {
  // Authentication Endpoints
  static const String register = 'agents/auth/register/';
  static const String loginToken = 'agents/auth/verify-token/';
  static const String verifyPhone = 'agents/auth/verify-phone/';
  static const String logout = 'users/logout/';
  static const String projects = 'agents/projects/';
  static const String visits = 'agents/visits/';
  static const String createVisits = 'agents/visits/create/';
  static const String notificationRegisterDevice = 'agents/notifications/register-device/';
  static const String profileData = 'agents/profile/';
  
  // Customer Endpoints
  static const String customers = '/customers/';
  static const String documentUpload = 'agents/documents/upload/';
  static const String availablePlotsData = '/plots/';
  // static const String availablePlotsData = '/plots/?status=available';
  
  // Booking Endpoints
  static const String plotBookings = 'plot-bookings/';
  static const String plotHolds = 'plot-holds/';
  static const String holdsList = 'projects/plots/holds/';
  static const String bookingsList = 'projects/plots/bookings/';
  
  // Document Endpoints
  static const String plotHoldDocuments = 'plot-hold-documents/';
  static const String plotBookingDocuments = 'plot-booking-documents/';

  // Organization Endpoints
  static const String organization = 'organization/';
}