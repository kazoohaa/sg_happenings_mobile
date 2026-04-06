class CategoryOption {
  const CategoryOption({required this.id, required this.name});

  final String id;
  final String name;

  factory CategoryOption.fromJson(Map<String, dynamic> json) {
    return CategoryOption(
      id: json['category_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] as String? ?? json['category_name'] as String? ?? '',
    );
  }
}
