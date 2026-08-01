import 'package:flutter/material.dart';
import '../../models/booking.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';

class BookingStatusScreen extends StatefulWidget {
  final String bookingId;

  const BookingStatusScreen({super.key, required this.bookingId});

  @override
  State<BookingStatusScreen> createState() => _BookingStatusScreenState();
}

class _BookingStatusScreenState extends State<BookingStatusScreen> {
  Booking? _booking;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    setState(() => _isLoading = true);
    final b = await ApiService.getBooking(widget.bookingId);
    setState(() {
      _booking = b;
      _isLoading = false;
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.blue;
      case 'in progress':
        return Colors.orange;
      case 'completed':
        return AppTheme.success;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Track Shipment'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _loadBooking,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _booking == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.search_off, size: 64, color: Colors.red.shade400),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Reference Code Not Found',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'We couldn\'t find any records matching "${widget.bookingId}". Please verify your reference code.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Go Back'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadBooking,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header Status Card
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: AppTheme.premiumShadow,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                const Text(
                                  'BOOKING REFERENCE',
                                  style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _booking!.bookingId,
                                  style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(_booking!.status).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: _getStatusColor(_booking!.status).withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    _booking!.status.toUpperCase(),
                                    style: TextStyle(
                                      color: _getStatusColor(_booking!.status),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Interactive Timeline
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: AppTheme.premiumShadow,
                          ),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Live Progress Tracking',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              const SizedBox(height: 24),
                              _buildTimeline(context, _booking!.status.toLowerCase()),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Order Details Card
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: AppTheme.premiumShadow,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Order Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                                const SizedBox(height: 8),
                                const Divider(color: Color(0xFFF1F5F9)),
                                const SizedBox(height: 8),
                                _detailRow('Customer Name', _booking!.customerName),
                                _detailRow('Phone', _booking!.customerPhone),
                                _detailRow('Device', '${_booking!.deviceBrand} ${_booking!.deviceModel}'),
                                _detailRow('Scheduled Date', '${_booking!.preferredDate} (${_booking!.preferredTime})'),
                                const SizedBox(height: 4),
                                const Divider(color: Color(0xFFF1F5F9)),
                                const SizedBox(height: 8),
                                _detailRow('Estimated Price', '₹${_booking!.totalPrice.toStringAsFixed(0)}', isBold: true),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildTimeline(BuildContext context, String currentStatus) {
    bool isStep1 = true; // Booking Confirmed (always true once booked)
    bool isStep2 = currentStatus == 'in progress' || currentStatus == 'completed'; // Tech Assigned
    bool isStep3 = currentStatus == 'in progress' || currentStatus == 'completed'; // Repairing
    bool isStep4 = currentStatus == 'completed'; // Completed

    return Column(
      children: [
        _buildTimelineStep(
          title: 'Booking Confirmed',
          subtitle: 'Your request has been successfully registered in our database.',
          isActive: isStep1,
          isLast: false,
        ),
        _buildTimelineStep(
          title: 'Technician Dispatched',
          subtitle: 'A certified service expert has been assigned and is heading over.',
          isActive: isStep2,
          isLast: false,
        ),
        _buildTimelineStep(
          title: 'Repair In Progress',
          subtitle: 'The repair is currently being performed at your doorstep.',
          isActive: isStep3,
          isLast: false,
        ),
        _buildTimelineStep(
          title: 'Completed',
          subtitle: 'The device is repaired, tested, and handed back to you.',
          isActive: isStep4,
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    required bool isActive,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? AppTheme.primary : const Color(0xFFF1F5F9),
                border: Border.all(
                  color: isActive ? AppTheme.primary.withOpacity(0.2) : const Color(0xFFE2E8F0),
                  width: 4,
                ),
              ),
              child: Icon(
                Icons.check,
                size: 10,
                color: isActive ? Colors.white : Colors.transparent,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 48,
                color: isActive ? AppTheme.primary : const Color(0xFFE2E8F0),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isActive ? Colors.black87 : Colors.black38,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isActive ? Colors.grey.shade600 : Colors.grey.shade400,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailRow(String title, String val, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(
              val,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                fontSize: isBold ? 16 : 14,
                color: isBold ? AppTheme.accent : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
