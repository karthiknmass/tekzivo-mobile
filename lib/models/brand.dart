class Brand {
  final int id;
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
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      logoUrl: json['logo_url'],
      active: json['active'] ?? true,
    );
  }
}

class DeviceModel {
  final int id;
  final int brandId;
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
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      brandId: json['brand_id'] is int ? json['brand_id'] : int.parse(json['brand_id'].toString()),
      name: json['name'] ?? '',
      active: json['active'] ?? true,
    );
  }
}
