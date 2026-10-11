import 'package:material_ui/material_ui.dart';

import '../../../theme/colors.dart';
import '../../../widgets/common/reveal.dart';
import '../../../widgets/layout/section.dart';
import '../../../theme/typography.dart';

/// One centred statement: the message is the design here.
class Manifesto extends StatelessWidget {
  const Manifesto({super.key});

  @override
  Widget build(BuildContext context) {
    final style = AppText.h1(context).copyWith(height: 1.18);
    return Section(
      color: AppColors.grey50,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Reveal(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Change sticks when people '),
                  TextSpan(
                    text: 'feel',
                    style: style.copyWith(
                      fontStyle: FontStyle.italic,
                      color: AppColors.red,
                    ),
                  ),
                  const TextSpan(
                    text: ' it, practise it, and see it modelled by the people they follow.',
                  ),
                ],
              ),
              style: style,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
