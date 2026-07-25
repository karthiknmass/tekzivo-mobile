import 'package:flutter/foundation.dart';
import '../models/booking.dart';
import '../models/technician.dart';
import '../core/services/api_service.dart';

class AdminProvider extends ChangeNotifier {
  List<Booking> _bookings = [];
  List<Technician> _technicians = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = false;

  List<Booking> get bookings => _bookings;
  List<Technician> get technicians => _technicians;
  Map<String, dynamic> get stats => _stats;
  bool get isLoading => _isLoading;

  Future<void> fetchDashboardData() async {
    _isLoading = true;
    notifyListeners();

    _bookings = await ApiService.getAllBookings();
    _technicians = await ApiService.getTechnicians();
    _stats = await ApiService.getDashboardStats();

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateBookingStatus(String bookingId, String newStatus) async {
    final success = await ApiService.updateBookingStatus(bookingId, newStatus);
    if (success) {
      await fetchDashboardData();
    }
    return success;
  }

  Future<bool> assignTechnician(String bookingId, int technicianId) async {
    final success = await ApiService.assignTechnician(bookingId, technicianId);
    if (success) {
      await fetchDashboardData();
    }
    return success;
  }
}
