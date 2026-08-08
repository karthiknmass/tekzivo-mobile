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
import 'package:provider/provider.dart';
import '../../core/constants/api_constants.dart';
import '../../models/brand.dart';
import '../../models/service_item.dart';
import '../technician/tech_dashboard_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'booking_status_screen.dart';
import 'product_detail_screen.dart';

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

String _resolveImageUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  
  // If it's a comma-separated list of image paths, extract the first one
  String singlePath = path;
  if (path.contains(',')) {
    singlePath = path.split(',')[0].trim();
  }

  if (singlePath.startsWith('http://') || singlePath.startsWith('https://')) {
    return singlePath;
  }
  final cleanPath = singlePath.startsWith('/') ? singlePath.substring(1) : singlePath;
  final base = ApiConstants.baseUrl.replaceAll('/api', '');
  return '$base/$cleanPath';
}

class CardStyle {
  final Color cardBg;
  final Color iconBg;
  final Color iconColor;
  final Color textColor;

  const CardStyle({
    required this.cardBg,
    required this.iconBg,
    required this.iconColor,
    required this.textColor,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CardStyle _getCardStyle(String title, String deviceType) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('battery')) {
      return const CardStyle(
        cardBg: Color(0xFFFAF0ED), // Soft peach
        iconBg: Color(0xFFF2D3CC),
        iconColor: Color(0xFF8A3A2B),
        textColor: Color(0xFF8A3A2B),
      );
    } else if (lowerTitle.contains('screen') || lowerTitle.contains('display') || lowerTitle.contains('glass') || lowerTitle.contains('panel')) {
      return const CardStyle(
        cardBg: Color(0xFFEAF4FC), // Soft blue
        iconBg: Color(0xFFD4E6F7),
        iconColor: Color(0xFF1A5F9E),
        textColor: Color(0xFF1A5F9E),
      );
    } else if (lowerTitle.contains('keyboard') || lowerTitle.contains('button') || lowerTitle.contains('key') || lowerTitle.contains('repair')) {
      if (lowerTitle.contains('keyboard') || lowerTitle.contains('key')) {
        return const CardStyle(
          cardBg: Color(0xFFEBF6F0), // Soft green
          iconBg: Color(0xFFD4ECE0),
          iconColor: Color(0xFF1E6F4A),
          textColor: Color(0xFF1E6F4A),
        );
      }
    }
    
    if (lowerTitle.contains('motherboard') || lowerTitle.contains('ic') || lowerTitle.contains('chip') || lowerTitle.contains('board')) {
      return const CardStyle(
        cardBg: Color(0xFFFAF5E6), // Soft gold
        iconBg: Color(0xFFF3EAD0),
        iconColor: Color(0xFF8E6B1E),
        textColor: Color(0xFF8E6B1E),
      );
    }

    // Default fallbacks based on category to keep layout color-coordinated
    if (deviceType == 'Smartphone') {
      return const CardStyle(
        cardBg: Color(0xFFEAF4FC),
        iconBg: Color(0xFFD4E6F7),
        iconColor: Color(0xFF1A5F9E),
        textColor: Color(0xFF1A5F9E),
      );
    } else if (deviceType == 'Laptop') {
      return const CardStyle(
        cardBg: Color(0xFFEBF6F0),
        iconBg: Color(0xFFD4ECE0),
        iconColor: Color(0xFF1E6F4A),
        textColor: Color(0xFF1E6F4A),
      );
    } else {
      return const CardStyle(
        cardBg: Color(0xFFFAF5E6),
        iconBg: Color(0xFFF3EAD0),
        iconColor: Color(0xFF8E6B1E),
        textColor: Color(0xFF8E6B1E),
      );
    }
  }

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
  List<String> _wishlistedIds = [];
  String _currentCatalogTab = 'Catalogues';
  String _searchQuery = '';
  String _sortBy = 'default';
  String _filterCategory = 'All';
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

  int _activePromoPage = 0;
  late PageController _promoPageController;

  @override
  void initState() {
    super.initState();
    _promoPageController = PageController(initialPage: 0);
    _loadCatalog();
    _loadNotifications();
    _startStatusPolling();
    _requestNotificationPermission();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> list = prefs.getStringList('wishlist_ids') ?? [];
    if (mounted) {
      setState(() {
        _wishlistedIds = list;
      });
    }
  }

  void _toggleWishlist(String serviceId) {
    setState(() {
      if (_wishlistedIds.contains(serviceId)) {
        _wishlistedIds.remove(serviceId);
      } else {
        _wishlistedIds.add(serviceId);
      }
    });
    _saveWishlistToPrefs();
  }

