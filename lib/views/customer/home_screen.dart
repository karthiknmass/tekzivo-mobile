import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/brand.dart';
import '../../models/service_item.dart';
import '../technician/tech_dashboard_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import 'booking_status_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Smartphone',
    'Laptop',
    'LED TV',
    'Accessories & Gadgets',
  ];

  List<ServiceItem> _allServices = [];
  bool _isLoadingServices = true;
  List<Brand> _brands = [];

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    setState(() => _isLoadingServices = true);
    final s = await ApiService.getServices();
    final b = await ApiService.getBrands();
    setState(() {
      _allServices = s;
      _brands = b;
      _isLoadingServices = false;
    });
  }

  List<ServiceItem> get _filteredServices {
    if (_selectedCategory == 'All') {
      return _allServices;
    }
    return _allServices.where((s) => s.deviceType == _selectedCategory).toList();
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Smartphone':
        return Icons.smartphone;
      case 'Laptop':
        return Icons.laptop_chromebook;
      case 'LED TV':
        return Icons.tv;
      case 'Accessories & Gadgets':
        return Icons.headphones;
      default:
        return Icons.build;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.build_circle_outlined, color: Colors.amberAccent),
            SizedBox(width: 8),
            Text('TekzivoElectronics Care', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            onSelected: (val) {
              if (val == 'tech') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TechDashboardScreen()));
              } else if (val == 'admin') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
              } else if (val == 'track') {
                _showTrackDialog();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'track', child: Text('Track Order Status')),
              PopupMenuItem(value: 'tech', child: Text('Technician Portal')),
              PopupMenuItem(value: 'admin', child: Text('Admin Dashboard')),
            ],
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            children: [
              // Hero Banner matching Web App Royal Blue Gradient
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Premium Doorstep Repair Service',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Get expert repair solutions for your devices with quick turnaround times and fully certified technicians right at your doorstep.',
                      style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: const [
                        _BannerBadge(icon: '⚡', label: '2hr Doorstep Service'),
                        _BannerBadge(icon: '🛡️', label: '90-Day Warranty'),
                        _BannerBadge(icon: '👨‍🔧', label: 'Certified Technicians'),
                        _BannerBadge(icon: '💎', label: '100% Genuine Spares'),
                      ],
                    ),
                  ],
                ),
              ),

              // Horizontal Category Chips Bar
              Container(
                height: 52,
                color: Colors.white,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: Icon(_getCategoryIcon(cat), size: 16, color: isSelected ? Colors.white : AppTheme.primary),
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: AppTheme.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (sel) {
                          if (sel) setState(() => _selectedCategory = cat);
                        },
                      ),
                    );
                  },
                ),
              ),

              const Divider(height: 1),

              // Catalog Grid
              Expanded(
                child: _isLoadingServices
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredServices.isEmpty
                        ? const Center(child: Text('No services or spare parts available.'))
                        : RefreshIndicator(
                            onRefresh: _loadCatalog,
                            child: GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.70,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: _filteredServices.length,
                              itemBuilder: (context, index) {
                                final service = _filteredServices[index];
                                final isAccessory = service.deviceType == 'Accessories & Gadgets';

                                return Card(
                                  clipBehavior: Clip.antiAlias,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  child: InkWell(
                                    onTap: () => _openBookingModal(service),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Circular Icon Badge matching Web App (#E0F2FE)
                                          Container(
                                            width: 64,
                                            height: 64,
                                            decoration: const BoxDecoration(
                                              color: AppTheme.badgeBg,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Icon(
                                                _getCategoryIcon(service.deviceType),
                                                size: 32,
                                                color: AppTheme.primary,
                                              ),
                                            ),
                                          ),
                                          
                                          // Title
                                          Text(
                                            '${service.deviceType} - ${service.title}',
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, height: 1.2),
                                          ),

                                          // Price Section: "Starts at" + Price
                                          Column(
                                            children: [
                                              const Text(
                                                'Starts at',
                                                style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '₹${service.price.toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                  color: AppTheme.primary,
                                                ),
                                              ),
                                            ],
                                          ),

                                          // Book Service Gold Button (#D97706)
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.accent,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                              minimumSize: const Size(double.infinity, 38),
                                            ),
                                            onPressed: () => _openBookingModal(service),
                                            child: Text(
                                              isAccessory ? 'Buy Now' : 'Book Service',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openBookingModal(ServiceItem service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookingModalSheet(service: service, initialBrands: _brands),
    );
  }

  void _showTrackDialog() {
    final c = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Track Order Status'),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(hintText: 'Enter Reference (e.g. TKZ-00000)', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (c.text.trim().isNotEmpty) {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => BookingStatusScreen(bookingId: c.text.trim())));
              }
            },
            child: const Text('Track'),
          ),
        ],
      ),
    );
  }
}

