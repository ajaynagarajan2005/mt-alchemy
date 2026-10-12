import 'people.dart' show dateFrom;

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

  Map<String, dynamic> toMap() => {
    'title': title,
    'category': category,
    'readMinutes': readMinutes,
    'published': published.toIso8601String(),
    'excerpt': excerpt,
    'body': body,
  };

  factory Article.fromMap(String slug, Map<String, dynamic> m) => Article(
    slug: slug,
    title: m['title'] as String? ?? '',
    category: m['category'] as String? ?? '',
    readMinutes: (m['readMinutes'] as num?)?.toInt() ?? 1,
    published: dateFrom(m['published']) ?? DateTime(2026),
    excerpt: m['excerpt'] as String? ?? '',
    body: List<String>.from(m['body'] as List? ?? const []),
  );
}

/// An impact story or testimonial from a client.
class Testimonial {
  const Testimonial({
    required this.quote,
    required this.name,
    required this.role,
    this.id = '',
    this.metric,
  });

  final String id;
  final String quote;
  final String name;
  final String role;

  /// Optional headline result, e.g. "92% of managers still using the tools".
  final String? metric;

  Map<String, dynamic> toMap() => {
    'quote': quote,
    'name': name,
    'role': role,
    'metric': metric,
  };

  factory Testimonial.fromMap(String id, Map<String, dynamic> m) => Testimonial(
    id: id,
    quote: m['quote'] as String? ?? '',
    name: m['name'] as String? ?? '',
    role: m['role'] as String? ?? '',
    metric: m['metric'] as String?,
  );
}

/// A learner's rating of a course or product.
class Review {
  const Review({
    required this.id,
    required this.targetId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    this.createdAt,
  });

  final String id;

  /// Course or product id.
  final String targetId;
  final String userId;
  final String userName;
  final int rating;
  final String comment;
  final DateTime? createdAt;

  factory Review.fromMap(String id, Map<String, dynamic> m) => Review(
    id: id,
    targetId: m['targetId'] as String? ?? '',
    userId: m['userId'] as String? ?? '',
    userName: m['userName'] as String? ?? '',
    rating: (m['rating'] as num?)?.toInt() ?? 5,
    comment: m['comment'] as String? ?? '',
    createdAt: dateFrom(m['createdAt']),
  );
}
