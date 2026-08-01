import 'package:flutter/material.dart';
import '../../models/service_item.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';

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

    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 340,
              floating: false,
              pinned: true,
              backgroundColor: Colors.white,
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
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: AppTheme.premiumShadow,
                      ),
                      child: const Icon(Icons.chevron_left, color: Colors.black87, size: 24),
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
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: AppTheme.premiumShadow,
                      ),
                      child: const Icon(Icons.share_outlined, color: Colors.black87, size: 20),
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
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: AppTheme.premiumShadow,
                      ),
                      child: Icon(
                        _isWishlisted ? Icons.favorite : Icons.favorite_border,
                        color: _isWishlisted ? AppTheme.accent : Colors.black87,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: const Color(0xFFF8FAFC),
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
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(24),
                                            boxShadow: AppTheme.premiumShadow,
                                            border: Border.all(color: Colors.white, width: 3),
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
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
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
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Seller: ${widget.product.brandName ?? 'Tekzivo Official'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
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
                      color: Colors.amber.shade50,
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
                  const Text(
                    '(320 Reviews)',
                    style: TextStyle(
                      color: Colors.black45,
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
                  const Text(
                    'Color Picker',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    _parsedColors[_selectedColorIndex]['name'],
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
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
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade100, width: 1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Quantity Picker capsule
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, color: Colors.black87, size: 18),
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
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.black87, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      onPressed: () {
                        setState(() => _quantity++);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Cart submit button
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: () {
                      widget.onAddToCart(_quantity);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                    label: const Text(
                      'Add to Cart',
                      style: TextStyle(
                        fontSize: 15,
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
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black54,
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
        return Text(
          defaultDesc,
          key: const ValueKey(0),
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 13,
            height: 1.5,
          ),
        );
    }
  }

  Widget _specRow(String label, String value, bool isEven) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isEven ? const Color(0xFFF8FAFC) : Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _reviewRow(String name, double rating, String comment) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
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
                    color: index < rating ? Colors.amber : Colors.grey.shade300,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(comment, style: const TextStyle(color: Colors.black54, fontSize: 12, height: 1.4)),
        ],
      ),
    );
  }
}
