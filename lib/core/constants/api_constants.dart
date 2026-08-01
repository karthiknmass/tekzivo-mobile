import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  // Live Production URL Path
  static const String baseUrl = 'https://karthikeyankasi.pythonanywhere.com/api';

  
  // Local Backend URLs (Commented out)
  // static String get baseUrl {
  //   if (kIsWeb) {
  //     return 'http://localhost:5000/api';
  //   } else if (Platform.isAndroid) {
  //     return 'http://10.0.2.2:5000/api'; // Android Emulator bridge
  //   } else {
  //     return 'http://127.0.0.1:5000/api'; // iOS Simulator or desktop
  //   }
  // }
  
  

  static String get checkPincode => '$baseUrl/check-pincode';
  static String get services => '$baseUrl/services';
  static String get brands => '$baseUrl/brands';
  static String get models => '$baseUrl/models';
  static String get bookings => '$baseUrl/bookings';
  static String get technicians => '$baseUrl/technicians';
  static String get dashboardStats => '$baseUrl/dashboard/stats';
  static String get settings => '$baseUrl/settings';
  static String get serviceAreas => '$baseUrl/service-areas';
}
