import 'course.dart';
import 'product.dart';

/// What a cart line buys: a store product, a course for yourself, or course
/// seats for your organisation's employees.
enum CartKind { product, course, seats }

class CartItem {
  CartItem.product(Product this.product, {this.quantity = 1})
    : kind = CartKind.product,
      course = null;

  CartItem.course(Course this.course)
    : kind = CartKind.course,
      product = null,
      quantity = 1;

  CartItem.seats(Course this.course, {this.quantity = 1})
    : kind = CartKind.seats,
      product = null;

  final CartKind kind;
  final Product? product;
  final Course? course;
  int quantity;

  /// Unique per line: the same course can be bought once for yourself and
  /// separately as seats.
  String get key => switch (kind) {
    CartKind.product => product!.id,
    CartKind.course => 'course:${course!.id}',
    CartKind.seats => 'seats:${course!.id}',
  };

  String get itemId => product?.id ?? course!.id;

  String get name => switch (kind) {
    CartKind.product => product!.name,
    CartKind.course => course!.title,
    CartKind.seats => '${course!.title} (team seats)',
  };

  double get price => product?.price ?? course!.price;
  double get lineTotal => price * quantity;

  /// Needs a shipping address and a delivery charge.
  bool get isPhysical => kind == CartKind.product && !product!.isDigital;

  /// Course purchases have a fixed quantity of one.
  bool get fixedQuantity => kind == CartKind.course;

  Map<String, dynamic> toMap() => {
    'kind': kind.name,
    'id': itemId,
    'name': name,
    'price': price,
    'quantity': quantity,
    if (product != null) 'type': product!.type.name,
  };
}