  Future<void> _saveWishlistToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _wishlistedIds.map((id) => id.toString()).toList();
    await prefs.setStringList('wishlist_ids', list);
  }

  @override
  void dispose() {
    _statusPollingTimer?.cancel();
    _promoPageController.dispose();
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
        return _buildWishlistPage();
      case 2:
        return _buildTrackPage();
      case 3:
        return _buildCartPage();
      case 0:
      default:
        return _buildCatalogPage();
    }
  }

  Widget _buildWishlistPage() {
    final List<ServiceItem> wishlistedItems = _allServices.where((s) => _wishlistedIds.contains(s.id)).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: wishlistedItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('Your wishlist is empty', style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Expanded(
                  child: ListView.builder(
                    itemCount: wishlistedItems.length,
                    itemBuilder: (context, index) {
                      final item = wishlistedItems[index];
                      final bool isDark = Theme.of(context).brightness == Brightness.dark;
                      final Color cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
                      final Color borderColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
                      final Color badgeColor = isDark ? const Color(0xFF151515) : AppTheme.badgeBg;
                      final Color accentIconColor = isDark ? const Color(0xFFE0533C) : AppTheme.primary;
                      final Color titleTextColor = isDark ? Colors.white : Colors.black87;

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: borderColor, width: 1.5),
                          boxShadow: isDark
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: ListTile(
                          onTap: () {
                            Navigator.push<String>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailScreen(
                                  product: item,
                                  isWishlisted: true,
                                  onWishlistToggle: () => _toggleWishlist(item.id),
                                  onAddToCart: (qty) => _addToCartWithQuantity(item, qty),
                                ),
                              ),
                            ).then((result) {
                              if (result == 'buy_now') {
                                setState(() => _currentTabIndex = 3);
                              }
                            });
                          },
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: item.imagePath != null && item.imagePath!.isNotEmpty
                                  ? Colors.transparent
                                  : badgeColor,
                              shape: BoxShape.circle,
                            ),
                            child: item.imagePath != null && item.imagePath!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Image.network(
                                      _resolveImageUrl(item.imagePath),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Icon(
                                        _getServiceIcon(item.title, item.deviceType),
                                        size: 20,
                                        color: accentIconColor,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    _getServiceIcon(item.title, item.deviceType),
                                    size: 20,
                                    color: accentIconColor,
                                  ),
                          ),
                          title: Text(item.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: titleTextColor)),
                          subtitle: Text('₹${item.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accent)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                  icon: Icon(Icons.shopping_cart_outlined, color: accentIconColor),
                                  onPressed: () {
                                    _addToCart(item);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () {
                                    _toggleWishlist(item.id);
                                  },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }  Widget _buildCatalogTabs() {
    final cataloguesCount = _allServices.where((s) => s.deviceType != 'Accessories & Gadgets').length;
    final productsCount = _allServices.where((s) => s.deviceType == 'Accessories & Gadgets').length;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color activeColor = const Color(0xFFE0533C);
    final Color inactiveBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color inactiveBorderColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final Color inactiveTextColor = isDark ? Colors.white70 : Colors.black54;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          // Catalogues (Services) Tab
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _currentCatalogTab = 'Catalogues';
                  if (_selectedCategory == 'Accessories & Gadgets') {
                    _selectedCategory = 'All';
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 44,
                decoration: BoxDecoration(
                  color: _currentCatalogTab == 'Catalogues'
                      ? activeColor
                      : inactiveBgColor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: _currentCatalogTab == 'Catalogues'
                        ? Colors.transparent
                        : inactiveBorderColor,
                    width: 1.5,
                  ),
                  boxShadow: _currentCatalogTab == 'Catalogues'
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Catalogues',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: _currentCatalogTab == 'Catalogues'
                            ? Colors.white
                            : inactiveTextColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _currentCatalogTab == 'Catalogues'
                            ? Colors.white24
                            : const Color(0xFFE0533C).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$cataloguesCount',
                        style: TextStyle(
                          color: _currentCatalogTab == 'Catalogues'
                              ? Colors.white
                              : const Color(0xFFE0533C),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Products Tab
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _currentCatalogTab = 'Products';
                  _selectedCategory = 'Accessories & Gadgets';
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 44,
                decoration: BoxDecoration(
                  color: _currentCatalogTab == 'Products'
                      ? activeColor
                      : inactiveBgColor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: _currentCatalogTab == 'Products'
                        ? Colors.transparent
                        : inactiveBorderColor,
                    width: 1.5,
                  ),
                  boxShadow: _currentCatalogTab == 'Products'
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Products',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: _currentCatalogTab == 'Products'
                            ? Colors.white
                            : inactiveTextColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _currentCatalogTab == 'Products'
                            ? Colors.white24
                            : const Color(0xFFE0533C).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$productsCount',
                        style: TextStyle(
                          color: _currentCatalogTab == 'Products'
                              ? Colors.white
                              : const Color(0xFFE0533C),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color searchBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color searchBorder = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color placeholderColor = isDark ? Colors.white38 : Colors.black38;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          // Search Input Capsule
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: searchBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: searchBorder, width: 1.5),
                boxShadow: isDark
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: TextField(
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim();
                  });
                },
                style: TextStyle(color: textColor, fontSize: 13),
                decoration: InputDecoration(
                  hintText: "What's on your list?",
                  hintStyle: TextStyle(color: placeholderColor, fontSize: 13),
                  prefixIcon: Icon(Icons.search, color: placeholderColor, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Circular Filter Button
          GestureDetector(
            onTap: _showFilterBottomSheet,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFE0533C),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.tune_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF151515) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter & Sort',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _sortBy = 'default';
                            _filterCategory = 'All';
                          });
                        },
                        child: const Text('Reset', style: TextStyle(color: Color(0xFFE0533C))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Sort By Section
                  Text(
                    'Sort By',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _filterChip(
                        label: 'Default',
                        isSelected: _sortBy == 'default',
                        onTap: () => setModalState(() => _sortBy = 'default'),
                      ),
                      _filterChip(
                        label: 'Price: Low to High',
                        isSelected: _sortBy == 'low_to_high',
                        onTap: () => setModalState(() => _sortBy = 'low_to_high'),
                      ),
                      _filterChip(
                        label: 'Price: High to Low',
                        isSelected: _sortBy == 'high_to_low',
                        onTap: () => setModalState(() => _sortBy = 'high_to_low'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Category Section (only for Catalogues)
                  if (_currentCatalogTab == 'Catalogues') ...[
                    Text(
                      'Service Category',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _categories
                          .where((c) => c != 'Accessories & Gadgets')
                          .map((cat) {
                            return _filterChip(
                              label: cat,
                              isSelected: _filterCategory == cat,
                              onTap: () => setModalState(() => _filterCategory = cat),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Apply Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.black12, width: 1),
                      ),
                      shadowColor: Colors.black.withOpacity(0.1),
                      elevation: 2,
                    ),
                    onPressed: () {
                      setState(() {}); // Apply changes to home screen
                      Navigator.pop(context);
                    },
                    child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _filterChip({required String label, required bool isSelected, required VoidCallback onTap}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color selectedBg = const Color(0xFFE0533C).withOpacity(0.12);
    final Color unselectedBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF1F5F9);
    final Color selectedTextColor = const Color(0xFFE0533C);
    final Color unselectedTextColor = isDark ? Colors.white70 : Colors.black87;
    final Color selectedBorderColor = const Color(0xFFE0533C);
    final Color unselectedBorderColor = isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200;

    return GestureDetector(
      onTap: onTap,
      child: Chip(
        label: Text(label),
        backgroundColor: isSelected ? selectedBg : unselectedBg,
        labelStyle: TextStyle(
          color: isSelected ? selectedTextColor : unselectedTextColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected ? selectedBorderColor : unselectedBorderColor,
        ),
      ),
    );
  }

  Widget _buildPromoCarousel() {
    final promoBanners = [
      {
        'title': '⚡ 2hr Doorstep Screen Repair',
        'subtitle': 'Original screens & certified technicians.',
        'action': 'Book now',
        'gradient': const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        'icon': Icons.bolt_outlined,
      },
      {
        'title': '🛡️ 90-Day Tekzivo Warranty',
        'subtitle': 'Enjoy worry-free device services.',
        'action': 'Learn more',
        'gradient': const LinearGradient(
          colors: [Color(0xFF065F46), Color(0xFF022C22)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        'icon': Icons.shield_outlined,
      },
      {
        'title': '🎧 Premium Accessories 15% OFF',
        'subtitle': 'Upgrade your sound & charging experience.',
        'action': 'Shop now',
        'gradient': const LinearGradient(
          colors: [Color(0xFF5B21B6), Color(0xFF2E1065)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        'icon': Icons.headphones_outlined,
      },
    ];

    return Column(
      children: [
        SizedBox(
          height: 130,
          child: PageView.builder(
            controller: _promoPageController,
            onPageChanged: (index) {
              setState(() {
                _activePromoPage = index;
              });
            },
            itemCount: promoBanners.length,
            itemBuilder: (context, index) {
              final banner = promoBanners[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: banner['gradient'] as LinearGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppTheme.premiumShadow,
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -30,
                      child: CircleAvatar(
                        radius: 80,
                        backgroundColor: Colors.white.withOpacity(0.06),
                      ),
                    ),
                    Positioned(
                      left: -20,
                      bottom: -40,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white.withOpacity(0.04),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  banner['title'] as String,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  banner['subtitle'] as String,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE0533C),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    banner['action'] as String,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            banner['icon'] as IconData,
                            color: Colors.white.withOpacity(0.2),
                            size: 72,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            promoBanners.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _activePromoPage == index ? 14 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _activePromoPage == index ? const Color(0xFFE0533C) : const Color(0xFF444444),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonLoader() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLoader(width: double.infinity, height: 130, borderRadius: 20),
          const SizedBox(height: 24),
          const SkeletonLoader(width: 140, height: 16, borderRadius: 8),
          const SizedBox(height: 12),
          Row(
            children: List.generate(4, (index) => const Padding(
              padding: EdgeInsets.only(right: 10),
              child: SkeletonLoader(width: 80, height: 36, borderRadius: 18),
            )),
          ),
          const SizedBox(height: 24),
          const SkeletonLoader(width: 180, height: 18, borderRadius: 8),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: SkeletonLoader(width: double.infinity, height: double.infinity, borderRadius: 12),
                    ),
                    const SizedBox(height: 12),
                    const SkeletonLoader(width: 100, height: 12, borderRadius: 6),
                    const SizedBox(height: 8),
                    const SkeletonLoader(width: 60, height: 14, borderRadius: 6),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogPage() {
    return Column(
      children: [
        // Search & Filter Bar
        _buildSearchAndFilterBar(),

        // Tab Selector (Catalogues vs Products)
        _buildCatalogTabs(),

        const SizedBox(height: 8),

        // Catalog Body
        Expanded(
          child: _isLoadingServices
              ? _buildSkeletonLoader()
              : RefreshIndicator(
                  onRefresh: _loadCatalog,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPromoCarousel(),
                        const SizedBox(height: 16),
                        _currentCatalogTab == 'Products'
                            ? Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: _buildProductsSection(),
                              )
                            : Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: _buildCataloguesSection(),
                              ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildCataloguesSection() {
    final visibleCats = _categories.where((c) => c != 'Accessories & Gadgets' && c != 'All').toList();
    
    // Determine categories to render based on bottom sheet filter
    final categoriesToRender = _filterCategory == 'All'
        ? visibleCats
        : [_filterCategory];

    if (categoriesToRender.isEmpty) {
      return const Center(child: Text('No categories available.'));
    }

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color currentCardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final Color currentTextPrimary = isDark ? Colors.white : Colors.black87;
    final Color currentTextSecondary = isDark ? Colors.white54 : Colors.black54;
    final Color currentBorderColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE2E8F0);

    bool hasAnyMatches = false;
    final List<Widget> sections = [];

    for (final cat in categoriesToRender) {
      var catServices = _allServices.where((s) => s.deviceType == cat).toList();
      
      // Filter by Search Query
      if (_searchQuery.isNotEmpty) {
        catServices = catServices.where((s) {
          final query = _searchQuery.toLowerCase();
          return s.title.toLowerCase().contains(query) ||
              s.description.toLowerCase().contains(query);
        }).toList();
      }

      if (catServices.isEmpty) continue;
      hasAnyMatches = true;

      // Sort
      if (_sortBy == 'low_to_high') {
        catServices.sort((a, b) => a.price.compareTo(b.price));
      } else if (_sortBy == 'high_to_low') {
        catServices.sort((a, b) => b.price.compareTo(a.price));
      }

      sections.add(
        Column(
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
                    const double hCardWidth = 160.0;
                    return Container(
                      width: hCardWidth,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: currentCardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: currentBorderColor, width: 1),
                        boxShadow: isDark
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            // Left edge accent line
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              child: Container(
                                width: 4,
                                color: const Color(0xFFE0533C),
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _openBookingModal(service),
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 16, top: 16, right: 12, bottom: 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Standalone Left-Aligned Icon (No Circle Bg)
                                      service.imagePath != null && service.imagePath!.isNotEmpty
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(4),
                                              child: Image.network(
                                                _resolveImageUrl(service.imagePath),
                                                width: 24,
                                                height: 24,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => Icon(
                                                  _getServiceIcon(service.title, service.deviceType),
                                                  size: 24,
                                                  color: const Color(0xFFE0533C),
                                                ),
                                              ),
                                            )
                                          : Icon(
                                              _getServiceIcon(service.title, service.deviceType),
                                              size: 24,
                                              color: const Color(0xFFE0533C),
                                            ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        height: 36,
                                        child: Text(
                                          service.title,
                                          textAlign: TextAlign.left,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: currentTextPrimary,
                                            height: 1.2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Starts at',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: currentTextSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '₹${service.price.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          color: currentTextPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    }

    if (!hasAnyMatches) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Column(
            children: [
              Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'No matching services found.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections,
    );
  }

  Widget _buildProductsSection() {
    var products = _allServices.where((s) => s.deviceType == 'Accessories & Gadgets').toList();
    
    // Filter by Search Query
    if (_searchQuery.isNotEmpty) {
      products = products.where((p) {
        final query = _searchQuery.toLowerCase();
        return p.title.toLowerCase().contains(query) ||
            p.description.toLowerCase().contains(query);
      }).toList();
    }

    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0),
          child: Column(
            children: [
              Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'No matching products found.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    // Sort
    if (_sortBy == 'low_to_high') {
      products.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortBy == 'high_to_low') {
      products.sort((a, b) => b.price.compareTo(a.price));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _categoryHeader('Accessories & Gadgets'),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            final isWish = _wishlistedIds.contains(product.id);
            final bool isDark = Theme.of(context).brightness == Brightness.dark;
            final Color cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
            final Color imgBgColor = isDark ? const Color(0xFF151515) : const Color(0xFFF1F5F9);
            final Color titleColor = isDark ? Colors.white : Colors.black87;
            final Color borderColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE2E8F0);

            return Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailScreen(
                          product: product,
                          isWishlisted: isWish,
                          onWishlistToggle: () => _toggleWishlist(product.id),
                          onAddToCart: (qty) => _addToCartWithQuantity(product, qty),
                        ),
                      ),
                    ).then((result) {
                      if (result == 'buy_now') {
                        setState(() => _currentTabIndex = 3);
                      } else {
                        // Reload state on returning back to ensure wishlist is perfectly in sync
                        setState(() {});
                      }
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor, width: 1),
                      boxShadow: isDark
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Image/Icon Badge (Off-white background)
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: imgBgColor,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              ),
                              child: product.imagePath != null && product.imagePath!.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                      child: Image.network(
                                        _resolveImageUrl(product.imagePath),
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Center(
                                          child: Icon(
                                            Icons.devices_other_outlined,
                                            size: 40,
                                            color: Color(0xFFE0533C),
                                          ),
                                        ),
                                      ),
                                    )
                                  : const Center(
                                      child: Icon(
                                        Icons.devices_other_outlined,
                                        size: 40,
                                        color: Color(0xFFE0533C),
                                      ),
                                    ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Status Pill
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE0533C).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'New in',
                                    style: TextStyle(
                                      color: Color(0xFFE0533C),
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Product Title
                                Text(
                                  product.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: titleColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Price
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '₹${product.price.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: isDark ? Colors.white : AppTheme.accent,
                                      ),
                                    ),
                                    // Shopping Cart Icon Button (Bottom Right)
                                    GestureDetector(
                                      onTap: () => _addToCart(product),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE0533C).withOpacity(0.08),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.add_shopping_cart_outlined,
                                          size: 14,
                                          color: Color(0xFFE0533C),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Wishlist Heart Icon Badge (Top Right)
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _toggleWishlist(product.id),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          isWish ? Icons.favorite : Icons.favorite_border,
                          size: 14,
                          color: isWish ? const Color(0xFFFF4B4B) : Colors.black45,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
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

  InputDecoration _cartInputDecoration({
    required String labelText,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppTheme.primary.withOpacity(0.7), size: 20) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      labelStyle: const TextStyle(fontSize: 13, color: Colors.black54),
      floatingLabelStyle: const TextStyle(fontSize: 14, color: AppTheme.primary, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildCartPage() {
    final double total = _cart.fold(0, (sum, item) => sum + item.price);

    return _cart.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Your Cart is Empty',
                    style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Browse our premium catalog of gadgets, screen repairs, and audio accessories to add items.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _currentTabIndex = 0; // Go to catalog tab
                        });
                      },
                      child: const Text('Explore Catalog'),
                    ),
                  ),
                ],
              ),
            ),
          )
        : RefreshIndicator(
            onRefresh: _loadCatalog,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _cartFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cart Items Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Shopping List (${_cart.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _cart.clear();
                            });
                          },
                          child: const Text('Clear All', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Cart Items List
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _cart.length,
                      itemBuilder: (context, index) {
                        final item = _cart[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: AppTheme.premiumShadow,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: AppTheme.badgeBg,
                                shape: BoxShape.circle,
                              ),
                              child: item.imagePath != null && item.imagePath!.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Image.network(
                                        _resolveImageUrl(item.imagePath),
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Icon(
                                          _getServiceIcon(item.title, item.deviceType),
                                          size: 20,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      _getServiceIcon(item.title, item.deviceType),
                                      size: 20,
                                      color: AppTheme.primary,
                                    ),
                            ),
                            title: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                            ),
                            subtitle: Text(
                              item.deviceType,
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '₹${item.price.toStringAsFixed(0)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accent, fontSize: 14),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
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
                    
                    const SizedBox(height: 20),
                    const Text('Delivery Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 10),

                    // Checkout Form Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: AppTheme.premiumShadow,
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _cartNameController,
                            decoration: _cartInputDecoration(labelText: 'Full Name *', prefixIcon: Icons.person_outline),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Enter full name' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _cartPhoneController,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: _cartInputDecoration(labelText: '10-Digit Mobile Number *', prefixIcon: Icons.phone_outlined),
                            validator: (v) => v == null || v.trim().length != 10 ? 'Enter valid phone' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _cartAddressController,
                            maxLines: 2,
                            decoration: _cartInputDecoration(labelText: 'Delivery Address *', prefixIcon: Icons.home_outlined),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Enter address' : null,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Price Summary Breakdown Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: AppTheme.premiumShadow,
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Order Summary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                          const SizedBox(height: 8),
                          const Divider(color: Color(0xFFF1F5F9)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Items Subtotal', style: TextStyle(color: Colors.black54, fontSize: 12)),
                              Text('₹${total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('Delivery Charge', style: TextStyle(color: Colors.black54, fontSize: 12)),
                              Text('FREE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.success)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: Color(0xFFF1F5F9)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                              Text('₹${total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.accent, fontSize: 18)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        shadowColor: AppTheme.accent.withOpacity(0.4),
                        elevation: 2,
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
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'PLACE ORDER',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAppBarTitle() {
    switch (_currentTabIndex) {
      case 0:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 28,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.build_circle_outlined, color: Color(0xFFE0533C), size: 24);
              },
            ),
            const SizedBox(height: 2),
            const Text(
              'electronics care',
              style: TextStyle(
                color: Color(0xFFE0533C),
                fontSize: 8,
                letterSpacing: 0.8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      case 1:
        return const Text(
          'Wishlist',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        );
      case 2:
        return const Text(
          'Track Shipment',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        );
      case 3:
        return const Text(
          'Shopping Cart',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        );
      default:
        return const Text('');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
        title: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: _buildAppBarTitle(),
        ),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                onPressed: () {
                  themeProvider.toggleTheme(!isDark);
                },
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              onPressed: _showNotificationsDialog,
              icon: Badge(
                isLabelVisible: _hasNewNotifications,
                child: Icon(
                  Icons.notifications_none_outlined,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 60 + MediaQuery.of(context).padding.bottom,
        decoration: const BoxDecoration(
          color: Color(0xFF151515),
          border: Border(
            top: BorderSide(color: Color(0xFF242424), width: 1.5),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildFlatNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
              _buildFlatNavItem(1, Icons.favorite_border, Icons.favorite, 'Wishlist', badgeCount: _wishlistedIds.length),
              _buildFlatNavItem(2, Icons.local_shipping_outlined, Icons.local_shipping, 'Track'),
              _buildFlatNavItem(3, Icons.shopping_cart_outlined, Icons.shopping_cart, 'Cart', badgeCount: _cart.length),
            ],
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: _buildCurrentPage(),
        ),
      ),
    );
  }

  Widget _buildFlatNavItem(int index, IconData outlineIcon, IconData filledIcon, String label, {int badgeCount = 0}) {
    final isSelected = _currentTabIndex == index;
    final activeColor = const Color(0xFFE0533C);
    final inactiveColor = const Color(0xFF6B7280);

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentTabIndex = index;
          });
        },
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? filledIcon : outlineIcon,
                  color: isSelected ? activeColor : inactiveColor,
                  size: 24,
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0533C),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF151515), width: 1.5),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        badgeCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            // Underline Indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: isSelected ? 24 : 0,
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
            const SizedBox(height: 4),
          ],
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
    Color indicatorColor = AppTheme.primary;
    switch (category) {
      case 'Smartphone':
        title = 'Smartphone services';
        indicatorColor = const Color(0xFF3B82F6);
        break;
      case 'Laptop':
        title = 'Laptop services';
        indicatorColor = const Color(0xFF10B981);
        break;
      case 'LED TV':
        title = 'LED TV services';
        indicatorColor = const Color(0xFFF59E0B);
        break;
      case 'Accessories & Gadgets':
        title = 'Accessories & Gadgets';
        indicatorColor = const Color(0xFF8B5CF6);
        break;
      default:
        title = '$category services';
        indicatorColor = AppTheme.accent;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: indicatorColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
              letterSpacing: -0.2,
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

  void _addToCartWithQuantity(ServiceItem item, int quantity) {
    setState(() {
      for (int i = 0; i < quantity; i++) {
        _cart.add(item);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$quantity x ${item.title} added to cart!'),
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
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: item.imagePath != null && item.imagePath!.isNotEmpty
                                  ? Colors.transparent
                                  : AppTheme.badgeBg,
                              shape: BoxShape.circle,
                            ),
                            child: item.imagePath != null && item.imagePath!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      _resolveImageUrl(item.imagePath),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Center(
                                        child: Icon(
                                          _getServiceIcon(item.title, item.deviceType),
                                          size: 16,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Icon(
                                      _getServiceIcon(item.title, item.deviceType),
                                      size: 16,
                                      color: AppTheme.primary,
                                    ),
                                  ),
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
                      decoration: _cartInputDecoration(labelText: 'Full Name *', prefixIcon: Icons.person_outline),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Enter full name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _cartInputDecoration(labelText: '10-Digit Mobile Number *', prefixIcon: Icons.phone_outlined),
                      validator: (v) => v == null || v.trim().length != 10 ? 'Enter valid phone' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: addressController,
                      maxLines: 2,
                      decoration: _cartInputDecoration(labelText: 'Delivery Address *', prefixIcon: Icons.home_outlined),
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
          decoration: InputDecoration(hintText: 'Enter Reference (e.g. TKZ-00000)', border: OutlineInputBorder()),
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
  int _currentStep = 0;

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
                      decoration: InputDecoration(
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
                      decoration: InputDecoration(
                        labelText: 'Review Comments',
                        hintText: 'Tell us about the service...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(10),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                        side: const BorderSide(color: Colors.black12, width: 1),
                      ),
                      shadowColor: Colors.black.withOpacity(0.1),
                      elevation: 2,
                    ),
                    onPressed: () async {
                      final comment = reviewController.text.trim();
                      if (comment.isNotEmpty) {
                        final name = nameController.text.trim().isEmpty ? 'Customer' : nameController.text.trim();
                        final payload = {
                          'item_name': widget.service.title,
                          'device_type': widget.service.deviceType,
                          'name': name,
                          'rating': selectedRating,
                          'text': comment
                        };
                        // Submit review to background API asynchronously
                        ApiService.submitReview(payload);
                      }
                      Navigator.pop(context);
                    },
                    child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color inputFillColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8FAFC);
    final Color inputBorderColor = isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade200;
    final Color inputLabelColor = isDark ? Colors.white70 : Colors.black54;
    final Color prefixIconColor = isDark ? const Color(0xFFE0533C) : AppTheme.primary.withOpacity(0.7);

    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black38, fontSize: 13),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: prefixIconColor, size: 20) : null,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: inputBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: inputBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0533C), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      filled: true,
      fillColor: inputFillColor,
      labelStyle: TextStyle(fontSize: 13, color: inputLabelColor),
      floatingLabelStyle: TextStyle(
        fontSize: 14,
        color: isDark ? Colors.white70 : const Color(0xFFE0533C),
        fontWeight: FontWeight.w600,
      ),
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

  void _nextStep() {
    if (_currentStep == 0) {
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
    } else if (_currentStep == 1) {
      if (_descriptionController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please describe the issue')),
        );
        return;
      }
    } else if (_currentStep == 2) {
      if (!_formKey.currentState!.validate()) {
        return;
      }
      if (_isPincodeValid != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid & covered pincode')),
        );
        return;
      }
    }

    setState(() {
      _currentStep++;
    });
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Widget _buildStepDeviceDetails() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1E3A8A).withOpacity(0.2), const Color(0xFF1E3A8A).withOpacity(0.1)]
                  : [AppTheme.primary.withOpacity(0.06), AppTheme.primary.withOpacity(0.12)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF1E3A8A).withOpacity(0.3) : AppTheme.primary.withOpacity(0.15),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.service.imagePath != null && widget.service.imagePath!.isNotEmpty
                      ? Colors.transparent
                      : (isDark ? const Color(0xFF1E1E1E) : AppTheme.badgeBg),
                  shape: BoxShape.circle,
                ),
                child: widget.service.imagePath != null && widget.service.imagePath!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          _resolveImageUrl(widget.service.imagePath),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Icon(
                              _getServiceIcon(widget.service.title, widget.service.deviceType),
                              color: isDark ? const Color(0xFFE0533C) : AppTheme.primary,
                              size: 24,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          _getServiceIcon(widget.service.title, widget.service.deviceType),
                          color: isDark ? const Color(0xFFE0533C) : AppTheme.primary,
                          size: 24,
                        ),
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
                        color: isDark ? const Color(0xFFE0533C) : AppTheme.primary.withOpacity(0.8),
                      ),
                    ),
                    Text(
                      widget.service.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Starts at',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white54 : Colors.black54,
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
        const SizedBox(height: 16),

        if (_reviews.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Verified Reviews',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${(_reviews.fold<double>(0, (sum, r) => sum + (r['rating'] as num).toDouble()) / _reviews.length).toStringAsFixed(1)} (${_reviews.length})',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 70,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _reviews.length,
                    itemBuilder: (context, index) {
                      final rev = _reviews[index];
                      final rating = rev['rating'] as int;
                      return Container(
                        width: 240,
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF151515) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  rev['name'] ?? 'Customer',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                                Row(
                                  children: List.generate(
                                    5,
                                    (i) => Icon(
                                      Icons.star,
                                      color: i < rating ? Colors.amber : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                                      size: 10,
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
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                                  height: 1.2,
                                ),
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
          const SizedBox(height: 16),
        ],

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _isLoadingBrands
                      ? const SkeletonLoader(width: double.infinity, height: 48, borderRadius: 12)
                      : _brands.isEmpty
                          ? TextFormField(
                              controller: _customBrandController,
                              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87, fontSize: 13),
                              decoration: _inputDecoration(labelText: 'Device Brand *', prefixIcon: Icons.branding_watermark_outlined),
                            )
                          : DropdownButtonFormField<Brand>(
                              isExpanded: true,
                              value: _selectedBrand,
                              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87, fontSize: 13),
                              dropdownColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
                              iconEnabledColor: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                              decoration: _inputDecoration(labelText: 'Device Brand *', prefixIcon: Icons.branding_watermark_outlined),
                              hint: Text('Select Brand...', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black45)),
                              items: _brands.map((b) => DropdownMenuItem(value: b, child: Text(b.name, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87)))).toList(),
                              onChanged: _onBrandSelected,
                            ),
                  if (_selectedBrand?.id == 'custom') ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _customBrandController,
                      style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87, fontSize: 13),
                      decoration: _inputDecoration(labelText: 'Type brand name...', prefixIcon: Icons.edit_note_outlined),
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
                      ? const SkeletonLoader(width: double.infinity, height: 48, borderRadius: 12)
                      : (_models.isEmpty || _selectedBrand?.id == 'custom')
                          ? TextFormField(
                              controller: _customModelController,
                              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87, fontSize: 13),
                              decoration: _inputDecoration(labelText: 'Device Model *', prefixIcon: Icons.phone_android_outlined, hintText: 'e.g. iPhone 14'),
                            )
                          : DropdownButtonFormField<DeviceModel>(
                              isExpanded: true,
                              value: _selectedModel,
                              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87, fontSize: 13),
                              dropdownColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
                              iconEnabledColor: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54,
                              decoration: _inputDecoration(labelText: 'Device Model *', prefixIcon: Icons.phone_android_outlined),
                              hint: Text('Select Model...', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black45)),
                              items: _models.map((m) => DropdownMenuItem(value: m, child: Text(m.name, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87)))).toList(),
                              onChanged: (val) => setState(() => _selectedModel = val),
                            ),
                  if (_selectedModel?.id == 'custom' && _selectedBrand?.id != 'custom') ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _customModelController,
                      style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87, fontSize: 13),
                      decoration: _inputDecoration(labelText: 'Type model name...', prefixIcon: Icons.edit_note_outlined),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepIssueDetails() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'WHAT IS GOING WRONG?',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white60 : Colors.black54, letterSpacing: 0.8),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _descriptionController,
          maxLines: 4,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
          decoration: _inputDecoration(
            labelText: 'Describe the Issue *',
            prefixIcon: Icons.description_outlined,
            hintText: 'Please share details like: when did this start, what is not working properly, etc.',
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'VISUAL PROOF (OPTIONAL)',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white60 : Colors.black54, letterSpacing: 0.8),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _imageFile != null
                    ? const Color(0xFFE0533C).withOpacity(0.3)
                    : (isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade300),
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              children: [
                if (_imageFile == null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF151515) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.add_photo_alternate_outlined, color: isDark ? Colors.white70 : Colors.black54),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Upload Device Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : Colors.black87)),
                        const SizedBox(height: 2),
                        Text('Helps technician understand the damage better', style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black45)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 14, color: isDark ? Colors.white38 : Colors.black38),
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
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : Colors.black87),
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
      ],
    );
  }

  Widget _buildStepContactDetails() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'YOUR INFORMATION',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white60 : Colors.black54, letterSpacing: 0.8),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _nameController,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
          decoration: _inputDecoration(labelText: 'Full Name *', prefixIcon: Icons.person_outline),
          validator: (v) => v == null || v.trim().isEmpty ? 'Enter full name' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
          decoration: _inputDecoration(labelText: '10-Digit Mobile Number *', prefixIcon: Icons.phone_outlined),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Enter mobile number';
            final trimmed = v.trim();
            if (trimmed.length != 10) return 'Mobile number must be 10 digits';
            if (!RegExp(r'^[6-9]\d{9}$').hasMatch(trimmed)) return 'Must start with 6, 7, 8, or 9';
            return null;
          },
        ),
        const SizedBox(height: 8),
        Text(
          'SCHEDULE & LOCATION',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white60 : Colors.black54, letterSpacing: 0.8),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _pincodeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
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
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
                    border: Border.all(color: isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month_outlined, color: isDark ? const Color(0xFFE0533C) : AppTheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          DateFormat('dd MMM yyyy').format(_selectedDate), 
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87)
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
          const SizedBox(height: 4),
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
                      fontSize: 11,
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
      ],
    );
  }

  Widget _buildStepSummaryConfirm() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final brandName = _selectedBrand?.id == 'custom'
        ? _customBrandController.text.trim()
        : _selectedBrand?.name ?? _customBrandController.text.trim();
    final modelName = _selectedModel?.id == 'custom'
        ? _customModelController.text.trim()
        : _selectedModel?.name ?? _customModelController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'BOOKING SUMMARY TICKET',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white60 : Colors.black54,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200),
            boxShadow: AppTheme.premiumShadow,
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE0533C), Color(0xFFC0392B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.confirmation_num_outlined, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.service.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _summaryRow('Device', '$brandName $modelName'),
                    const SizedBox(height: 8),
                    _summaryRow('Preferred Date', DateFormat('EEEE, dd MMM yyyy').format(_selectedDate)),
                    const SizedBox(height: 8),
                    _summaryRow('Customer', _nameController.text.trim()),
                    const SizedBox(height: 8),
                    _summaryRow('Mobile No.', _phoneController.text.trim()),
                    const SizedBox(height: 8),
                    _summaryRow('Pincode', _pincodeController.text.trim()),
                    const SizedBox(height: 8),
                    _summaryRow('Visit Address', _addressController.text.trim()),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF1F5F9), height: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Service Charge', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13)),
                        Text('₹${widget.service.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.accent, fontSize: 18)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black87,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveStepWidget() {
    switch (_currentStep) {
      case 0:
        return _buildStepDeviceDetails();
      case 1:
        return _buildStepIssueDetails();
      case 2:
        return _buildStepContactDetails();
      case 3:
        return _buildStepSummaryConfirm();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double stepProgress = (_currentStep + 1) / 4.0;
    final List<String> stepTitles = [
      'Device Details',
      'Describe the Issue',
      'Contact & Location',
      'Summary & Confirm',
    ];

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color sheetBg = isDark ? const Color(0xFF121212) : Colors.white;
    final Color titleColor = isDark ? Colors.white : Colors.black87;
    final Color dividerColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF1F5F9);
    final Color closeBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100;
    final Color progressTrackBg = isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100;

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 16, spreadRadius: 2),
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
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF333333) : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Book ${widget.service.title}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: titleColor),
                    ),
                  ),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: closeBgColor,
                      minimumSize: const Size(32, 32),
                    ),
                    icon: Icon(Icons.close, size: 18, color: titleColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Divider(height: 20, color: dividerColor),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'STEP ${_currentStep + 1} OF 4',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFE0533C), letterSpacing: 0.8),
                      ),
                      Text(
                        stepTitles[_currentStep],
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: titleColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: stepProgress,
                      minHeight: 6,
                      backgroundColor: progressTrackBg,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE0533C)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _buildActiveStepWidget(),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            side: BorderSide(color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                          onPressed: _prevStep,
                          child: Text(
                            'Back',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                          side: const BorderSide(color: Colors.black12, width: 1),
                        ),
                        shadowColor: Colors.black.withOpacity(0.1),
                        elevation: 2,
                      ),
                      onPressed: _isSubmitting 
                          ? null 
                          : (_currentStep == 3 ? _submitBooking : _nextStep),
                      child: _isSubmitting
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                          : Text(
                              _currentStep == 3 
                                  ? 'CONFIRM BOOKING — ₹${widget.service.price.toStringAsFixed(0)}' 
                                  : 'Continue',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
                            ),
                    ),
                  ),
                ],
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
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2C2C2C)
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

