import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../router/routes.dart';
import '../../state/learning_store.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/radii.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/common/alchemy_button.dart';
import '../../widgets/common/app_icon.dart';
import '../../widgets/common/gradient_backdrop.dart';
import '../../widgets/layout/app_shell.dart';
import '../../widgets/layout/section.dart';
import '../portal/portal_widgets.dart' show formatDate;
import '../upskilling/notice_page.dart';

/// Public, shareable certificate (Journey A "Receive Certificate"). Anyone
/// with the link can verify it, because certificates are publicly readable.
class CertificateScreen extends StatelessWidget {
  const CertificateScreen({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Certificate?>(
      future: context.read<LearningStore>().verify(code),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(Space.section),
              child: CircularProgressIndicator(),
            ),
          );
        }
        final cert = snap.data;
        if (cert == null) {
          return NoticePage(
            title: 'Certificate not found',
            message:
                'We could not verify the code $code. Check the link and try again.',
            action: AlchemyButton(
              label: 'Browse courses',
              onPressed: () => context.go(Routes.upskilling),
            ),
          );
        }
        return PageScroll(
          underNav: true,
          children: [
            GradientBackdrop(
              child: Padding(
                padding: EdgeInsets.only(top: pageHeaderTop(context)),
                child: Section(
                  top: false,
                  child: Column(
                    children: [
                      Center(child: _CertificateCard(cert: cert)),
                      if (cert.review != null) ...[
                        const SizedBox(height: Space.xl),
                        Center(child: _ReviewPanel(review: cert.review!)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CertificateCard extends StatelessWidget {
  const _CertificateCard({required this.cert});
  final Certificate cert;

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 900),
      child: AspectRatio(
        aspectRatio: compact ? 0.8 : 1.414,
        // CONTAINER (decoration): the certificate sheet with a red border.
        child: Container(
          padding: EdgeInsets.all(compact ? Space.lg : Space.xxl),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: Radii.cardAll,
            border: Border.all(color: AppColors.red, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowTint,
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.line),
              borderRadius: Radii.inputAll,
            ),
            padding: EdgeInsets.all(compact ? Space.md : Space.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'MT ',
                        style: AppText.wordmark.copyWith(color: AppColors.red),
                      ),
                      TextSpan(text: 'Alchemy', style: AppText.wordmark),
                    ],
                  ),
                ),
                const Spacer(),
                Text('CERTIFICATE OF COMPLETION', style: AppText.eyebrow),
                const SizedBox(height: Space.md),
                Text('This certifies that', style: AppText.bodyMuted),
                const SizedBox(height: Space.sm),
                Text(
                  cert.userName,
                  textAlign: TextAlign.center,
                  style: AppText.display(context)
                      .copyWith(fontSize: compact ? 34 : 52),
                ),
                const SizedBox(height: Space.sm),
                Text('has completed', style: AppText.bodyMuted),
                const SizedBox(height: Space.xs),
                Text(
                  cert.courseTitle,
                  textAlign: TextAlign.center,
                  style: AppText.h3.copyWith(color: AppColors.red),
                ),
                const Spacer(),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: Space.xl,
                  runSpacing: Space.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _Meta(label: 'Issued', value: formatDate(cert.issuedAt)),
                    AppIcon(
                      HugeIcons.strokeRoundedAward01,
                      size: 44,
                      color: AppColors.red,
                    ),
                    _Meta(label: 'Verification code', value: cert.code),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The learning review written when the certificate was issued.
class _ReviewPanel extends StatelessWidget {
  const _ReviewPanel({required this.review});
  final String review;

  @override
  Widget build(BuildContext context) {
    // CONTAINER (card): the personal review under the certificate.
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 900),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Space.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: Radii.cardAll,
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('YOUR LEARNING REVIEW', style: AppText.eyebrow),
            const SizedBox(height: Space.sm),
            SelectableText(review, style: AppText.body.copyWith(height: 1.7)),
            const SizedBox(height: Space.sm),
            Text(
              'Written automatically from your quiz scores, attempts and pace.',
              style: AppText.small,
            ),
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppText.small),
        SelectableText(value, style: AppText.label),
      ],
    );
  }
}
