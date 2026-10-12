import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../data/backend.dart';
import '../data/mock/articles.dart' as seed;
import '../data/mock/courses.dart' as seed;
import '../data/mock/products.dart' as seed;
import '../data/models/article.dart';
import '../data/models/course.dart';
import '../data/models/product.dart';

/// Live catalogue from Firestore: courses, products, articles and impact
/// stories, plus admin create/update/delete.
///
/// Starts with the bundled seed catalogue so pages paint instantly and still
/// work offline; each collection is replaced as soon as Firestore answers.
class CatalogStore extends ChangeNotifier {
  CatalogStore(this._backend) {
    _listen();
  }

  final Backend _backend;
  final _subs = <StreamSubscription<Object?>>[];

  List<Course> _courses = seed.courses;
  List<Product> _products = seed.products;
  List<Article> _articles = seed.articles;
  List<Testimonial> _stories = seed.testimonials;
  bool _staff = false;
  bool _live = false;
  String? _error;

  /// Published courses for visitors; every course for trainers and admins.
  List<Course> get courses =>
      _staff ? _courses : _courses.where((c) => c.published).toList();
  List<Course> get allCourses => _courses;
  List<Product> get products => _products;
  List<Article> get articles => _articles;
  List<Testimonial> get stories => _stories;

  /// True once at least one collection has loaded from Firestore.
  bool get isLive => _live;
  String? get error => _error;

  Course? courseById(String id) => _find(_courses, (c) => c.id == id);
  Product? productById(String id) => _find(_products, (p) => p.id == id);
  Article? articleBySlug(String slug) =>
      _find(_articles, (a) => a.slug == slug);

  static T? _find<T>(List<T> list, bool Function(T) test) {
    for (final x in list) {
      if (test(x)) return x;
    }
    return null;
  }

  /// Trainers and admins see unpublished courses too. Called on sign-in.
  void setStaff(bool staff) {
    if (staff == _staff) return;
    _staff = staff;
    _listen();
  }

  void _listen() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    final coursesQuery = _staff
        ? _backend.col('courses')
        : _backend.col('courses').where('published', isEqualTo: true);
    _subs
      ..add(
        _watch(coursesQuery, (d) => Course.fromMap(d.id, d.data()), (list) {
          // Keep unpublished courses we already know about for staff views.
          _courses = list..sort((a, b) => a.price.compareTo(b.price));
        }),
      )
      ..add(
        _watch(
          _backend.col('products'),
          (d) => Product.fromMap(d.id, d.data()),
          (list) => _products = list,
        ),
      )
      ..add(
        _watch(
          _backend.col('articles'),
          (d) => Article.fromMap(d.id, d.data()),
          (list) =>
              _articles = list
                ..sort((a, b) => b.published.compareTo(a.published)),
        ),
      )
      ..add(
        _watch(
          _backend.col('impactStories'),
          (d) => Testimonial.fromMap(d.id, d.data()),
          (list) => _stories = list,
        ),
      );
  }

  StreamSubscription<Object?> _watch<T>(
    Query<Map<String, dynamic>> query,
    T Function(QueryDocumentSnapshot<Map<String, dynamic>>) parse,
    void Function(List<T>) apply,
  ) {
    return query.snapshots().listen(
      (snap) {
        // An empty collection means the database is not seeded yet;
        // keep showing the bundled catalogue rather than a blank page.
        if (snap.docs.isEmpty) return;
        apply([for (final d in snap.docs) parse(d)]);
        _live = true;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _error = friendlyError(e);
        notifyListeners();
      },
    );
  }

  // ---------- Admin CRUD ----------

  /// Creates or replaces a course. Returns an error message or null.
  Future<String?> saveCourse(Course course) => _write(
    () => _backend.col('courses').doc(course.id).set({
      ...course.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }),
  );

  Future<String?> deleteCourse(String id) =>
      _write(() => _backend.col('courses').doc(id).delete());

  Future<String?> saveProduct(Product product) => _write(
    () => _backend.col('products').doc(product.id).set(product.toMap()),
  );

  Future<String?> deleteProduct(String id) =>
      _write(() => _backend.col('products').doc(id).delete());

  Future<String?> saveArticle(Article article) => _write(
    () => _backend.col('articles').doc(article.slug).set(article.toMap()),
  );

  Future<String?> deleteArticle(String slug) =>
      _write(() => _backend.col('articles').doc(slug).delete());

  Future<String?> saveStory(Testimonial story) {
    final ref = story.id.isEmpty
        ? _backend.col('impactStories').doc()
        : _backend.col('impactStories').doc(story.id);
    return _write(() => ref.set(story.toMap()));
  }

  Future<String?> deleteStory(String id) =>
      _write(() => _backend.col('impactStories').doc(id).delete());

  Future<String?> _write(Future<void> Function() op) async {
    try {
      await op();
      return null;
    } catch (e) {
      return friendlyError(e);
    }
  }

  // ---------- Reviews ----------

  Stream<List<Review>> reviewsFor(String targetId) => _backend
      .col('reviews')
      .where('targetId', isEqualTo: targetId)
      .snapshots()
      .map(
        (s) =>
            [for (final d in s.docs) Review.fromMap(d.id, d.data())]..sort(
              (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
                a.createdAt ?? DateTime(0),
              ),
            ),
      );

  Future<String?> addReview({
    required String targetId,
    required String userId,
    required String userName,
    required int rating,
    required String comment,
  }) => _write(
    () => _backend.col('reviews').add({
      'targetId': targetId,
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'comment': comment.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    }),
  );

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }
}
