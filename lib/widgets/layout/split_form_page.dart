import 'package:material_ui/material_ui.dart';

import '../../theme/breakpoints.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../common/glass_panel.dart';
import '../common/gradient_backdrop.dart';
import '../common/reveal.dart';
import 'app_shell.dart';
import 'section.dart';

/// Shared layout for Login, Register and Contact.
///
/// SCAFFOLD note: the page sits inside the AppShell Scaffold (AppBar nav).
/// CONTAINER (decoration): the form lives in a strong GlassPanel over a
/// GradientBackdrop. At 1024px and above the page splits into an intro column
/// and the form panel; below that it stacks into a single column.
class SplitFormPage extends StatelessWidget {
  const SplitFormPage({
    super.key,
    required this.headline,
    required this.copy,
    required this.panel,
    this.aside,
  });

  final String headline;
  final String copy;

  /// Content of the glass panel (usually a Form).
  final Widget panel;

  /// Extra content under the intro copy (contact rows, links).
  final Widget? aside;

  static const _panelMax = 560.0;

  @override
  Widget build(BuildContext context) {
    final split = context.isExpanded;

    final intro = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(headline, style: AppText.h1(context)),
        const SizedBox(height: Space.lg),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(copy, style: AppText.lead),
        ),
        if (aside != null) ...[const SizedBox(height: Space.xl), aside!],
      ],
    );

    final form = GlassPanel(
      strong: true,
      padding: EdgeInsets.all(context.isCompact ? Space.lg : Space.xl),
      child: panel,
    );

    return PageScroll(
      underNav: true,
      children: [
        GradientBackdrop(
          child: Padding(
            padding: EdgeInsets.only(top: pageHeaderTop(context)),
            child: Section(
              top: false,
              child: split
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Padding(
                            padding: const EdgeInsets.only(top: Space.lg),
                            child: Reveal(child: intro),
                          ),
                        ),
                        const SizedBox(width: Space.xxl),
                        Expanded(
                          flex: 6,
                          child: Align(
                            alignment: Alignment.topRight,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: _panelMax,
                              ),
                              child: Reveal(
                                delay: const Duration(milliseconds: 120),
                                child: form,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Reveal(child: intro),
                        const SizedBox(height: Space.xl),
                        Reveal(
                          delay: const Duration(milliseconds: 120),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: _panelMax,
                            ),
                            child: form,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
