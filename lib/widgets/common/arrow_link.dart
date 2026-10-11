import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';

import '../../theme/colors.dart';
import '../../theme/motion.dart';
import '../../theme/typography.dart';
import 'app_icon.dart';
import 'tappable.dart';

/// Inline text link with an arrow that nudges right on hover.
class ArrowLink extends StatefulWidget {
  const ArrowLink({
    super.key,
    required this.label,
    required this.onTap,
    this.color = AppColors.ink,
    this.hoverColor = AppColors.red,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color hoverColor;

  @override
  State<ArrowLink> createState() => _ArrowLinkState();
}

class _ArrowLinkState extends State<ArrowLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final color = _hover ? widget.hoverColor : widget.color;
    return Semantics(
      link: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: Tappable(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.label, style: AppText.label.copyWith(color: color)),
              AnimatedPadding(
                duration: Motion.fast,
                curve: Motion.ease,
                padding: EdgeInsets.only(left: _hover ? 10 : 6),
                child: AppIcon(
                  HugeIcons.strokeRoundedArrowRight01,
                  size: 18,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
