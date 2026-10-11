import 'package:material_ui/material_ui.dart';

/// Light, dark or follow the browser (prefers-color-scheme).
///
/// The choice is kept in memory for the session. Tapping the nav toggle
/// switches between light and dark relative to what is currently showing.
class ThemeController extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  /// Brightness actually in use, given the platform setting.
  Brightness effective(Brightness platform) => switch (_mode) {
    ThemeMode.light => Brightness.light,
    ThemeMode.dark => Brightness.dark,
    ThemeMode.system => platform,
  };

  void setMode(ThemeMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
  }

  /// Flip from the brightness currently showing.
  void toggle(Brightness current) =>
      setMode(current == Brightness.dark ? ThemeMode.light : ThemeMode.dark);
}
