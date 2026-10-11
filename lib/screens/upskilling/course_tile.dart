import 'package:material_ui/material_ui.dart';

import '../../data/models/course.dart';
import '../../theme/colors.dart';
import '../../theme/motion.dart';
import '../../theme/radii.dart';
import '../../widgets/common/course_card.dart';

/// Tappable [CourseCard] that lifts a few pixels on hover.
///
/// CONTAINER (decoration): the AnimatedContainer adds the soft shadow that
/// grows as the card lifts.
class CourseTile extends StatefulWidget {
  const CourseTile({super.key, required this.course, required this.onTap});

  final Course course;
  final VoidCallback onTap;

  @override
  State<CourseTile> createState() => _CourseTileState();
}

class _CourseTileState extends State<CourseTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final lifted = _hover && !Motion.reduced(context);
    return Semantics(
      button: true,
      label: widget.course.title,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: Motion.medium,
            curve: Motion.ease,
            transform: Matrix4.translationValues(0, lifted ? -6 : 0, 0),
            decoration: BoxDecoration(
              borderRadius: Radii.cardAll,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowTint,
                  blurRadius: lifted ? 32 : 0,
                  offset: Offset(0, lifted ? 14 : 0),
                ),
              ],
            ),
            child: CourseCard(course: widget.course),
          ),
        ),
      ),
    );
  }
}
