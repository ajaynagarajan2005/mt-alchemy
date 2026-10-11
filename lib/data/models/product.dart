enum ProductCategory { toolkit, cards, book, workshop }

extension ProductCategoryLabel on ProductCategory {
  String get label => switch (this) {
    ProductCategory.toolkit => 'Toolkits',
    ProductCategory.cards => 'Card decks',
    ProductCategory.book => 'Books',
    ProductCategory.workshop => 'Workshop kits',
  };
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.summary,
    required this.description,
    required this.details,
  });

  final String id;
  final String name;
  final ProductCategory category;
  final double price;
  final String summary;
  final String description;
  final List<String> details;
}
