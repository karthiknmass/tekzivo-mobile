class Booking {
  final String bookingId;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String address;
  final String pincode;
  final String deviceBrand;
  final String deviceModel;
  final List<String> services;
  final double totalPrice;
  final String preferredDate;
  final String preferredTime;
  final String status; // Pending, Confirmed, In Progress, Completed, Cancelled
  final String? technicianName;
  final String createdAt;

  Booking({
    required this.bookingId,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.address,
    required this.pincode,
    required this.deviceBrand,
    required this.deviceModel,
    required this.services,
    required this.totalPrice,
    required this.preferredDate,
    required this.preferredTime,
    required this.status,
    this.technicianName,
    required this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    List<String> parsedServices = [];
    if (json['services'] != null) {
      if (json['services'] is List) {
        parsedServices = List<String>.from(json['services']);
      } else if (json['services'] is String) {
        parsedServices = json['services'].toString().split(', ');
      }
    }

    return Booking(
      bookingId: json['booking_id'] ?? json['id'] ?? '',
      customerName: json['customer_name'] ?? json['name'] ?? '',
      customerPhone: json['customer_phone'] ?? json['phone'] ?? '',
      customerEmail: json['customer_email'] ?? json['email'] ?? '',
      address: json['address'] ?? '',
      pincode: json['pincode'] ?? '',
      deviceBrand: json['device_brand'] ?? json['brand'] ?? '',
      deviceModel: json['device_model'] ?? json['model'] ?? '',
      services: parsedServices,
      totalPrice: double.parse((json['total_price'] ?? json['price'] ?? 0).toString()),
      preferredDate: json['preferred_date'] ?? json['date'] ?? '',
      preferredTime: json['preferred_time'] ?? json['time'] ?? '',
      status: json['status'] ?? 'Pending',
      technicianName: json['technician_name'] ?? json['technician'],
      createdAt: json['created_at'] ?? '',
    );
  }
}
