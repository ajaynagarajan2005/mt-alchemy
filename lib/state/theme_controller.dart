import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Light, dark or follow the browser (prefers-color-scheme), plus the text
/// size. Both choices are saved in the browser, so they survive a refresh and
/// the next visit. Tapping the nav toggle switches between light and dark
/// relative to what is currently showing.
class ThemeController extends ChangeNotifier {
  ThemeController({bool persist = true}) : _persist = persist {
    if (persist) _load();
  }

  static const _modeKey = 'themeMode';
  static const _scaleKey = 'textScale';

  /// Text sizes on offer: normal, large, extra large.
  static const textScales = [1.0, 1.15, 1.3];

  final bool _persist;
  ThemeMode _mode = ThemeMode.system;
  double _textScale = 1.0;

  ThemeMode get mode => _mode;
  double get textScale => _textScale;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_modeKey);
      final savedScale = prefs.getDouble(_scaleKey);
      _mode = ThemeMode.values.firstWhere(
        (m) => m.name == savedMode,
        orElse: () => _mode,
      );
      if (savedScale != null && textScales.contains(savedScale)) {
        _textScale = savedScale;
      }
      notifyListeners();
    } catch (_) {
      // Storage can be blocked (private windows); the defaults still work.
    }
  }

  Future<void> _save() async {
    if (!_persist) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_modeKey, _mode.name);
      await prefs.setDouble(_scaleKey, _textScale);
    } catch (_) {}
  }

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
    _save();
  }

  void setTextScale(double scale) {
    if (_textScale == scale) return;
    _textScale = scale;
    notifyListeners();
    _save();
  }

  /// Flip from the brightness currently showing.
  void toggle(Brightness current) =>
      setMode(current == Brightness.dark ? ThemeMode.light : ThemeMode.dark);
}
