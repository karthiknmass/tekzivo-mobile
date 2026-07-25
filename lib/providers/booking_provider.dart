import 'package:flutter/foundation.dart';
import '../models/brand.dart';
import '../models/service_item.dart';
import '../models/booking.dart';
import '../core/services/api_service.dart';

class BookingProvider extends ChangeNotifier {
  String? _pincode;
  bool _isServiceable = false;
  String _serviceableMessage = '';
  bool _isLoadingPincode = false;

  Brand? _selectedBrand;
  DeviceModel? _selectedModel;
  final List<ServiceItem> _selectedServices = [];

  List<Brand> _brands = [];
  List<DeviceModel> _models = [];
  List<ServiceItem> _availableServices = [];
  bool _isLoadingCatalog = false;

  Booking? _currentBooking;

  // Getters
  String? get pincode => _pincode;
  bool get isServiceable => _isServiceable;
  String get serviceableMessage => _serviceableMessage;
  bool get isLoadingPincode => _isLoadingPincode;

  Brand? get selectedBrand => _selectedBrand;
  DeviceModel? get selectedModel => _selectedModel;
  List<ServiceItem> get selectedServices => List.unmodifiable(_selectedServices);

  List<Brand> get brands => _brands;
  List<DeviceModel> get models => _models;
  List<ServiceItem> get availableServices => _availableServices;
  bool get isLoadingCatalog => _isLoadingCatalog;

  Booking? get currentBooking => _currentBooking;

  double get totalPrice => _selectedServices.fold(0.0, (sum, item) => sum + item.price);

  // Actions
  Future<void> checkPincode(String pincode) async {
    _isLoadingPincode = true;
    _pincode = pincode;
    notifyListeners();

    final result = await ApiService.checkPincode(pincode);
    _isServiceable = (result['covered'] == true) || (result['serviceable'] == true);
    
    if (_isServiceable) {
      final city = result['city'] ?? '';
      final state = result['state'] ?? '';
      _serviceableMessage = 'Great news! Doorstep repair is available in ${city.isNotEmpty ? city : 'your area'} ($pincode).';
      loadCatalog();
    } else {
      _serviceableMessage = result['message'] ?? 'Sorry, service is not available in $pincode yet.';
    }

    _isLoadingPincode = false;
    notifyListeners();
  }

  Future<void> loadCatalog() async {
    _isLoadingCatalog = true;
    notifyListeners();

    _brands = await ApiService.getBrands();
    _availableServices = await ApiService.getServices();

    _isLoadingCatalog = false;
    notifyListeners();
  }

  Future<void> selectBrand(Brand brand) async {
    _selectedBrand = brand;
    _selectedModel = null;
    _models = await ApiService.getModels(brand.id);
    notifyListeners();
  }

  void selectModel(DeviceModel model) {
    _selectedModel = model;
    notifyListeners();
  }

  void toggleService(ServiceItem service) {
    if (_selectedServices.contains(service)) {
      _selectedServices.remove(service);
    } else {
      _selectedServices.add(service);
    }
    notifyListeners();
  }

  Future<bool> submitBooking({
    required String name,
    required String phone,
    required String email,
    required String address,
    required String preferredDate,
    required String preferredTime,
  }) async {
    if (_selectedBrand == null || _selectedModel == null || _selectedServices.isEmpty) {
      return false;
    }

    final payload = {
      'customer_name': name,
      'customer_phone': phone,
      'customer_email': email,
      'address': address,
      'pincode': _pincode ?? '',
      'device_brand': _selectedBrand!.name,
      'device_model': _selectedModel!.name,
      'services': _selectedServices.map((s) => s.title).toList(),
      'total_price': totalPrice,
      'preferred_date': preferredDate,
      'preferred_time': preferredTime,
    };

    final result = await ApiService.createBooking(payload);
    if (result['success'] == true) {
      final bookingId = result['booking_id'];
      _currentBooking = await ApiService.getBooking(bookingId);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> refreshCurrentBooking() async {
    if (_currentBooking != null) {
      _currentBooking = await ApiService.getBooking(_currentBooking!.bookingId);
      notifyListeners();
    }
  }

  void resetFlow() {
    _pincode = null;
    _isServiceable = false;
    _selectedBrand = null;
    _selectedModel = null;
    _selectedServices.clear();
    _currentBooking = null;
    notifyListeners();
  }
}
