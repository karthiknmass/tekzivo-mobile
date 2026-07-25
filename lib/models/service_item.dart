class ServiceItem {
  final int id;
  final String title;
  final String deviceType;
  final String description;
  final double price;
  final String duration;
  final String icon;
  final String? imagePath;
  final String? brandName;
  final String? colorOptions;
  final bool active;

  ServiceItem({
    required this.id,
    required this.title,
    required this.deviceType,
    required this.description,
    required this.price,
    required this.duration,
    required this.icon,
    this.imagePath,
    this.brandName,
    this.colorOptions,
    this.active = true,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title'] ?? json['name'] ?? '',
      deviceType: json['device_type'] ?? 'Smartphone',
      description: json['description'] ?? '',
      price: double.tryParse((json['base_price'] ?? json['price'] ?? 0).toString()) ?? 0.0,
      duration: json['duration'] ?? '1 hour',
      icon: json['icon'] ?? 'wrench',
      imagePath: json['image_path'],
      brandName: json['brand_name'],
      colorOptions: json['color_options'],
      active: json['active'] ?? true,
    );
  }
}
