import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../data/mock/courses.dart';
import '../../router/routes.dart';
import '../../state/auth_store.dart';
import '../../state/org_store.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/common/alchemy_button.dart';
import '../../widgets/common/arrow_link.dart';
import '../../widgets/common/labeled_field.dart';
import 'portal_widgets.dart';

/// Employer: pick a course, pick people, assign.
class AssignScreen extends StatefulWidget {
  const AssignScreen({super.key});

  @override
  State<AssignScreen> createState() => _AssignScreenState();
}

class _AssignScreenState extends State<AssignScreen> {
  // FORM: course dropdown plus employee checkboxes, validated on submit.
  final _formKey = GlobalKey<FormState>();
  String? _courseId;
  final Set<String> _selected = {};
  bool _showEmployeeError = false;
  bool _justAssigned = false;

  void _submit(String orgId) {
    final valid = _formKey.currentState?.validate() ?? false;
    setState(() => _showEmployeeError = _selected.isEmpty);
    if (!valid || _selected.isEmpty) return;

    final course = courseById(_courseId!)!;
    final added = context.read<OrgStore>().assign(
      orgId,
      course.id,
      _selected.toList(),
    );
    final message = added == 0
        ? 'Everyone selected already has this course.'
        : 'Assigned ${course.title} to $added ${added == 1 ? 'person' : 'people'}.';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
    setState(() {
      _selected.clear();
      _justAssigned = added > 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final org = context.watch<AuthStore>().currentOrganisation;
    final store = context.watch<OrgStore>();
    if (org == null) return const SizedBox.shrink();
    final employees = store.employees(org.id);
    final allSelected =
        employees.isNotEmpty && _selected.length == employees.length;

    if (employees.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PortalHeader(title: 'Assign courses'),
          EmptyState(
            title: 'Add employees first',
            message: 'You need at least one employee before you can assign a course.',
            actionLabel: 'Add employees',
            onAction: () => context.go(Routes.employerEmployees),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PortalHeader(
          title: 'Assign courses',
          subtitle: 'Choose a course, then choose who should take it.',
        ),
        Form(
          key: _formKey,
          child: PortalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LabeledDropdown<String>(
                  label: 'Course',
                  hint: 'Choose a course',
                  value: _courseId,
                  validator: (v) => v == null ? 'Choose a course.' : null,
                  items: [
                    for (final c in courses)
                      DropdownMenuItem(value: c.id, child: Text(c.title)),
                  ],
                  onChanged: (v) => setState(() => _courseId = v),
                ),
                const SizedBox(height: Space.lg),
                Row(
                  children: [
                    Expanded(child: Text('Employees', style: AppText.label)),
                    TextButton(
                      onPressed: () => setState(() {
                        if (allSelected) {
                          _selected.clear();
                        } else {
                          _selected
                            ..clear()
                            ..addAll(employees.map((e) => e.id));
                        }
                      }),
                      child: Text(allSelected ? 'Clear all' : 'Select all'),
                    ),
                  ],
                ),
                for (final e in employees)
                  CheckboxListTile(
                    value: _selected.contains(e.id),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.red,
                    title: Text(e.name, style: AppText.body),
                    subtitle: Text(
                      '${e.team}  |  ${e.email}',
                      style: AppText.small,
                    ),
                    onChanged: (v) => setState(() {
                      v == true ? _selected.add(e.id) : _selected.remove(e.id);
                    }),
                  ),
                if (_showEmployeeError && _selected.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: Space.xs),
                    child: Text(
                      'Choose at least one employee.',
                      style: AppText.small.copyWith(color: AppColors.error),
                    ),
                  ),
                const SizedBox(height: Space.lg),
                AlchemyButton(
                  label: _selected.isEmpty
                      ? 'Assign course'
                      : 'Assign to ${_selected.length}',
                  onPressed: () => _submit(org.id),
                ),
              ],
            ),
          ),
        ),
        if (_justAssigned) ...[
          const SizedBox(height: Space.lg),
          ArrowLink(
            label: 'View progress',
            onTap: () => context.go(Routes.employerProgress),
          ),
        ],
      ],
    );
  }
}
