enum ProductCategory { toolkit, cards, book, workshop }

extension ProductCategoryLabel on ProductCategory {
  String get label => switch (this) {
    ProductCategory.toolkit => 'Toolkits',
    ProductCategory.cards => 'Card decks',
    ProductCategory.book => 'Books',
    ProductCategory.workshop => 'Workshop kits',
  };
}

/// Digital products are downloaded after payment; physical ones are shipped.
enum ProductType { digital, physical }

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.summary,
    required this.description,
    required this.details,
    this.type = ProductType.physical,
    this.stock = 0,
    this.fileUrl,
  });

  final String id;
  final String name;
  final ProductCategory category;
  final double price;
  final String summary;
  final String description;
  final List<String> details;
  final ProductType type;

  /// Units on hand (physical products only).
  final int stock;

  /// Download location (digital products only).
  final String? fileUrl;

  bool get isDigital => type == ProductType.digital;
  bool get inStock => isDigital || stock > 0;

  Map<String, dynamic> toMap() => {
    'name': name,
    'category': category.name,
    'price': price,
    'summary': summary,
    'description': description,
    'details': details,
    'type': type.name,
    'stock': stock,
    'fileUrl': fileUrl,
  };

  factory Product.fromMap(String id, Map<String, dynamic> m) => Product(
    id: id,
    name: m['name'] as String? ?? '',
    category: ProductCategory.values.firstWhere(
      (c) => c.name == m['category'],
      orElse: () => ProductCategory.toolkit,
    ),
    price: (m['price'] as num?)?.toDouble() ?? 0,
    summary: m['summary'] as String? ?? '',
    description: m['description'] as String? ?? '',
    details: List<String>.from(m['details'] as List? ?? const []),
    type: m['type'] == 'digital' ? ProductType.digital : ProductType.physical,
    stock: (m['stock'] as num?)?.toInt() ?? 0,
    fileUrl: m['fileUrl'] as String?,
  );

  Product copyWith({
    String? name,
    ProductCategory? category,
    double? price,
    String? summary,
    String? description,
    List<String>? details,
    ProductType? type,
    int? stock,
    String? fileUrl,
  }) => Product(
    id: id,
    name: name ?? this.name,
    category: category ?? this.category,
    price: price ?? this.price,
    summary: summary ?? this.summary,
    description: description ?? this.description,
    details: details ?? this.details,
    type: type ?? this.type,
    stock: stock ?? this.stock,
    fileUrl: fileUrl ?? this.fileUrl,
  );
}
