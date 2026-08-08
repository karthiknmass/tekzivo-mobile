import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/service_item.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/api_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final ServiceItem product;
  final bool isWishlisted;
  final VoidCallback onWishlistToggle;
  final Function(int) onAddToCart;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.isWishlisted,
    required this.onWishlistToggle,
    required this.onAddToCart,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late bool _isWishlisted;
  int _quantity = 1;
  int _selectedColorIndex = 0;
  int _selectedTabIndex = 0; // 0 = Description, 1 = Specifications, 2 = Reviews
  int _currentImageIndex = 0;
  final PageController _imagePageController = PageController();

  List<Map<String, dynamic>> _parsedColors = [];

  @override
  void initState() {
    super.initState();
    _isWishlisted = widget.isWishlisted;
    _initializeColors();
  }

  void _initializeColors() {
    final options = widget.product.colorOptions;
    if (options != null && options.isNotEmpty) {
      final list = options.split(',');
      for (final opt in list) {
        final cleanOpt = opt.trim();
        if (cleanOpt.isEmpty) continue;
        final color = _parseColorName(cleanOpt);
        if (color != null) {
          _parsedColors.add({'name': cleanOpt, 'color': color});
        }
      }
    }
    
    // Fallback if no colors parsed
    if (_parsedColors.isEmpty) {
      _parsedColors = [
        {'name': 'Dark Grey', 'color': const Color(0xFF1E293B)},
        {'name': 'Light Grey', 'color': const Color(0xFFCBD5E1)},
      ];
    }
    _selectedColorIndex = 0;
  }

  Color? _parseColorName(String name) {
    final cleanName = name.trim().toLowerCase();
    switch (cleanName) {
      case 'red': return const Color(0xFFEF4444);
      case 'blue': return const Color(0xFF3B82F6);
      case 'green': return const Color(0xFF10B981);
      case 'yellow': return const Color(0xFFFBBF24);
      case 'orange': return const Color(0xFFF97316);
      case 'purple': return const Color(0xFF8B5CF6);
      case 'pink': return const Color(0xFFEC4899);
      case 'black': return const Color(0xFF0F172A);
      case 'white': return const Color(0xFFF8FAFC);
      case 'grey':
      case 'gray': return const Color(0xFF64748B);
      case 'silver': return const Color(0xFFCBD5E1);
      case 'gold': return const Color(0xFFFFD700);
      case 'brown': return const Color(0xFF78350F);
      case 'maroon': return const Color(0xFF800000);
      default:
        // Try parsing hex starting with #
        if (cleanName.startsWith('#')) {
          try {
            final hex = cleanName.replaceAll('#', '');
            if (hex.length == 6) {
              return Color(int.parse('FF$hex', radix: 16));
            } else if (hex.length == 8) {
              return Color(int.parse(hex, radix: 16));
            }
          } catch (_) {}
        }
        // Try parsing hex without #
        try {
          if (cleanName.length == 6 && int.tryParse(cleanName, radix: 16) != null) {
            return Color(int.parse('FF$cleanName', radix: 16));
          }
        } catch (_) {}
        return null;
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

  List<String> _getImagesList(String? path) {
    if (path == null || path.isEmpty) return [];
    return path.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  String _resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    
    final images = _getImagesList(path);
    if (images.isEmpty) return '';
    final singlePath = images[0];

    if (singlePath.startsWith('http://') || singlePath.startsWith('https://')) {
      return singlePath;
    }
    final cleanPath = singlePath.startsWith('/') ? singlePath.substring(1) : singlePath;
    final base = ApiConstants.baseUrl.replaceAll('/api', '');
    return '$base/$cleanPath';
  }

  @override
  Widget build(BuildContext context) {
    final defaultDesc = widget.product.description.isNotEmpty
        ? widget.product.description
        : "Experience premium, certified quality hardware accessories and parts from Tekzivo. Optimized for durability and long-term device performance.";
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 340,
              floating: false,
              pinned: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              leadingWidth: 64,
              leading: Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: AppTheme.premiumShadow,
                        border: Border.all(color: isDark ? const Color(0xFF2C2C2C) : Colors.transparent, width: 1),
                      ),
                      child: Icon(Icons.chevron_left, color: isDark ? Colors.white : Colors.black87, size: 24),
                    ),
                  ),
                ),
              ),
              actions: [
                Center(
                  child: GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link shared successfully!')),
                      );
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: AppTheme.premiumShadow,
                        border: Border.all(color: isDark ? const Color(0xFF2C2C2C) : Colors.transparent, width: 1),
                      ),
                      child: Icon(Icons.share_outlined, color: isDark ? Colors.white : Colors.black87, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isWishlisted = !_isWishlisted;
                      });
                      widget.onWishlistToggle();
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: AppTheme.premiumShadow,
                        border: Border.all(color: isDark ? const Color(0xFF2C2C2C) : Colors.transparent, width: 1),
                      ),
                      child: Icon(
                        _isWishlisted ? Icons.favorite : Icons.favorite_border,
                        color: _isWishlisted ? AppTheme.accent : (isDark ? Colors.white : Colors.black87),
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: isDark ? const Color(0xFF151515) : const Color(0xFFF8FAFC),
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      // Parallax Image slider
                      // Dynamic Parallax Image slider
                      Builder(
                        builder: (context) {
                          final images = _getImagesList(widget.product.imagePath);
                          final showPlaceholder = images.isEmpty;
                          final itemCount = showPlaceholder ? 1 : images.length;

                          return Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              PageView.builder(
                                controller: _imagePageController,
                                itemCount: itemCount,
                                onPageChanged: (index) {
                                  setState(() {
                                    _currentImageIndex = index;
                                  });
                                },
                                itemBuilder: (context, index) {
                                  final scale = index == _currentImageIndex ? 1.0 : 0.85;
                                  final rotation = index == _currentImageIndex ? 0.0 : (index > _currentImageIndex ? 0.08 : -0.08);
                                  return Center(
                                    child: Transform.rotate(
                                      angle: rotation,
                                      child: Transform.scale(
                                        scale: scale,
                                        child: Container(
                                          width: 260,
                                          height: 260,
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                            borderRadius: BorderRadius.circular(24),
                                            boxShadow: AppTheme.premiumShadow,
                                            border: Border.all(color: isDark ? const Color(0xFF2C2C2C) : Colors.white, width: 3),
                                          ),
                                          child: !showPlaceholder
                                              ? ClipRRect(
                                                  borderRadius: BorderRadius.circular(21),
                                                  child: Image.network(
                                                    _resolveImageUrl(images[index]),
                                                    fit: BoxFit.contain,
                                                    errorBuilder: (context, error, stackTrace) => Center(
                                                      child: Icon(
                                                        _getServiceIcon(widget.product.title, widget.product.deviceType),
                                                        size: 100,
                                                        color: _parsedColors[_selectedColorIndex]['color'],
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              : Center(
                                                  child: Icon(
                                                    _getServiceIcon(widget.product.title, widget.product.deviceType),
                                                    size: 100,
                                                    color: _parsedColors[_selectedColorIndex]['color'],
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              // Indicators
                              if (itemCount > 1)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 24.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(itemCount, (index) {
                                      final isCurrent = index == _currentImageIndex;
                                      return AnimatedContainer(
                                        duration: const Duration(milliseconds: 250),
                                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                        height: 6.0,
                                        width: isCurrent ? 18.0 : 6.0,
                                        decoration: BoxDecoration(
                                          color: isCurrent ? AppTheme.primary : const Color(0xFFCBD5E1),
                                          borderRadius: BorderRadius.circular(3.0),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                            ],
                          );
                        }
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Title
              Text(
                widget.product.title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),

              // Price & Seller Details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₹${widget.product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.accent,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200, width: 1),
                    ),
                    child: Text(
                      'Seller: ${widget.product.brandName ?? 'Tekzivo Official'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Rating pill
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade900.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.star, color: Colors.amber, size: 14),
                        SizedBox(width: 4),
                        Text(
                          '4.8',
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(320 Reviews)',
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black45,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Color Pick Container
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Color Picker',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    _parsedColors[_selectedColorIndex]['name'],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: List.generate(_parsedColors.length, (index) {
                  final isSelected = index == _selectedColorIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColorIndex = index),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppTheme.primary : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _parsedColors[index]['color'],
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 28),

              // Tab Section Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTabItem(0, 'Description'),
                  _buildTabItem(1, 'Specifications'),
                  _buildTabItem(2, 'Reviews'),
                ],
              ),
              const SizedBox(height: 16),

              // Tab content
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _buildTabContent(defaultDesc),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFF151515),
            border: Border(top: BorderSide(color: Color(0xFF242424), width: 1.5)),
          ),
          child: Row(
            children: [
              // Quantity Picker capsule
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF2C2C2C), width: 1),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, color: Colors.white, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      onPressed: () {
                        if (_quantity > 1) {
                          setState(() => _quantity--);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$_quantity',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.white, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      onPressed: () {
                        setState(() => _quantity++);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Add to Cart Button (Secondary style)
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF2C2C2C)),
                      foregroundColor: Colors.white70,
                      backgroundColor: const Color(0xFF1E1E1E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: () {
                      widget.onAddToCart(_quantity);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Added to Cart!'), duration: Duration(seconds: 1)),
                      );
                    },
                    icon: const Icon(Icons.shopping_bag_outlined, size: 16, color: Colors.white70),
                    label: const Text(
                      'Add to Cart',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Buy Now Button (Prominent Brand Orange-Red)
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE0533C),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => QuickCheckoutModalSheet(
                          product: widget.product,
                          quantity: _quantity,
                        ),
                      );
                    },
                    icon: const Icon(Icons.flash_on, size: 16),
                    label: const Text(
                      'Buy Now',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, String label) {
    final isSelected = index == _selectedTabIndex;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFE0533C)
              : (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark ? const Color(0xFF2C2C2C) : Colors.transparent),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black54),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(String defaultDesc) {
    switch (_selectedTabIndex) {
      case 1:
        return Column(
          key: const ValueKey(1),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _specRow('Category', widget.product.deviceType, true),
            _specRow('Brand', widget.product.brandName ?? 'Tekzivo', false),
            _specRow('Delivery Duration', widget.product.duration, true),
            _specRow('Warranty Period', '1 Year Tekzivo Warranty', false),
            _specRow('Condition', 'Brand New Sealed', true),
          ],
        );
      case 2:
        return Column(
          key: const ValueKey(2),
          children: [
            _reviewRow('John K.', 5.0, 'Fantastic build quality, battery matches description completely.'),
            _reviewRow('Tariqul I.', 4.5, 'Sound is outstanding for the price point. Fast doorstep shipment.'),
            _reviewRow('Sarah J.', 4.0, 'Good durability. Packaging was sealed and very neat.'),
          ],
        );
      case 0:
      default:
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        return Text(
          defaultDesc,
          key: const ValueKey(0),
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black87,
            fontSize: 13,
            height: 1.5,
          ),
        );
    }
  }

  Widget _specRow(String label, String value, bool isEven) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color rowBg = isEven
        ? (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8FAFC))
        : (isDark ? const Color(0xFF151515) : Colors.white);
    final Color labelColor = isDark ? Colors.white60 : Colors.black54;
    final Color valueColor = isDark ? Colors.white : Colors.black87;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: rowBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: labelColor, fontSize: 13, fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: valueColor, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _reviewRow(String name, double rating, String comment) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    Icons.star,
                    size: 12,
                    color: index < rating ? Colors.amber : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(comment, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 12, height: 1.4)),
        ],
      ),
    );
  }
}

