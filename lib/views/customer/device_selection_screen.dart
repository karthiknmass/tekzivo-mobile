import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../models/brand.dart';
import '../../core/theme/app_theme.dart';
import 'service_selection_screen.dart';

class DeviceSelectionScreen extends StatelessWidget {
  const DeviceSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookingProvider = Provider.of<BookingProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Device'),
      ),
      body: bookingProvider.isLoadingCatalog
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Step 1 of 3: Select Brand & Model',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                  ),
                  const SizedBox(height: 12),
                  
                  // Brand Selector Header
                  const Text('Select Smartphone Brand', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  
                  // Brands Grid / List
                  SizedBox(
                    height: 90,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: bookingProvider.brands.length,
                      itemBuilder: (context, index) {
                        final brand = bookingProvider.brands[index];
                        final isSelected = bookingProvider.selectedBrand?.id == brand.id;
                        return GestureDetector(
                          onTap: () => bookingProvider.selectBrand(brand),
                          child: Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primary.withOpacity(0.1) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppTheme.primary : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.phone_iphone,
                                  color: isSelected ? AppTheme.primary : Colors.grey[700],
                                  size: 28,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  brand.name,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? AppTheme.primary : Colors.black87,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Model Selector
                  if (bookingProvider.selectedBrand != null) ...[
                    Text(
                      'Select ${bookingProvider.selectedBrand!.name} Model',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: bookingProvider.models.isEmpty
                          ? const Center(child: Text('No models found for this brand.'))
                          : GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 2.5,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                              itemCount: bookingProvider.models.length,
                              itemBuilder: (context, index) {
                                final model = bookingProvider.models[index];
                                final isSelected = bookingProvider.selectedModel?.id == model.id;
                                return InkWell(
                                  onTap: () => bookingProvider.selectModel(model),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppTheme.primary : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected ? AppTheme.primary : Colors.grey.shade300,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    alignment: Alignment.center,
                                    child: Text(
                                      model.name,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : Colors.black87,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ] else ...[
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Select a brand above to view available device models.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ],

                  // Next Button
                  if (bookingProvider.selectedModel != null) ...[
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ServiceSelectionScreen()),
                        );
                      },
                      child: Text('Next: Choose Repair Services (${bookingProvider.selectedModel!.name})'),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
