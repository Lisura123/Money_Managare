class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final bool isActive;
  final int? showroomId;
  final String? showroomName;
  final String? createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    this.showroomId,
    this.showroomName,
    this.createdAt,
  });

  bool get isAdmin => role == 'admin';
  bool get isStaff => role == 'staff';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      isActive: json['is_active'] == true || json['is_active'] == 1,
      showroomId: json['showroom_id'] as int?,
      showroomName: json['showroom']?['name'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'is_active': isActive,
        'showroom_id': showroomId,
      };

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
