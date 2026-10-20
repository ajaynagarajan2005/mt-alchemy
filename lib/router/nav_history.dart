import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'routes.dart';

/// Remembers the pages the visitor has been through so a back button can
/// return to the previous one. The app navigates with `go`, which replaces
/// the page instead of stacking it, so the router's own back stack is empty.
class NavHistory extends ChangeNotifier {
  NavHistory(this._router) {
    _router.routerDelegate.addListener(_onRoute);
    _record(_current);
  }

  final GoRouter _router;
  final _stack = <String>[];
  bool _goingBack = false;

  String get _current =>
      _router.routerDelegate.currentConfiguration.uri.toString();

  void _onRoute() => _record(_current);

  void _record(String location) {
    if (_goingBack) {
      _goingBack = false;
      return;
    }
    if (_stack.isNotEmpty && _stack.last == location) return;
    _stack.add(location);
    // Keep the list short; nobody goes back fifty pages.
    if (_stack.length > 40) _stack.removeAt(0);
    notifyListeners();
  }

  /// The page a back press would open, or null on the first page.
  String? get previous => _stack.length > 1 ? _stack[_stack.length - 2] : null;

  /// Go to the previous page. With no history, go to [fallback].
  void back({String fallback = Routes.home}) {
    final target = previous;
    if (target == null) {
      _router.go(fallback);
      return;
    }
    _stack.removeLast();
    _goingBack = true;
    _router.go(target);
    notifyListeners();
  }

  @override
  void dispose() {
    _router.routerDelegate.removeListener(_onRoute);
    super.dispose();
  }
}