class _BannerBadge extends StatelessWidget {
  final String icon;
  final String label;

  const _BannerBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// BOOKING / CHECKOUT MODAL SHEET
// ─────────────────────────────────────────
class BookingModalSheet extends StatefulWidget {
  final ServiceItem service;
  final List<Brand> initialBrands;

  const BookingModalSheet({super.key, required this.service, required this.initialBrands});

  @override
  State<BookingModalSheet> createState() => _BookingModalSheetState();
}

class _BookingModalSheetState extends State<BookingModalSheet> {
  final _formKey = GlobalKey<FormState>();

  List<Brand> _brands = [];
  bool _isLoadingBrands = false;
  Brand? _selectedBrand;

  List<DeviceModel> _models = [];
  bool _isLoadingModels = false;
  DeviceModel? _selectedModel;

  final _customBrandController = TextEditingController();
  final _customModelController = TextEditingController();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  bool _isCheckingPincode = false;
  bool? _isPincodeValid;
  String _pincodeMessage = '';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _brands = widget.initialBrands;
    _fetchBrands();
  }

  Future<void> _fetchBrands() async {
    setState(() => _isLoadingBrands = true);
    final b = await ApiService.getBrands();
    setState(() {
      _brands = b;
      _isLoadingBrands = false;
    });
  }

  Future<void> _onBrandSelected(Brand? brand) async {
    setState(() {
      _selectedBrand = brand;
      _selectedModel = null;
      _models = [];
    });

    if (brand != null) {
      setState(() => _isLoadingModels = true);
      final m = await ApiService.getModels(brand.id);
      setState(() {
        _models = m;
        _isLoadingModels = false;
      });
    }
  }

