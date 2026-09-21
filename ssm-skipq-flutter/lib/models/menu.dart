class Category {
  const Category({
    required this.id,
    required this.name,
    this.icon = 'restaurant',
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final String icon;
  final int sortOrder;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String? ?? 'restaurant',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }
}

class MenuItem {
  const MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.categoryId,
    required this.categoryName,
    required this.imageUrl,
    required this.isVeg,
    required this.available,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String description;
  final num price;
  final String categoryId;
  final String categoryName;
  final String imageUrl;
  final bool isVeg;
  final bool available;
  final DateTime createdAt;

  MenuItem copyWith({
    String? name,
    String? description,
    num? price,
    String? categoryId,
    String? categoryName,
    String? imageUrl,
    bool? isVeg,
    bool? available,
    DateTime? createdAt,
  }) {
    return MenuItem(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      imageUrl: imageUrl ?? this.imageUrl,
      isVeg: isVeg ?? this.isVeg,
      available: available ?? this.available,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: json['price'] as num? ?? 0,
      categoryId: json['categoryId']?.toString() ?? '',
      categoryName: json['categoryName'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      isVeg: json['isVeg'] as bool? ?? true,
      available: json['available'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
