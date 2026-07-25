class Technician {
  final int id;
  final String name;
  final String phone;
  final String email;
  final String specialization;
  final bool active;

  Technician({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.specialization,
    this.active = true,
  });

  factory Technician.fromJson(Map<String, dynamic> json) {
    return Technician(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      specialization: json['specialization'] ?? 'General Repair',
      active: json['active'] ?? true,
    );
  }
}