  Future<void> _checkPincode(String code) async {
    if (code.trim().length != 6) return;
    setState(() => _isCheckingPincode = true);

    final res = await ApiService.checkPincode(code.trim());
    final covered = (res['covered'] == true) || (res['serviceable'] == true);

    setState(() {
      _isCheckingPincode = false;
      _isPincodeValid = covered;
      if (covered) {
        final city = res['city'] ?? 'your city';
        _pincodeMessage = '✓ Doorstep repair available in $city!';
      } else {
        _pincodeMessage = '✕ ${res['message'] ?? 'Service not available in this pincode yet.'}';
      }
    });
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isPincodeValid == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doorstep repair is not available in this pincode')),
      );
      return;
    }

    final brandName = _selectedBrand?.name ?? _customBrandController.text.trim();
    final modelName = _selectedModel?.name ?? _customModelController.text.trim();

    if (brandName.isEmpty || modelName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or enter Brand and Model')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    String finalDesc = 'Brand: $brandName, Model: $modelName';
    if (_descriptionController.text.trim().isNotEmpty) {
      finalDesc += '\n\nDescription:\n${_descriptionController.text.trim()}';
    }

    final payload = {
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'pincode': _pincodeController.text.trim(),
      'address': _addressController.text.trim(),
      'device_type': widget.service.deviceType,
      'issue_type': widget.service.title,
      'service_id': widget.service.id,
      'issue_description': finalDesc,
      'preferred_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
      'time_slot': 'Anytime',
      'estimated_price': widget.service.price
    };

    final result = await ApiService.createBooking(payload);

    setState(() => _isSubmitting = false);

    if (result['success'] == true || result['data'] != null) {
      final data = result['data'] ?? result;
      final refCode = data['booking_ref'] ?? data['booking_id'] ?? 'TKZ-SUCCESS';
      Navigator.pop(context);
      _showSuccessDialog(refCode);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${result['error'] ?? result['message'] ?? 'Failed to book'}')),
      );
    }
  }

  void _showSuccessDialog(String refCode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: AppTheme.success,
              child: Icon(Icons.check, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'Booking Confirmed!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Our certified technician will arrive as scheduled.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    refCode,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppTheme.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20, color: AppTheme.primary),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: refCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Reference Code copied to clipboard!')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Book ${widget.service.title}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),

              // Selected Service Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${widget.service.deviceType} - ${widget.service.title}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    Text(
                      'Starts at ₹${widget.service.price.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 14),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Brand & Model Selection with Loader
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Device Brand *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 6),
                        _isLoadingBrands
                            ? const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                            : _brands.isEmpty
                                ? TextFormField(
                                    controller: _customBrandController,
                                    decoration: const InputDecoration(hintText: 'e.g. Apple, Samsung', border: OutlineInputBorder()),
                                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter brand' : null,
                                  )
                                : DropdownButtonFormField<Brand>(
                                    value: _selectedBrand,
                                    decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
                                    hint: const Text('Select Brand...'),
                                    items: _brands.map((b) => DropdownMenuItem(value: b, child: Text(b.name))).toList(),
                                    onChanged: _onBrandSelected,
                                    validator: (v) => _selectedBrand == null && _customBrandController.text.trim().isEmpty ? 'Select brand' : null,
                                  ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Device Model *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 6),
                        _isLoadingModels
                            ? const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                            : _models.isEmpty
                                ? TextFormField(
                                    controller: _customModelController,
                                    decoration: const InputDecoration(hintText: 'e.g. iPhone 14', border: OutlineInputBorder()),
                                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter model' : null,
                                  )
                                : DropdownButtonFormField<DeviceModel>(
                                    value: _selectedModel,
                                    decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
                                    hint: const Text('Select Model...'),
                                    items: _models.map((m) => DropdownMenuItem(value: m, child: Text(m.name))).toList(),
                                    onChanged: (val) => setState(() => _selectedModel = val),
                                    validator: (v) => _selectedModel == null && _customModelController.text.trim().isEmpty ? 'Select model' : null,
                                  ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name *', border: OutlineInputBorder()),
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter full name' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(labelText: '10-Digit Mobile Number *', border: OutlineInputBorder(), counterText: ''),
                validator: (v) => v == null || v.trim().length != 10 ? 'Enter valid 10-digit phone' : null,
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _pincodeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: InputDecoration(
                        labelText: 'Pincode *',
                        border: const OutlineInputBorder(),
                        counterText: '',
                        suffixIcon: _isCheckingPincode ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2)) : null,
                      ),
                      onChanged: (val) {
                        if (val.length == 6) _checkPincode(val);
                      },
                      validator: (v) => v == null || v.trim().length != 6 ? '6-digit pincode' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (d != null) setState(() => _selectedDate = d);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(DateFormat('dd MMM yyyy').format(_selectedDate), style: const TextStyle(fontSize: 13)),
                            const Icon(Icons.calendar_month, color: AppTheme.primary, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              if (_pincodeMessage.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  _pincodeMessage,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _isPincodeValid == true ? AppTheme.success : Colors.red,
                  ),
                ),
              ],

              const SizedBox(height: 12),

              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Full Address *', border: OutlineInputBorder()),
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter address' : null,
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Describe the Issue *', border: OutlineInputBorder()),
                validator: (v) => v == null || v.trim().isEmpty ? 'Describe the issue' : null,
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
                onPressed: _isSubmitting ? null : _submitBooking,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('CONFIRM BOOKING (Starts at ₹${widget.service.price.toStringAsFixed(0)})'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
