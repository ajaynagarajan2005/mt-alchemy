import 'package:material_ui/material_ui.dart';

import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';

/// Required checkbox with its error text shown below.
///
/// FORM: a FormField of bool, so it validates with the rest of the Form.
class CheckField extends FormField<bool> {
  CheckField({
    super.key,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    String? requiredMessage,
  }) : super(
         initialValue: value,
         validator: requiredMessage == null
             ? null
             : (v) => (v ?? false) ? null : requiredMessage,
         builder: (state) {
           return Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               InkWell(
                 onTap: () {
                   state.didChange(!value);
                   onChanged(!value);
                 },
                 child: Row(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     SizedBox(
                       width: 24,
                       height: 24,
                       child: Checkbox(
                         value: value,
                         activeColor: AppColors.red,
                         side: BorderSide(
                           color: state.hasError
                               ? AppColors.error
                               : AppColors.grey500,
                           width: 1.5,
                         ),
                         onChanged: (v) {
                           state.didChange(v ?? false);
                           onChanged(v ?? false);
                         },
                       ),
                     ),
                     const SizedBox(width: Space.sm),
                     Expanded(child: Text(label, style: AppText.body)),
                   ],
                 ),
               ),
               if (state.hasError)
                 Padding(
                   padding: const EdgeInsets.only(top: Space.xs),
                   child: Text(
                     state.errorText!,
                     style: AppText.small.copyWith(color: AppColors.error),
                   ),
                 ),
             ],
           );
         },
       );
}
