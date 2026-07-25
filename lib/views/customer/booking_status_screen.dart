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
      appBar: AppBar(
        title: const Text('Booking Status Tracking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBooking,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _booking == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off, size: 60, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text('Booking reference "${widget.bookingId}" not found.'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Go Back'),
                      ),
                    ],
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
                        Card(
                          color: AppTheme.secondary,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                const Text(
                                  'BOOKING REFERENCE',
                                  style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _booking!.bookingId,
                                  style: const TextStyle(
                                    color: AppTheme.accent,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(_booking!.status).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: _getStatusColor(_booking!.status)),
                                  ),
                                  child: Text(
                                    _booking!.status.toUpperCase(),
                                    style: TextStyle(
                                      color: _getStatusColor(_booking!.status),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Order Details Card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Order Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const Divider(),
                                _detailRow('Customer Name', _booking!.customerName),
                                _detailRow('Phone', _booking!.customerPhone),
                                _detailRow('Device', '${_booking!.deviceBrand} ${_booking!.deviceModel}'),
                                _detailRow('Scheduled Date', '${_booking!.preferredDate} (${_booking!.preferredTime})'),
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

  Widget _detailRow(String title, String val, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(title, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
          ),
          Expanded(
            child: Text(
              val,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                fontSize: isBold ? 16 : 14,
                color: isBold ? AppTheme.primary : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
