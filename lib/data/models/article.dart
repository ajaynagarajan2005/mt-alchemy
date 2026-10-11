class Article {
  const Article({
    required this.slug,
    required this.title,
    required this.category,
    required this.readMinutes,
    required this.published,
    required this.excerpt,
    required this.body,
  });

  final String slug;
  final String title;
  final String category;
  final int readMinutes;
  final DateTime published;
  final String excerpt;

  /// Paragraphs.
  final List<String> body;
}

class Testimonial {
  const Testimonial({
    required this.quote,
    required this.name,
    required this.role,
  });

  final String quote;
  final String name;
  final String role;
}
