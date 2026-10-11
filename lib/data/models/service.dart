/// One of MT Alchemy's four practice areas.
class Service {
  const Service({
    required this.slug,
    required this.title,
    required this.short,
    required this.summary,
    required this.outcomes,
    required this.formats,
  });

  final String slug;
  final String title;

  /// One-line description for cards (max ~12 words).
  final String short;
  final String summary;
  final List<String> outcomes;
  final List<String> formats;
}
