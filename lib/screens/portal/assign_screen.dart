import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../router/routes.dart';
import '../../state/auth_store.dart';
import '../../state/cart_store.dart';
import '../../state/catalog_store.dart';
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
  bool _busy = false;
  String? _seatError;

  Future<void> _submit(String orgId) async {
    final valid = _formKey.currentState?.validate() ?? false;
    setState(() {
      _showEmployeeError = _selected.isEmpty;
      _seatError = null;
    });
    if (!valid || _selected.isEmpty) return;

    final course = context.read<CatalogStore>().courseById(_courseId!)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    final (added, error) = await context.read<OrgStore>().assign(
      orgId,
      course.id,
      _selected.toList(),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      setState(() => _seatError = error);
      return;
    }
    final message = added == 0
        ? 'Everyone selected already has this course.'
        : 'Assigned ${course.title} to $added ${added == 1 ? 'person' : 'people'}.';
    messenger.showSnackBar(SnackBar(content: Text(message)));
    setState(() {
      _selected.clear();
      _justAssigned = added > 0;
    });
  }

  void _buySeats() {
    final course = context.read<CatalogStore>().courseById(_courseId!)!;
    final needed = _selected.isEmpty ? 1 : _selected.length;
    context.read<CartStore>().addSeats(course, needed);
    context.go(Routes.checkout);
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
                    for (final c in context.watch<CatalogStore>().courses)
                      DropdownMenuItem(
                        value: c.id,
                        child: Text(
                          '${c.title}  (${org.seatsFor(c.id)} seats)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() {
                    _courseId = v;
                    _seatError = null;
                  }),
                ),
                if (_courseId != null) ...[
                  const SizedBox(height: Space.xs),
                  Text(
                    '${org.seatsFor(_courseId!)} unassigned seats for this course.',
                    style: AppText.small,
                  ),
                ],
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
                if (_seatError != null) ...[
                  const SizedBox(height: Space.md),
                  Text(
                    _seatError!,
                    style: AppText.small.copyWith(color: AppColors.error),
                  ),
                ],
                const SizedBox(height: Space.lg),
                Wrap(
                  spacing: Space.sm,
                  runSpacing: Space.sm,
                  children: [
                    AlchemyButton(
                      label: _selected.isEmpty
                          ? 'Assign course'
                          : 'Assign to ${_selected.length}',
                      loading: _busy,
                      onPressed: () => _submit(org.id),
                    ),
                    if (_courseId != null)
                      AlchemyButton(
                        label: 'Buy seats',
                        variant: ButtonVariant.secondary,
                        onPressed: _buySeats,
                      ),
                  ],
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
