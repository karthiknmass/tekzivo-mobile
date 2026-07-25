import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../core/theme/app_theme.dart';
import 'booking_form_screen.dart';

class ServiceSelectionScreen extends StatelessWidget {
  const ServiceSelectionScreen({super.key});

  IconData _getIconData(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'display':
      case 'screen':
        return Icons.smartphone;
      case 'battery':
        return Icons.battery_charging_full;
      case 'charging':
      case 'plug':
        return Icons.power;
      case 'camera':
        return Icons.photo_camera;
      case 'water':
        return Icons.water_drop;
      default:
        return Icons.build;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = Provider.of<BookingProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Services'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone_android, color: AppTheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selected Device',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          '${bookingProvider.selectedBrand?.name ?? ''} ${bookingProvider.selectedModel?.name ?? ''}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Required Services & Repairs',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Services List
            Expanded(
              child: ListView.builder(
                itemCount: bookingProvider.availableServices.length,
                itemBuilder: (context, index) {
                  final service = bookingProvider.availableServices[index];
                  final isSelected = bookingProvider.selectedServices.contains(service);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: CheckboxListTile(
                      value: isSelected,
                      onChanged: (_) => bookingProvider.toggleService(service),
                      activeColor: AppTheme.primary,
                      secondary: CircleAvatar(
                        backgroundColor: AppTheme.primary.withOpacity(0.1),
                        child: Icon(_getIconData(service.icon), color: AppTheme.primary),
                      ),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              service.title,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            '₹${service.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        '${service.description}\nEstimated Time: ${service.duration}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
            ),

            // Total & Checkout Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Price (${bookingProvider.selectedServices.length} items):',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '₹${bookingProvider.totalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: bookingProvider.selectedServices.isEmpty
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const BookingFormScreen()),
                            );
                          },
                    child: const Text('Proceed to Customer & Address Details'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
