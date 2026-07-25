import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/booking.dart';
import '../../models/technician.dart';
import '../../core/theme/app_theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).fetchDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Operations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => adminProvider.fetchDashboardData(),
          ),
        ],
      ),
      body: adminProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Key Metrics Cards
                  const Text('Dashboard KPI Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _kpiCard(
                        'Total Orders',
                        '${adminProvider.bookings.length}',
                        Icons.receipt_long,
                        Colors.blue,
                      ),
                      const SizedBox(width: 12),
                      _kpiCard(
                        'Revenue',
                        '₹${_calculateRevenue(adminProvider.bookings)}',
                        Icons.payments,
                        AppTheme.success,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Text('Recent Repair Bookings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  // Bookings List
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: adminProvider.bookings.length,
                    itemBuilder: (context, index) {
                      final booking = adminProvider.bookings[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          title: Text(
                            '${booking.bookingId} - ${booking.customerName}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${booking.deviceBrand} ${booking.deviceModel} | ₹${booking.totalPrice.toStringAsFixed(0)}',
                          ),
                          trailing: Chip(
                            label: Text(booking.status, style: const TextStyle(color: Colors.white, fontSize: 11)),
                            backgroundColor: booking.status == 'Completed' ? AppTheme.success : Colors.orange,
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Services: ${booking.services.join(', ')}'),
                                  Text('Phone: ${booking.customerPhone}'),
                                  Text('Address: ${booking.address}'),
                                  Text('Slot: ${booking.preferredDate} (${booking.preferredTime})'),
                                  const SizedBox(height: 12),
                                  
                                  // Assign Tech Dropdown
                                  Row(
                                    children: [
                                      const Text('Technician: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: DropdownButton<int>(
                                          isExpanded: true,
                                          hint: Text(booking.technicianName ?? 'Unassigned'),
                                          items: adminProvider.technicians.map((Technician tech) {
                                            return DropdownMenuItem<int>(
                                              value: tech.id,
                                              child: Text(tech.name),
                                            );
                                          }).toList(),
                                          onChanged: (techId) {
                                            if (techId != null) {
                                              adminProvider.assignTechnician(booking.bookingId, techId);
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _kpiCard(String title, String val, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
            const SizedBox(height: 2),
            Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  String _calculateRevenue(List<Booking> bookings) {
    final sum = bookings
        .where((b) => b.status != 'Cancelled')
        .fold(0.0, (acc, b) => acc + b.totalPrice);
    return sum.toStringAsFixed(0);
  }
}
