import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/booking_provider.dart';
import '../../core/theme/app_theme.dart';
import 'booking_status_screen.dart';

class BookingFormScreen extends StatefulWidget {
  const BookingFormScreen({super.key});

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedSlot = '10:00 AM - 01:00 PM';
  bool _isSubmitting = false;

  final List<String> _timeSlots = [
    '09:00 AM - 12:00 PM',
    '12:00 PM - 03:00 PM',
    '03:00 PM - 06:00 PM',
    '06:00 PM - 08:00 PM',
  ];

  @override
  Widget build(BuildContext context) {
    final bookingProvider = Provider.of<BookingProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer & Slot Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Step 3 of 3: Enter Repair Details',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
              const SizedBox(height: 16),

              // Contact Info Section
              const Text('Customer Contact Info', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter your full name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
                validator: (v) => v == null || v.trim().length < 10 ? 'Enter valid 10-digit phone' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
                validator: (v) => v == null || !v.contains('@') ? 'Enter valid email address' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Doorstep Repair Address', border: OutlineInputBorder(), prefixIcon: Icon(Icons.home)),
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter full address' : null,
              ),

              const SizedBox(height: 24),

              // Schedule Date & Slot Section
              const Text('Select Date & Time Slot', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              
              // Date Picker Button
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Date: ${DateFormat('EEE, dd MMM yyyy').format(_selectedDate)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Icon(Icons.calendar_month, color: AppTheme.primary),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),
              const Text('Time Slot:', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _timeSlots.map((slot) {
                  final isSelected = _selectedSlot == slot;
                  return ChoiceChip(
                    label: Text(slot),
                    selected: isSelected,
                    selectedColor: AppTheme.primary,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _selectedSlot = slot;
                        });
                      }
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            _isSubmitting = true;
                          });

                          final success = await bookingProvider.submitBooking(
                            name: _nameController.text.trim(),
                            phone: _phoneController.text.trim(),
                            email: _emailController.text.trim(),
                            address: _addressController.text.trim(),
                            preferredDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
                            preferredTime: _selectedSlot,
                          );

                          setState(() {
                            _isSubmitting = false;
                          });

                          if (success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Booking Confirmed Successfully!')),
                            );
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BookingStatusScreen(
                                  bookingId: bookingProvider.currentBooking?.bookingId ?? '',
                                ),
                              ),
                              (route) => route.isFirst,
                            );
                          } else if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed to submit booking. Try again.')),
                            );
                          }
                        }
                      },
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('Confirm Booking (₹${bookingProvider.totalPrice.toStringAsFixed(0)})'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
