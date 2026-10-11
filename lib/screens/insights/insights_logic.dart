import 'package:intl/intl.dart';

import '../../data/models/article.dart';

/// Distinct categories in first-seen order.
List<String> categoriesOf(List<Article> items) {
  final seen = <String>[];
  for (final a in items) {
    if (!seen.contains(a.category)) seen.add(a.category);
  }
  return seen;
}

/// Newest first. A null [category] means all.
List<Article> filterArticles(List<Article> items, String? category) {
  final list = [
    for (final a in items)
      if (category == null || a.category == category) a,
  ]..sort((a, b) => b.published.compareTo(a.published));
  return list;
}

/// Up to [count] other articles, same category first, then newest.
List<Article> relatedArticles(Article current, List<Article> items, int count) {
  final others = [
    for (final a in items)
      if (a.slug != current.slug) a,
  ]..sort((a, b) => b.published.compareTo(a.published));
  final same = [
    for (final a in others)
      if (a.category == current.category) a,
  ];
  final rest = [
    for (final a in others)
      if (a.category != current.category) a,
  ];
  return [...same, ...rest].take(count).toList();
}

final _date = DateFormat('d MMMM yyyy');
String formatDate(DateTime d) => _date.format(d);
