import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../data/models/article.dart';
import '../../state/auth_store.dart';
import '../../state/catalog_store.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/radii.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../utils/validators.dart';
import 'alchemy_button.dart';
import 'app_icon.dart';
import 'labeled_field.dart';

/// Star rating summary, recent reviews and a short review form, shared by
/// courses and products. Reviews live in the `reviews` collection.
class ReviewsSection extends StatelessWidget {
  const ReviewsSection({
    super.key,
    required this.targetId,
    required this.title,
    required this.canReview,
    required this.cannotReviewMessage,
  });

  final String targetId;
  final String title;
  final bool Function(BuildContext) canReview;
  final String cannotReviewMessage;

  @override
  Widget build(BuildContext context) {
    final catalog = context.read<CatalogStore>();
    return StreamBuilder<List<Review>>(
      stream: catalog.reviewsFor(targetId),
      builder: (context, snap) {
        final reviews = snap.data ?? const <Review>[];
        final avg = reviews.isEmpty
            ? 0.0
            : reviews.fold<int>(0, (s, r) => s + r.rating) / reviews.length;
        final plural = reviews.length == 1 ? '' : 's';
        final list = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppText.h2(context)),
            const SizedBox(height: Space.sm),
            if (reviews.isNotEmpty)
              Row(
                children: [
                  Stars(rating: avg.round()),
                  const SizedBox(width: Space.sm),
                  Text(
                    '${avg.toStringAsFixed(1)} from ${reviews.length} review$plural',
                    style: AppText.small,
                  ),
                ],
              )
            else
              Text('No reviews yet. Be the first.', style: AppText.bodyMuted),
            const SizedBox(height: Space.lg),
            for (final r in reviews.take(6)) _ReviewTile(review: r),
          ],
        );
        final form = _ReviewForm(
          targetId: targetId,
          canReview: canReview,
          cannotReviewMessage: cannotReviewMessage,
        );
        if (context.isExpanded) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 7, child: list),
              const SizedBox(width: Space.xxl),
              Expanded(flex: 4, child: form),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [list, const SizedBox(height: Space.lg), form],
        );
      },
    );
  }
}

class Stars extends StatelessWidget {
  const Stars({super.key, required this.rating, this.size = 18, this.onTap});

  final int rating;
  final double size;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$rating out of 5 stars',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 5; i++)
            GestureDetector(
              onTap: onTap == null ? null : () => onTap!(i),
              child: Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Icon(
                  i <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: size,
                  color: i <= rating ? AppColors.red : AppColors.grey400,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});
  final Review review;

  @override
  Widget build(BuildContext context) {
    // CONTAINER (grouping): hairline divider under each review.
    return Container(
      padding: const EdgeInsets.symmetric(vertical: Space.md),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Stars(rating: review.rating, size: 16),
              const SizedBox(width: Space.sm),
              Expanded(child: Text(review.userName, style: AppText.label)),
              if (review.createdAt != null)
                Text(
                  DateFormat('d MMM yyyy').format(review.createdAt!),
                  style: AppText.small,
                ),
            ],
          ),
          const SizedBox(height: Space.xs),
          Text(review.comment, style: AppText.body),
        ],
      ),
    );
  }
}

class _ReviewForm extends StatefulWidget {
  const _ReviewForm({
    required this.targetId,
    required this.canReview,
    required this.cannotReviewMessage,
  });

  final String targetId;
  final bool Function(BuildContext) canReview;
  final String cannotReviewMessage;

  @override
  State<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<_ReviewForm> {
  // FORM: review form with a required comment.
  final _formKey = GlobalKey<FormState>();
  final _comment = TextEditingController();
  int _rating = 5;
  bool _busy = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = context.read<AuthStore>().currentUser!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    final parts = user.name.trim().split(' ');
    final shortName = parts.length > 1
        ? '${parts.first} ${parts.last[0]}.'
        : parts.first;
    final error = await context.read<CatalogStore>().addReview(
      targetId: widget.targetId,
      userId: user.id,
      userName: shortName,
      rating: _rating,
      comment: _comment.text,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (error == null) {
      _comment.clear();
      _formKey.currentState!.reset();
    }
    messenger.showSnackBar(
      SnackBar(content: Text(error ?? 'Thank you for your review.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = context.watch<AuthStore>().isSignedIn;
    final allowed = signedIn && widget.canReview(context);
    // CONTAINER (card): quiet bordered panel for the review form.
    return Container(
      padding: const EdgeInsets.all(Space.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: Radii.cardAll,
        border: Border.all(color: AppColors.line),
      ),
      child: !allowed
          ? Row(
              children: [
                AppIcon(
                  HugeIcons.strokeRoundedStar,
                  size: 20,
                  color: AppColors.grey500,
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Text(
                    signedIn
                        ? widget.cannotReviewMessage
                        : 'Sign in to leave a review.',
                    style: AppText.small,
                  ),
                ),
              ],
            )
          : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Leave a review', style: AppText.h4),
                  const SizedBox(height: Space.sm),
                  Stars(
                    rating: _rating,
                    size: 28,
                    onTap: (r) => setState(() => _rating = r),
                  ),
                  const SizedBox(height: Space.md),
                  LabeledField(
                    label: 'Your review',
                    controller: _comment,
                    maxLines: 4,
                    minLines: 3,
                    validator: (v) => Validators.required(v, 'a short review'),
                  ),
                  const SizedBox(height: Space.md),
                  AlchemyButton(
                    label: 'Post review',
                    variant: ButtonVariant.secondary,
                    loading: _busy,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
    );
  }
}
