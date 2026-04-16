class Setting {
  final int id;
  final String key;
  final String value;
  final String? description;
  final String? updatedAt;

  Setting({
    required this.id,
    required this.key,
    required this.value,
    this.description,
    this.updatedAt,
  });

  factory Setting.fromJson(Map<String, dynamic> json) {
    return Setting(
      id: json['id'] as int,
      key: json['key'] as String,
      value: json['value'].toString(),
      description: json['description'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}
