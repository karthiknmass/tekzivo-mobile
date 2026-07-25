class Brand {
  final String id;
  final String name;
  final String? logoUrl;
  final bool active;

  Brand({
    required this.id,
    required this.name,
    this.logoUrl,
    this.active = true,
  });

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      logoUrl: json['logo_url'],
      active: json['active'] ?? true,
    );
  }
}

class DeviceModel {
  final String id;
  final String brandId;
  final String name;
  final bool active;

  DeviceModel({
    required this.id,
    required this.brandId,
    required this.name,
    this.active = true,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id']?.toString() ?? '',
      brandId: json['brand_id']?.toString() ?? '',
      name: json['name'] ?? '',
      active: json['active'] ?? true,
    );
  }
}
