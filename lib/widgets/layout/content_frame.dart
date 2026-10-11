import 'package:material_ui/material_ui.dart';

import '../../theme/breakpoints.dart';
import '../../theme/spacing.dart';

/// Centres page content at a max width of 1600 with fluid gutters.
///
/// CONTAINER (padding + constraints): the Container applies the responsive
/// side gutters and caps the line length so layouts stay readable from
/// 360px phones to 1440px desktops.
class ContentFrame extends StatelessWidget {
  const ContentFrame({
    super.key,
    required this.child,
    this.maxWidth = Space.contentMax,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxWidth: maxWidth + Breakpoints.gutter(context) * 2,
        ),
        padding: EdgeInsets.symmetric(horizontal: Breakpoints.gutter(context)),
        child: child,
      ),
    );
  }
}
