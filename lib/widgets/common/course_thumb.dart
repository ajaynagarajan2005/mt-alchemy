import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../state/catalog_store.dart';
import '../../theme/radii.dart';
import 'card_image.dart';

/// A course's photo at a fixed size, looked up from the live catalogue by id.
/// Used wherever a course appears in a progress list, so every row has an
/// image. Falls back to the red ink artwork if the course has no photo.
class CourseThumb extends StatelessWidget {
  const CourseThumb({
    super.key,
    required this.courseId,
    this.width = 64,
    this.height = 64,
    this.radius = Radii.smallAll,
  });

  final String courseId;
  final double width;
  final double height;
  final BorderRadius radius;

  /// Full-width banner variant for card headers.
  const CourseThumb.banner({
    super.key,
    required this.courseId,
    this.height = 110,
    this.radius = BorderRadius.zero,
  }) : width = double.infinity;

  @override
  Widget build(BuildContext context) {
    final course = context.watch<CatalogStore>().courseById(courseId);
    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: width,
        height: height,
        child: CardImage(
          seed: courseId,
          src: course?.imageUrl ?? bundledImage('course-$courseId'),
          tint: false,
        ),
      ),
    );
  }
}
