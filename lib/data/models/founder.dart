/// One of the people who founded the site. Shown in the "Meet the founders"
/// section; the photo is optional so a card is never broken without one.
class Founder {
  const Founder({
    required this.id,
    required this.name,
    this.role = 'Founder',
    this.bio = '',
    this.imageUrl,
    this.order = 0,
  });

  final String id;
  final String name;
  final String role;
  final String bio;

  /// An https URL, a bundled `asset:` path, or a `data:image/...` URL when
  /// uploaded from the site (the super admin's "Upload photo").
  final String? imageUrl;
  final int order;

  String get initials {
    final parts = name
        .replaceAll('.', ' ')
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'role': role,
    'bio': bio,
    'imageUrl': imageUrl,
    'order': order,
  };

  factory Founder.fromMap(String id, Map<String, dynamic> m) => Founder(
    id: id,
    name: m['name'] as String? ?? '',
    role: m['role'] as String? ?? 'Founder',
    bio: m['bio'] as String? ?? '',
    imageUrl: m['imageUrl'] as String?,
    order: (m['order'] as num?)?.toInt() ?? 0,
  );

  Founder copyWith({
    String? name,
    String? role,
    String? bio,
    String? imageUrl,
    int? order,
  }) => Founder(
    id: id,
    name: name ?? this.name,
    role: role ?? this.role,
    bio: bio ?? this.bio,
    imageUrl: imageUrl ?? this.imageUrl,
    order: order ?? this.order,
  );
}
