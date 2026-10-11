import 'package:flutter_test/flutter_test.dart';
import 'package:mt_alchemy/data/mock/articles.dart';
import 'package:mt_alchemy/screens/insights/insights_logic.dart';

void main() {
  test('filters by category, newest first', () {
    final all = filterArticles(articles, null);
    expect(all.length, articles.length);
    expect(all.first.published.isAfter(all.last.published), isTrue);
    final one = filterArticles(articles, 'Leadership');
    expect(one.every((a) => a.category == 'Leadership'), isTrue);
    expect(filterArticles(articles, 'Nope'), isEmpty);
  });

  test('related excludes the current article', () {
    final r = relatedArticles(articles.first, articles, 2);
    expect(r.length, 2);
    expect(r.any((a) => a.slug == articles.first.slug), isFalse);
  });
}
