import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/brand.dart';
import '../../models/service_item.dart';
import '../technician/tech_dashboard_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'booking_status_screen.dart';

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

IconData _getServiceIcon(String title, String deviceType) {
  final lowerTitle = title.toLowerCase();
  
  if (lowerTitle.contains('screen') || lowerTitle.contains('panel') || lowerTitle.contains('display')) {
    return Icons.screenshot_outlined;
  } else if (lowerTitle.contains('battery')) {
    return Icons.battery_charging_full_outlined;
  } else if (lowerTitle.contains('charging') || lowerTitle.contains('port')) {
    return Icons.power_outlined;
  } else if (lowerTitle.contains('keyboard')) {
    return Icons.keyboard_outlined;
  } else if (lowerTitle.contains('motherboard') || lowerTitle.contains('board') || lowerTitle.contains('turn on')) {
    return Icons.developer_board_outlined;
  } else if (lowerTitle.contains('sound') || lowerTitle.contains('speaker') || lowerTitle.contains('audio') || lowerTitle.contains('voice')) {
    return Icons.volume_up_outlined;
  } else if (lowerTitle.contains('headset') || lowerTitle.contains('headphones') || lowerTitle.contains('bluetooth')) {
    return Icons.headphones_outlined;
  } else if (lowerTitle.contains('power bank')) {
    return Icons.battery_saver_outlined;
  }
  
  // Fallback to category level icon
  switch (deviceType) {
    case 'Smartphone':
      return Icons.smartphone_outlined;
    case 'Laptop':
      return Icons.laptop_chromebook_outlined;
    case 'LED TV':
      return Icons.tv_outlined;
    case 'Accessories & Gadgets':
      return Icons.headphones_outlined;
    default:
      return Icons.build_circle_outlined;
  }
}

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
  final List<ServiceItem> _cart = [];
  int _currentTabIndex = 0;
  final _trackController = TextEditingController();
  final _cartNameController = TextEditingController();
  final _cartPhoneController = TextEditingController();
  final _cartAddressController = TextEditingController();
  final _cartFormKey = GlobalKey<FormState>();
  bool _isCartCheckingOut = false;

  Timer? _statusPollingTimer;
  bool _hasNewNotifications = false;
  List<String> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadCatalog();
    _loadNotifications();
    _startStatusPolling();
    _requestNotificationPermission();
  }

  @override
  void dispose() {
    _statusPollingTimer?.cancel();
    super.dispose();
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

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifications = prefs.getStringList('user_notifications') ?? [];
      _hasNewNotifications = prefs.getBool('has_new_notifications') ?? false;
    });
  }

  void _startStatusPolling() {
    // Poll every 8 seconds for rapid response during tests & demos
    _statusPollingTimer = Timer.periodic(const Duration(seconds: 8), (_) => _checkBookingStatuses());
  }

  Future<void> _checkBookingStatuses() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> bookings = prefs.getStringList('my_bookings') ?? [];
    if (bookings.isEmpty) return;

    final Map<String, String> cachedStatuses = Map<String, String>.from(
      json.decode(prefs.getString('booking_statuses') ?? '{}'),
    );
    final List<String> currentNotifications = prefs.getStringList('user_notifications') ?? [];
    bool statusChanged = false;
    bool hasNew = prefs.getBool('has_new_notifications') ?? false;

    for (final ref in bookings) {
      final booking = await ApiService.getBooking(ref);
      if (booking != null) {
        final lastStatus = cachedStatuses[ref];
        final currentStatus = booking.status;
        
        if (lastStatus == null) {
          cachedStatuses[ref] = currentStatus;
          statusChanged = true;
        } else if (lastStatus.toLowerCase() != currentStatus.toLowerCase()) {
          cachedStatuses[ref] = currentStatus;
          statusChanged = true;
          hasNew = true;
          
          final msg = 'Booking $ref status updated to $currentStatus';
          if (!currentNotifications.contains(msg)) {
            currentNotifications.insert(0, msg);
            _showSystemNotification(msg);
          }
        }
      }
    }

    if (statusChanged) {
      await prefs.setString('booking_statuses', json.encode(cachedStatuses));
      await prefs.setStringList('user_notifications', currentNotifications);
      await prefs.setBool('has_new_notifications', hasNew);
      
      if (mounted) {
        setState(() {
          _notifications = currentNotifications;
          _hasNewNotifications = hasNew;
        });
      }
    }
  }

  void _requestNotificationPermission() {
    if (kIsWeb) {
      try {
        if (html.Notification.permission != "granted" && html.Notification.permission != "denied") {
          html.Notification.requestPermission();
        }
      } catch (e) {
        print('Error requesting notification permission: $e');
      }
    }
  }

  void _showSystemNotification(String message) {
    if (kIsWeb) {
      try {
        if (html.Notification.permission == "granted") {
          html.Notification("Tekzivo Electronics Care", body: message);
        }
      } catch (e) {
        print('Error showing system notification: $e');
      }
    }
  }

  void _showNotificationsDialog() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('has_new_notifications', false);
      setState(() {
        _hasNewNotifications = false;
      });
    });

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
                if (_notifications.isNotEmpty)
                  TextButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setStringList('user_notifications', []);
                      dialogSetState(() {
                        _notifications.clear();
                      });
                      setState(() {});
                    },
                    child: const Text('Clear All'),
                  ),
              ],
            ),
            content: _notifications.isEmpty
                ? const SizedBox(
                    height: 120,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('No new notifications', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  )
                : SizedBox(
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final note = _notifications[index];
                        final refMatch = RegExp(r'TKZ-\d{4}-\d+').firstMatch(note);
                        final ref = refMatch?.group(0);

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200, width: 1),
                          ),
                          elevation: 0,
                          color: Colors.white,
                          child: ListTile(
                            leading: Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                color: AppTheme.badgeBg,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.info_outline, color: AppTheme.primary, size: 20),
                            ),
                            title: Text(
                              note,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              'Tap to track status',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                            onTap: ref != null
                                ? () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => BookingStatusScreen(bookingId: ref),
                                      ),
                                    );
                                  }
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  List<ServiceItem> get _filteredServices {
    if (_selectedCategory == 'All') {
      return _allServices;
    }
    return _allServices.where((s) => s.deviceType == _selectedCategory).toList();
  }



  Widget _buildCurrentPage() {
    switch (_currentTabIndex) {
      case 1:
        return _buildTrackPage();
      case 2:
        return _buildNotificationsPage();
      case 3:
        return _buildCartPage();
      case 0:
      default:
        return _buildCatalogPage();
    }
  }

  Widget _buildCatalogPage() {
    return Column(
      children: [
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
                child: GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primary.withOpacity(0.08) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppTheme.primary.withOpacity(0.3) : Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getCategoryIcon(cat),
                          size: 16,
                          color: isSelected ? AppTheme.primary : Colors.black54,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          cat,
                          style: TextStyle(
                            color: isSelected ? AppTheme.primary : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
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

        const Divider(height: 1),

        // Catalog Grid
        Expanded(
          child: _isLoadingServices
              ? const Center(child: CircularProgressIndicator())
              : _filteredServices.isEmpty
                  ? const Center(child: Text('No services or spare parts available.'))
                  : RefreshIndicator(
                      onRefresh: _loadCatalog,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final categoriesToRender = _selectedCategory == 'All'
                                ? _categories.where((c) => c != 'All').toList()
                                : [_selectedCategory];

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: categoriesToRender.map((cat) {
                                final catServices = _allServices.where((s) => s.deviceType == cat).toList();
                                if (catServices.isEmpty) return const SizedBox.shrink();

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _categoryHeader(cat),
                                    const SizedBox(height: 8),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: Row(
                                          children: catServices.map((service) {
                                            final isAccessory = service.deviceType == 'Accessories & Gadgets';
                                            const double hCardWidth = 160.0;
                                            return Container(
                                              width: hCardWidth,
                                              margin: const EdgeInsets.only(right: 12),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(16),
                                                border: Border.all(color: Colors.grey.shade100, width: 1),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.04),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ],
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(16),
                                                child: Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    onTap: () => isAccessory ? _buyNowDirect(service) : _openBookingModal(service),
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(12),
                                                      child: Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          // Circular Icon Badge
                                                          Container(
                                                            width: 52,
                                                            height: 52,
                                                            decoration: BoxDecoration(
                                                              color: AppTheme.badgeBg,
                                                              shape: BoxShape.circle,
                                                              border: Border.all(color: AppTheme.primary.withOpacity(0.08), width: 1),
                                                            ),
                                                            child: Center(
                                                              child: Icon(
                                                                _getServiceIcon(service.title, service.deviceType),
                                                                size: 24,
                                                                color: AppTheme.primary,
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(height: 10),
                                                          // Service Title
                                                          SizedBox(
                                                            height: 36,
                                                            child: Text(
                                                              service.title,
                                                              textAlign: TextAlign.center,
                                                              maxLines: 2,
                                                              overflow: TextOverflow.ellipsis,
                                                              style: const TextStyle(
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 12,
                                                                color: Colors.black87,
                                                                height: 1.2,
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(height: 10),
                                                          // Price
                                                          const Text(
                                                            'Starts at',
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              color: Colors.black54,
                                                            ),
                                                          ),
                                                          Text(
                                                            '₹${service.price.toStringAsFixed(0)}',
                                                            style: const TextStyle(
                                                              fontSize: 15,
                                                              fontWeight: FontWeight.w900,
                                                              color: AppTheme.accent,
                                                            ),
                                                          ),
                                                          const SizedBox(height: 12),
                                                          // Action Button(s)
                                                          if (isAccessory) ...[
                                                            // Add to Cart Button (Top)
                                                            OutlinedButton(
                                                              style: OutlinedButton.styleFrom(
                                                                foregroundColor: AppTheme.primary,
                                                                side: const BorderSide(color: AppTheme.primary, width: 1),
                                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                                minimumSize: const Size(double.infinity, 30),
                                                                padding: EdgeInsets.zero,
                                                              ),
                                                              onPressed: () => _addToCart(service),
                                                              child: const Text(
                                                                'Add to Cart',
                                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                                              ),
                                                            ),
                                                            const SizedBox(height: 6),
                                                            // Buy Now Button (Bottom)
                                                            ElevatedButton(
                                                              style: ElevatedButton.styleFrom(
                                                                backgroundColor: AppTheme.accent,
                                                                foregroundColor: Colors.white,
                                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                                minimumSize: const Size(double.infinity, 30),
                                                                padding: EdgeInsets.zero,
                                                                elevation: 0,
                                                              ),
                                                              onPressed: () => _buyNowDirect(service),
                                                              child: const Text(
                                                                'Buy Now',
                                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                                              ),
                                                            ),
                                                          ] else ...[
                                                            // Book Service Button
                                                            ElevatedButton(
                                                              style: ElevatedButton.styleFrom(
                                                                backgroundColor: AppTheme.accent,
                                                                foregroundColor: Colors.white,
                                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                                minimumSize: const Size(double.infinity, 34),
                                                                padding: EdgeInsets.zero,
                                                                elevation: 0,
                                                              ),
                                                              onPressed: () => _openBookingModal(service),
                                                              child: const Text(
                                                                'Book Service',
                                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                                              ),
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildTrackPage() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.local_shipping_outlined, size: 72, color: AppTheme.primary),
            const SizedBox(height: 16),
            const Text(
              'Track Order Status',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your reference code to check the status of your device repair or order.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _trackController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Reference Code',
                hintText: 'e.g. TKZ-2026-XXXXX',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
                suffixIcon: _trackController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _trackController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _trackController.text.trim().isEmpty
                  ? null
                  : () {
                      final ref = _trackController.text.trim();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookingStatusScreen(bookingId: ref),
                        ),
                      );
                    },
              child: const Text(
                'Track Now',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsPage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_hasNewNotifications) {
        SharedPreferences.getInstance().then((prefs) {
          prefs.setBool('has_new_notifications', false);
          if (mounted && _hasNewNotifications) {
            setState(() {
              _hasNewNotifications = false;
            });
          }
        });
      }
    });

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Notifications',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              if (_notifications.isNotEmpty)
                TextButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setStringList('user_notifications', []);
                    setState(() {
                      _notifications.clear();
                    });
                  },
                  child: const Text('Clear All'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'No new notifications',
                          style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final note = _notifications[index];
                      final refMatch = RegExp(r'TKZ-\d{4}-\d+').firstMatch(note);
                      final ref = refMatch?.group(0);

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200, width: 1),
                        ),
                        elevation: 0,
                        color: Colors.white,
                        child: ListTile(
                          leading: Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              color: AppTheme.badgeBg,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.info_outline, color: AppTheme.primary, size: 20),
                          ),
                          title: Text(
                            note,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          subtitle: const Text(
                            'Tap to track status',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          onTap: ref != null
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BookingStatusScreen(bookingId: ref),
                                    ),
                                  );
                                }
                              : null,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartPage() {
    final double total = _cart.fold(0, (sum, item) => sum + item.price);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: _cart.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('Your cart is empty', style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Form(
                key: _cartFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Shopping Cart',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    
                    // Cart Items List
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _cart.length,
                      itemBuilder: (context, index) {
                        final item = _cart[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          elevation: 0,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: AppTheme.badgeBg, shape: BoxShape.circle),
                              child: Icon(_getServiceIcon(item.title, item.deviceType), size: 18, color: AppTheme.primary),
                            ),
                            title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: Text(item.deviceType, style: const TextStyle(fontSize: 11)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('₹${item.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accent)),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _cart.removeAt(index);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 8),
                    
                    // Checkout Details Form
                    const Text('Delivery & Checkout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    
                    TextFormField(
                      controller: _cartNameController,
                      decoration: const InputDecoration(labelText: 'Full Name *', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Enter full name' : null,
                    ),
                    const SizedBox(height: 12),
                    
                    TextFormField(
                      controller: _cartPhoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: '10-Digit Mobile Number *', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.trim().length != 10 ? 'Enter valid phone' : null,
                    ),
                    const SizedBox(height: 12),
                    
                    TextFormField(
                      controller: _cartAddressController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Delivery Address *', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Enter address' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Total & Order Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('₹${total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.accent, fontSize: 18)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isCartCheckingOut
                          ? null
                          : () async {
                              if (!_cartFormKey.currentState!.validate()) return;
                              
                              setState(() => _isCartCheckingOut = true);
                              
                              final payload = {
                                'name': _cartNameController.text.trim(),
                                'phone': _cartPhoneController.text.trim(),
                                'pincode': '600001',
                                'address': _cartAddressController.text.trim(),
                                'device_type': 'Accessories & Gadgets',
                                'issue_type': _cart.map((item) => item.title).join(', '),
                                'preferred_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                                'time_slot': 'Anytime',
                                'estimated_price': total
                              };
                              
                              final result = await ApiService.createBooking(payload);
                              
                              setState(() => _isCartCheckingOut = false);
                              
                              if (result['success'] == true || result['data'] != null) {
                                final data = result['data'] ?? result;
                                final refCode = data['booking_ref'] ?? data['booking_id'] ?? 'TKZ-SUCCESS';
                                
                                final prefs = await SharedPreferences.getInstance();
                                final list = prefs.getStringList('my_bookings') ?? [];
                                if (!list.contains(refCode)) {
                                  list.add(refCode);
                                  await prefs.setStringList('my_bookings', list);
                                  
                                  final cachedStatuses = Map<String, String>.from(
                                    json.decode(prefs.getString('booking_statuses') ?? '{}'),
                                  );
                                  cachedStatuses[refCode] = 'Pending';
                                  await prefs.setString('booking_statuses', json.encode(cachedStatuses));
                                }
                                
                                setState(() {
                                  _cart.clear();
                                  _currentTabIndex = 0; // Go to home tab
                                });
                                _showOrderPlacedDialog(refCode);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: ${result['error'] ?? result['message'] ?? 'Failed to place order'}')),
                                );
                              }
                            },
                      child: _isCartCheckingOut
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Place Order (COD)', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
    );
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
            Text('Tekzivo Electronics Care', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: Colors.black54,
        onTap: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home, color: AppTheme.primary),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping_outlined),
            label: 'Track',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: _hasNewNotifications,
              child: const Icon(Icons.notifications_outlined),
            ),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: _cart.isNotEmpty,
              label: Text(_cart.length.toString()),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            label: 'Cart',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: _buildCurrentPage(),
        ),
      ),
    );
  }

  void _buyNowDirect(ServiceItem item) {
    if (!_cart.contains(item)) {
      setState(() {
        _cart.add(item);
      });
    }
    setState(() {
      _currentTabIndex = 3;
    });
  }

  Widget _categoryHeader(String category) {
    String title = '';
    switch (category) {
      case 'Smartphone':
        title = 'Smartphone Services & Parts';
        break;
      case 'Laptop':
        title = 'Laptop Services & Parts';
        break;
      case 'LED TV':
        title = 'LED TV Services & Parts';
        break;
      case 'Accessories & Gadgets':
        title = 'Accessories & Gadgets Catalog';
        break;
      default:
        title = '$category Services & Parts';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 50,
            height: 3,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ],
      ),
    );
  }

  void _addToCart(ServiceItem item) {
    setState(() {
      _cart.add(item);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.title} added to cart!'),
        action: SnackBarAction(
          label: 'VIEW',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              _currentTabIndex = 3;
            });
          },
        ),
      ),
    );
  }

  void _showCartDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) {
          final double total = _cart.fold(0, (sum, item) => sum + item.price);
          
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: const [
                Icon(Icons.shopping_cart_outlined, color: AppTheme.primary),
                SizedBox(width: 8),
                Text('Shopping Cart', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: _cart.isEmpty
                ? const SizedBox(
                    height: 100,
                    child: Center(child: Text('Your cart is empty', style: TextStyle(color: Colors.grey))),
                  )
                : SizedBox(
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _cart.length,
                      itemBuilder: (context, index) {
                        final item = _cart[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: AppTheme.badgeBg, shape: BoxShape.circle),
                            child: Icon(_getServiceIcon(item.title, item.deviceType), size: 18, color: AppTheme.primary),
                          ),
                          title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text(item.deviceType, style: const TextStyle(fontSize: 11)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('₹${item.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accent)),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _cart.removeAt(index);
                                  });
                                  dialogSetState(() {});
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            actions: [
              if (_cart.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('₹${total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.accent, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    minimumSize: const Size(double.infinity, 40),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _showCheckoutDialog(total);
                  },
                  child: const Text('Proceed to Checkout'),
                ),
                const SizedBox(height: 4),
              ],
              TextButton(
                style: TextButton.styleFrom(minimumSize: const Size(double.infinity, 36)),
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    ).then((_) => setState(() {}));
  }

  void _showCheckoutDialog(double total) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isCheckingOut = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Delivery & Checkout', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Full Name *', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Enter full name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: '10-Digit Mobile Number *', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.trim().length != 10 ? 'Enter valid phone' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: addressController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Delivery Address *', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Enter address' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('To Pay:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('₹${total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.accent, fontSize: 16)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isCheckingOut ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isCheckingOut ? null : () async {
                  if (!formKey.currentState!.validate()) return;
                  
                  dialogSetState(() => isCheckingOut = true);
                  
                  final payload = {
                    'name': nameController.text.trim(),
                    'phone': phoneController.text.trim(),
                    'pincode': '600001',
                    'address': addressController.text.trim(),
                    'device_type': 'Accessories & Gadgets',
                    'issue_type': _cart.map((item) => item.title).join(', '),
                    'preferred_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                    'time_slot': 'Anytime',
                    'estimated_price': total
                  };
                  
                  final result = await ApiService.createBooking(payload);
                  
                  dialogSetState(() => isCheckingOut = false);
                  
                  if (result['success'] == true || result['data'] != null) {
                    final data = result['data'] ?? result;
                    final refCode = data['booking_ref'] ?? data['booking_id'] ?? 'TKZ-SUCCESS';
                    
                    final prefs = await SharedPreferences.getInstance();
                    final list = prefs.getStringList('my_bookings') ?? [];
                    if (!list.contains(refCode)) {
                      list.add(refCode);
                      await prefs.setStringList('my_bookings', list);
                      
                      final cachedStatuses = Map<String, String>.from(
                        json.decode(prefs.getString('booking_statuses') ?? '{}'),
                      );
                      cachedStatuses[refCode] = 'Pending';
                      await prefs.setString('booking_statuses', json.encode(cachedStatuses));
                    }
                    
                    if (context.mounted) {
                      Navigator.pop(context);
                      setState(() {
                        _cart.clear();
                      });
                      _showOrderPlacedDialog(refCode);
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${result['error'] ?? result['message'] ?? 'Failed to place order'}')),
                      );
                    }
                  }
                },
                child: isCheckingOut 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Place Order (COD)'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showOrderPlacedDialog(String refCode) {
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
            const Text('Order Placed Successfully!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Reference Code: $refCode', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 14)),
            const SizedBox(height: 8),
            const Text('Thank you! Your gadget will be delivered within 2-3 business days.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
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

  File? _imageFile;
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoadingReviews = true;

  @override
  void initState() {
    super.initState();
    _brands = widget.initialBrands;
    _fetchBrands();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    setState(() => _isLoadingReviews = true);
    final r = await ApiService.getReviews(widget.service.title);
    setState(() {
      _reviews = r;
      _isLoadingReviews = false;
    });
  }

  Future<void> _fetchBrands() async {
    setState(() => _isLoadingBrands = true);
    final b = await ApiService.getBrands();
    setState(() {
      _brands = List<Brand>.from(b);
      if (_brands.isNotEmpty) {
        _brands.add(Brand(id: 'custom', name: 'Other (Type custom brand...)'));
      }
      _isLoadingBrands = false;
    });
  }

  Future<void> _onBrandSelected(Brand? brand) async {
    setState(() {
      _selectedBrand = brand;
      _selectedModel = null;
      _models = [];
      _customBrandController.clear();
      _customModelController.clear();
    });

    if (brand != null && brand.id != 'custom') {
      setState(() => _isLoadingModels = true);
      final m = await ApiService.getModels(brand.id);
      setState(() {
        _models = List<DeviceModel>.from(m);
        if (_models.isNotEmpty) {
          _models.add(DeviceModel(id: 'custom', brandId: brand.id, name: 'Other (Type custom model...)'));
        }
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

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      showModalBottomSheet(
        context: context,
        builder: (context) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                  if (picked != null) {
                    setState(() => _imageFile = File(picked.path));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.pop(context);
                  final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                  if (picked != null) {
                    setState(() => _imageFile = File(picked.path));
                  }
                },
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isPincodeValid == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doorstep repair is not available in this pincode')),
      );
      return;
    }

    final brandName = _selectedBrand?.id == 'custom'
        ? _customBrandController.text.trim()
        : _selectedBrand?.name ?? _customBrandController.text.trim();
    final modelName = _selectedModel?.id == 'custom'
        ? _customModelController.text.trim()
        : _selectedModel?.name ?? _customModelController.text.trim();

    if (brandName.isEmpty || modelName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or enter Brand and Model')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    String? uploadedImagePath;
    if (_imageFile != null) {
      uploadedImagePath = await ApiService.uploadImage(_imageFile!);
      if (uploadedImagePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Warning: Photo upload failed. Proceeding without photo.')),
        );
      }
    }

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
      'image_path': uploadedImagePath,
      'preferred_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
      'time_slot': 'Anytime',
      'estimated_price': widget.service.price
    };

    final result = await ApiService.createBooking(payload);

    setState(() => _isSubmitting = false);

    if (result['success'] == true || result['data'] != null) {
      final data = result['data'] ?? result;
      final refCode = data['booking_ref'] ?? data['booking_id'] ?? 'TKZ-SUCCESS';

      SharedPreferences.getInstance().then((prefs) {
        final list = prefs.getStringList('my_bookings') ?? [];
        if (!list.contains(refCode)) {
          list.add(refCode);
          prefs.setStringList('my_bookings', list);
          
          final cachedStatuses = Map<String, String>.from(
            json.decode(prefs.getString('booking_statuses') ?? '{}'),
          );
          cachedStatuses[refCode] = 'Pending';
          prefs.setString('booking_statuses', json.encode(cachedStatuses));
        }
      });

      Navigator.pop(context);
      _showSuccessDialog(refCode);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${result['error'] ?? result['message'] ?? 'Failed to book'}')),
      );
    }
  }

  void _showSuccessDialog(String refCode) {
    int selectedRating = 5;
    final nameController = TextEditingController(text: _nameController.text.trim());
    final reviewController = TextEditingController();
    bool isReviewSubmitting = false;
    bool isReviewSubmitted = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: SingleChildScrollView(
              child: Column(
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
                  const Divider(),
                  const SizedBox(height: 12),
                  
                  // Feedback / Review Box
                  if (!isReviewSubmitted) ...[
                    const Text(
                      'Share Your Experience!',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Help other customers by rating this service.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Your Name',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starValue = index + 1;
                        return IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            Icons.star,
                            color: starValue <= selectedRating ? Colors.amber : Colors.grey.shade300,
                            size: 32,
                          ),
                          onPressed: () {
                            dialogSetState(() {
                              selectedRating = starValue;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: reviewController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Review Comments',
                        hintText: 'Tell us about the service...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        minimumSize: const Size(double.infinity, 38),
                      ),
                      onPressed: isReviewSubmitting
                          ? null
                          : () async {
                              final name = nameController.text.trim();
                              final comment = reviewController.text.trim();
                              if (name.isEmpty || comment.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter your name and comment.')),
                                );
                                return;
                              }
                              
                              dialogSetState(() => isReviewSubmitting = true);
                              final payload = {
                                'item_name': widget.service.title,
                                'device_type': widget.service.deviceType,
                                'name': name,
                                'rating': selectedRating,
                                'text': comment
                              };
                              final res = await ApiService.submitReview(payload);
                              dialogSetState(() {
                                isReviewSubmitting = false;
                                if (res['success'] == true || res['data'] != null) {
                                  isReviewSubmitted = true;
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to submit review: ${res['error'] ?? 'Unknown error'}')),
                                  );
                                }
                              });
                            },
                      child: isReviewSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Submit Review', style: TextStyle(fontSize: 13)),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Thank you! Your review has been published.',
                              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade800,
                      minimumSize: const Size(double.infinity, 40),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String labelText,
    IconData? prefixIcon,
    Widget? suffixIcon,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppTheme.primary.withOpacity(0.7), size: 20) : null,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      labelStyle: const TextStyle(fontSize: 13, color: Colors.black54),
      floatingLabelStyle: const TextStyle(fontSize: 14, color: AppTheme.primary, fontWeight: FontWeight.w600),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.black54,
          letterSpacing: 0.8,
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
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2),
        ],
      ),
      padding: EdgeInsets.only(
        top: 10,
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
              // Bottom Sheet Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

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
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      minimumSize: const Size(32, 32),
                    ),
                    icon: const Icon(Icons.close, size: 18, color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Selected Service Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary.withOpacity(0.06), AppTheme.primary.withOpacity(0.12)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppTheme.badgeBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getServiceIcon(widget.service.title, widget.service.deviceType),
                        color: AppTheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.service.deviceType,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary.withOpacity(0.8),
                            ),
                          ),
                          Text(
                            widget.service.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Starts at',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '₹${widget.service.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.accent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Customer Reviews Section
              _isLoadingReviews
                  ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(2, (index) => Container(
                          width: 260,
                          height: 80,
                          margin: const EdgeInsets.only(right: 10),
                          child: const SkeletonLoader(width: 260, height: 80, borderRadius: 8),
                        )),
                      ),
                    )
                  : _reviews.isEmpty
                      ? const SizedBox.shrink()
                      : Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Verified Reviews',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${(_reviews.fold<double>(0, (sum, r) => sum + (r['rating'] as num).toDouble()) / _reviews.length).toStringAsFixed(1)}/5.0 (${_reviews.length})',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 80,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _reviews.length,
                                  itemBuilder: (context, index) {
                                    final rev = _reviews[index];
                                    final rating = rev['rating'] as int;
                                    return Container(
                                      width: 260,
                                      margin: const EdgeInsets.only(right: 10),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                rev['name'] ?? 'Customer',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                              ),
                                              Row(
                                                children: List.generate(
                                                  5,
                                                  (i) => Icon(
                                                    Icons.star,
                                                    color: i < rating ? Colors.amber : Colors.grey.shade200,
                                                    size: 11,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Expanded(
                                            child: Text(
                                              rev['text'] ?? '',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.2),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

              _sectionHeader('Device Details'),

              // Brand & Model Selection with Loader
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _isLoadingBrands
                            ? const SkeletonLoader(width: double.infinity, height: 50, borderRadius: 12)
                            : _brands.isEmpty
                                ? TextFormField(
                                    controller: _customBrandController,
                                    decoration: _inputDecoration(labelText: 'Device Brand *', prefixIcon: Icons.branding_watermark_outlined),
                                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter brand' : null,
                                  )
                                : DropdownButtonFormField<Brand>(
                                    isExpanded: true,
                                    value: _selectedBrand,
                                    decoration: _inputDecoration(labelText: 'Device Brand *', prefixIcon: Icons.branding_watermark_outlined),
                                    hint: const Text('Select Brand...', overflow: TextOverflow.ellipsis),
                                    items: _brands.map((b) => DropdownMenuItem(value: b, child: Text(b.name, overflow: TextOverflow.ellipsis))).toList(),
                                    onChanged: _onBrandSelected,
                                    validator: (v) => _selectedBrand == null ? 'Select brand' : null,
                                  ),
                        if (_selectedBrand?.id == 'custom') ...[
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _customBrandController,
                            decoration: _inputDecoration(labelText: 'Type brand name...', prefixIcon: Icons.edit_note_outlined),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Enter brand name' : null,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _isLoadingModels
                            ? const SkeletonLoader(width: double.infinity, height: 50, borderRadius: 12)
                            : (_models.isEmpty || _selectedBrand?.id == 'custom')
                                ? TextFormField(
                                    controller: _customModelController,
                                    decoration: _inputDecoration(labelText: 'Device Model *', prefixIcon: Icons.phone_android_outlined, hintText: 'e.g. iPhone 14'),
                                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter model' : null,
                                  )
                                : DropdownButtonFormField<DeviceModel>(
                                    isExpanded: true,
                                    value: _selectedModel,
                                    decoration: _inputDecoration(labelText: 'Device Model *', prefixIcon: Icons.phone_android_outlined),
                                    hint: const Text('Select Model...', overflow: TextOverflow.ellipsis),
                                    items: _models.map((m) => DropdownMenuItem(value: m, child: Text(m.name, overflow: TextOverflow.ellipsis))).toList(),
                                    onChanged: (val) => setState(() => _selectedModel = val),
                                    validator: (v) => _selectedModel == null ? 'Select model' : null,
                                  ),
                        if (_selectedModel?.id == 'custom' && _selectedBrand?.id != 'custom') ...[
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _customModelController,
                            decoration: _inputDecoration(labelText: 'Type model name...', prefixIcon: Icons.edit_note_outlined),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Enter model name' : null,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              _sectionHeader('Contact Details'),

              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration(labelText: 'Full Name *', prefixIcon: Icons.person_outline),
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter full name' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _inputDecoration(labelText: '10-Digit Mobile Number *', prefixIcon: Icons.phone_outlined),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Enter mobile number';
                  }
                  final trimmed = v.trim();
                  if (trimmed.length != 10) {
                    return 'Mobile number must be exactly 10 digits';
                  }
                  if (!RegExp(r'^[6-9]\d{9}$').hasMatch(trimmed)) {
                    return 'Must start with 6, 7, 8, or 9';
                  }
                  return null;
                },
              ),

              _sectionHeader('Schedule & Location'),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _pincodeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: _inputDecoration(
                        labelText: 'Pincode *',
                        prefixIcon: Icons.location_on_outlined,
                        suffixIcon: _isCheckingPincode 
                            ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))) 
                            : null,
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_outlined, color: AppTheme.primary, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                DateFormat('dd MMM yyyy').format(_selectedDate), 
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              if (_pincodeMessage.isNotEmpty) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      Icon(
                        _isPincodeValid == true ? Icons.check_circle_outline : Icons.error_outline,
                        color: _isPincodeValid == true ? AppTheme.success : Colors.red,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _pincodeMessage.replaceFirst('✓ ', '').replaceFirst('✕ ', ''),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _isPincodeValid == true ? AppTheme.success : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: _inputDecoration(labelText: 'Full Address *', prefixIcon: Icons.home_outlined),
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter address' : null,
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: _inputDecoration(labelText: 'Describe the Issue *', prefixIcon: Icons.description_outlined),
                validator: (v) => v == null || v.trim().isEmpty ? 'Describe the issue' : null,
              ),

              _sectionHeader('Additional Options'),

              // Device Photo Upload UI
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _imageFile != null ? AppTheme.primary.withOpacity(0.3) : Colors.grey.shade300,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (_imageFile == null) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.add_photo_alternate_outlined, color: Colors.black54),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Upload Device Photo (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              SizedBox(height: 2),
                              Text('Helps technician understand the damage', style: TextStyle(fontSize: 11, color: Colors.black45)),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black38),
                      ] else ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(_imageFile!, width: 44, height: 44, fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _imageFile!.path.split('/').last,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              const Text('Image attached successfully', style: TextStyle(fontSize: 11, color: AppTheme.success, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => setState(() => _imageFile = null),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                  shadowColor: AppTheme.accent.withOpacity(0.4),
                ),
                onPressed: _isSubmitting ? null : _submitBooking,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'CONFIRM BOOKING — ₹${widget.service.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 0.8).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

