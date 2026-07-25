class ApiConstants {
  // Replace with your server URL when running on device or PythonAnywhere live host
  // For Android Emulator to access host machine localhost, use 10.0.2.2
  // For PythonAnywhere host: https://karthikeyankasi.pythonanywhere.com/api
  static const String baseUrl = 'http://192.168.29.101:5000/api';

  static const String checkPincode = '$baseUrl/check-pincode';
  static const String services = '$baseUrl/services';
  static const String brands = '$baseUrl/brands';
  static const String models = '$baseUrl/models';
  static const String bookings = '$baseUrl/bookings';
  static const String technicians = '$baseUrl/technicians';
  static const String dashboardStats = '$baseUrl/dashboard/stats';
  static const String settings = '$baseUrl/settings';
  static const String serviceAreas = '$baseUrl/service-areas';
}
