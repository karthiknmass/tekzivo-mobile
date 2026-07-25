import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../../models/brand.dart';
import '../../models/service_item.dart';
import '../../models/booking.dart';
import '../../models/technician.dart';

class ApiService {
  // Check service availability by Pincode against Flask /api/check-pincode/<pincode>
  static Future<Map<String, dynamic>> checkPincode(String pincode) async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.checkPincode}/$pincode'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        if (body.containsKey('data') && body['data'] is Map<String, dynamic>) {
          return Map<String, dynamic>.from(body['data']);
        }
        return body;
      } else {
        return {'covered': false, 'message': 'Pincode not serviceable'};
      }
    } catch (e) {
      return {'covered': false, 'message': 'Network error connecting to API: $e'};
    }
  }

  // Fetch Brands from Flask /api/brands
  static Future<List<Brand>> getBrands() async {
    try {
      final response = await http.get(Uri.parse(ApiConstants.brands));
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        final List data = body['data'] ?? body['brands'] ?? (body is List ? body : []);
        return data.map((j) => Brand.fromJson(j)).toList();
      }
    } catch (e) {
      print('Error fetching brands: $e');
    }
    return [];
  }

  // Fetch Models for Brand from Flask /api/models?brand_id=...
  static Future<List<DeviceModel>> getModels(int brandId) async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.models}?brand_id=$brandId'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        final List data = body['data'] ?? (body is List ? body : []);
        return data.map((j) => DeviceModel.fromJson(j)).toList();
      }
    } catch (e) {
      print('Error fetching models: $e');
    }
    return [];
  }

  // Fetch Services Catalog from Flask /api/services
  static Future<List<ServiceItem>> getServices() async {
    try {
      final response = await http.get(Uri.parse(ApiConstants.services));
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        final List data = body['data'] ?? [];
        return data.map((j) => ServiceItem.fromJson(j)).toList();
      }
    } catch (e) {
      print('Error fetching services: $e');
    }
    return [];
  }

  // Upload Image File to Flask /api/upload
  static Future<String?> uploadImage(File file) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('${ApiConstants.baseUrl}/upload'));
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final res = json.decode(response.body);
        if (res['success'] == true) {
          return res['data']['file_path'];
        }
      }
    } catch (e) {
      print('Upload error: $e');
    }
    return null;
  }

  // Create Booking via Flask POST /api/bookings
  static Future<Map<String, dynamic>> createBooking(Map<String, dynamic> bookingPayload) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.bookings),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(bookingPayload),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get Booking Status by ID or Ref Code
  static Future<Booking?> getBooking(String bookingId) async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.bookings}/$bookingId'));
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['data'] != null) {
          return Booking.fromJson(body['data']);
        }
      }
    } catch (e) {
      print('Error fetching booking: $e');
    }
    return null;
  }

  // Get All Bookings (Admin / Tech)
  static Future<List<Booking>> getAllBookings() async {
    try {
      final response = await http.get(Uri.parse(ApiConstants.bookings));
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        final List data = body['data'] ?? [];
        return data.map((j) => Booking.fromJson(j)).toList();
      }
    } catch (e) {
      print('Error fetching bookings: $e');
    }
    return [];
  }

  // Update Booking Status
  static Future<bool> updateBookingStatus(String bookingId, String status) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConstants.bookings}/$bookingId/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': status}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Assign Technician to Booking
  static Future<bool> assignTechnician(String bookingId, int technicianId) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConstants.bookings}/$bookingId/assign'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'technician_id': technicianId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Get Technicians List
  static Future<List<Technician>> getTechnicians() async {
    try {
      final response = await http.get(Uri.parse(ApiConstants.technicians));
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        final List data = body['data'] ?? [];
        return data.map((j) => Technician.fromJson(j)).toList();
      }
    } catch (e) {
      print('Error fetching technicians: $e');
    }
    return [];
  }

  // Get Dashboard Stats
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await http.get(Uri.parse(ApiConstants.dashboardStats));
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        return body['data'] ?? {};
      }
    } catch (e) {
      print('Error fetching dashboard stats: $e');
    }
    return {};
  }
}
