class Showroom {
  final int id;
  final String name;
  final String? location;
  final bool isActive;
  final String? createdAt;

  Showroom({
    required this.id,
    required this.name,
    this.location,
    required this.isActive,
    this.createdAt,
  });

  factory Showroom.fromJson(Map<String, dynamic> json) {
    return Showroom(
      id: json['id'] as int,
      name: json['name'] as String,
      location: json['location'] as String?,
      isActive: json['is_active'] == true || json['is_active'] == 1,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'location': location,
        'is_active': isActive,
      };
}
