import 'package:material_ui/material_ui.dart';

import '../../theme/colors.dart';
import '../../theme/radii.dart';
import '../../theme/typography.dart';

/// True when every word typed in [query] appears somewhere in [haystack],
/// ignoring case. An empty query matches everything.
bool matchesQuery(String query, Iterable<String> haystack) {
  final words = query
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty);
  if (words.isEmpty) return true;
  final text = haystack.join(' ').toLowerCase();
  return words.every(text.contains);
}

/// A search box with a clear button. [onChanged] fires on every keystroke.
class SearchField extends StatefulWidget {
  const SearchField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.maxWidth = 480,
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final double maxWidth;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: Radii.pillAll,
      borderSide: BorderSide(color: AppColors.grey300),
    );
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: widget.maxWidth),
      child: Semantics(
        textField: true,
        label: widget.hint,
        child: TextField(
          controller: _controller,
          onChanged: (v) {
            setState(() {});
            widget.onChanged(v);
          },
          textInputAction: TextInputAction.search,
          style: AppText.body,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: AppText.bodyMuted,
            filled: true,
            fillColor: AppColors.surface,
            prefixIcon: Icon(Icons.search, color: AppColors.grey500),
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    icon: Icon(Icons.close, color: AppColors.grey500),
                    onPressed: () {
                      _controller.clear();
                      setState(() {});
                      widget.onChanged('');
                    },
                  ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),
            border: border,
            enabledBorder: border,
            focusedBorder: OutlineInputBorder(
              borderRadius: Radii.pillAll,
              borderSide: BorderSide(color: AppColors.red, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}