class QuickCheckoutModalSheet extends StatefulWidget {
  final ServiceItem product;
  final int quantity;

  const QuickCheckoutModalSheet({
    super.key,
    required this.product,
    required this.quantity,
  });

  @override
  State<QuickCheckoutModalSheet> createState() => _QuickCheckoutModalSheetState();
}

class _QuickCheckoutModalSheetState extends State<QuickCheckoutModalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  int _currentStep = 0;
  bool _isSubmitting = false;

  void _nextStep() {
    if (_currentStep == 0) {
      if (!_formKey.currentState!.validate()) return;
    }
    setState(() => _currentStep++);
  }

  void _prevStep() {
    setState(() => _currentStep--);
  }

  Future<void> _submitOrder() async {
    setState(() => _isSubmitting = true);

    final double total = widget.product.price * widget.quantity;
    final payload = {
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'pincode': '600001',
      'address': _addressController.text.trim(),
      'device_type': 'Accessories & Gadgets',
      'issue_type': '${widget.product.title} (Qty: ${widget.quantity})',
      'preferred_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'time_slot': 'Anytime',
      'estimated_price': total
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

      // Close bottom sheet
      Navigator.pop(context);
      // Show Success Dialog
      _showSuccessDialog(refCode);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${result['error'] ?? result['message'] ?? 'Failed to place order'}')),
      );
    }
  }

  void _showSuccessDialog(String refCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Colors.black12, width: 1),
                ),
                shadowColor: Colors.black.withOpacity(0.1),
                elevation: 2,
              ),
              onPressed: () {
                Navigator.pop(context); // Pop dialog
                Navigator.pop(context); // Pop details screen to go back to home screen catalog!
              },
              child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String labelText, IconData? prefixIcon}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: labelText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: isDark ? const Color(0xFFE0533C) : AppTheme.primary, size: 20) : null,
      filled: true,
      fillColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0533C)),
      ),
      labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13),
    );
  }

  Widget _buildStepContactDetails() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'SHIPPING DETAILS',
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
        const SizedBox(height: 12),
        TextFormField(
          controller: _addressController,
          maxLines: 3,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
          decoration: _inputDecoration(labelText: 'Full Delivery Address *', prefixIcon: Icons.home_outlined),
          validator: (v) => v == null || v.trim().isEmpty ? 'Enter delivery address' : null,
        ),
      ],
    );
  }

  Widget _buildStepSummary() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double total = widget.product.price * widget.quantity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'PURCHASE SUMMARY TICKET',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white60 : Colors.black54, letterSpacing: 0.8),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200),
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
                    const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.product.title,
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
                    _summaryRow('Quantity', '${widget.quantity} unit(s)'),
                    const SizedBox(height: 8),
                    _summaryRow('Customer', _nameController.text.trim()),
                    const SizedBox(height: 8),
                    _summaryRow('Mobile No.', _phoneController.text.trim()),
                    const SizedBox(height: 8),
                    _summaryRow('Delivery Address', _addressController.text.trim()),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF1F5F9), height: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Amount', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13)),
                        Text('₹${total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.accent, fontSize: 18)),
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
          width: 110,
          child: Text(label, style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 12)),
        ),
        Expanded(
          child: Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87, fontSize: 12)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color sheetBg = isDark ? const Color(0xFF121212) : Colors.white;
    final Color titleColor = isDark ? Colors.white : Colors.black87;
    final Color dividerColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF1F5F9);
    final Color closeBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100;

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
                  const Expanded(
                    child: Text(
                      'Quick Checkout',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'STEP ${_currentStep + 1} OF 2',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFE0533C), letterSpacing: 0.8),
                  ),
                  Text(
                    _currentStep == 0 ? 'Shipping Details' : 'Summary & Order',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: titleColor),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: (_currentStep + 1) / 2.0,
                  minHeight: 6,
                  backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE0533C)),
                ),
              ),
              const SizedBox(height: 20),
              _currentStep == 0 ? _buildStepContactDetails() : _buildStepSummary(),
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
                          : (_currentStep == 1 ? _submitOrder : _nextStep),
                      child: _isSubmitting
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                          : Text(
                              _currentStep == 1 ? 'CONFIRM ORDER' : 'Continue',
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
