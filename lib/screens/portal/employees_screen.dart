import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../data/models/people.dart';
import '../../router/routes.dart';
import '../../state/auth_store.dart';
import '../../state/org_store.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../utils/validators.dart';
import '../../widgets/common/alchemy_button.dart';
import '../../widgets/common/app_icon.dart';
import '../../widgets/common/arrow_link.dart';
import '../../widgets/common/labeled_field.dart';
import 'portal_widgets.dart';

/// Employer: add employees and manage the list.
class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  // FORM: the add-employee form; every field is required and the email is
  // checked for format and for duplicates within the organisation.
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _team = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _team.dispose();
    super.dispose();
  }

  void _submit(String orgId) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final name = _name.text.trim();
    context.read<OrgStore>().addEmployee(
      orgId,
      name: name,
      email: _email.text,
      team: _team.text,
    );
    _formKey.currentState?.reset();
    _name.clear();
    _email.clear();
    _team.clear();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$name has been added.')));
  }

  Future<void> _confirmRemove(String orgId, Employee e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Remove ${e.name}?', style: AppText.h3),
        content: Text(
          'They will lose any courses assigned to them. This cannot be undone.',
          style: AppText.bodyMuted,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      context.read<OrgStore>().removeEmployee(orgId, e.id);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${e.name} has been removed.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final org = context.watch<AuthStore>().currentOrganisation;
    final store = context.watch<OrgStore>();
    if (org == null) return const SizedBox.shrink();
    final employees = store.employees(org.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PortalHeader(
          title: 'Employees',
          subtitle: 'Add the people you want to develop, then assign courses.',
        ),
        PortalCard(child: _buildForm(org.id, store)),
        const SizedBox(height: Space.xl),
        Text('Your people (${employees.length})', style: AppText.h3),
        const SizedBox(height: Space.md),
        if (employees.isEmpty)
          const EmptyState(
            title: 'No employees yet',
            message: 'Use the form above to add your first employee.',
          )
        else if (context.isCompact)
          Column(
            children: [
              for (final e in employees)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.sm),
                  child: _EmployeeCard(
                    employee: e,
                    courses: store.courseCountFor(org.id, e.id),
                    onRemove: () => _confirmRemove(org.id, e),
                  ),
                ),
            ],
          )
        else
          _EmployeeTable(
            employees: employees,
            courseCount: (e) => store.courseCountFor(org.id, e.id),
            onRemove: (e) => _confirmRemove(org.id, e),
          ),
        if (employees.isNotEmpty) ...[
          const SizedBox(height: Space.lg),
          ArrowLink(
            label: 'Assign a course',
            onTap: () => context.go(Routes.employerAssign),
          ),
        ],
      ],
    );
  }

  Widget _buildForm(String orgId, OrgStore store) {
    final fields = [
      LabeledField(
        label: 'Full name',
        controller: _name,
        textInputAction: TextInputAction.next,
        validator: (v) => Validators.required(v, 'their full name'),
      ),
      LabeledField(
        label: 'Work email',
        controller: _email,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        validator: (v) {
          final base = Validators.email(v);
          if (base != null) return base;
          if (store.emailInUse(orgId, v!)) {
            return 'That email is already in use.';
          }
          return null;
        },
      ),
      LabeledField(
        label: 'Team',
        controller: _team,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(orgId),
        validator: (v) => Validators.required(v, 'their team'),
      ),
    ];

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add an employee', style: AppText.h3),
          const SizedBox(height: Space.md),
          if (context.isCompact)
            Column(
              children: [
                for (final f in fields) ...[
                  f,
                  const SizedBox(height: Space.md),
                ],
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < fields.length; i++) ...[
                  if (i > 0) const SizedBox(width: Space.md),
                  Expanded(child: fields[i]),
                ],
              ],
            ),
          if (!context.isCompact) const SizedBox(height: Space.md),
          AlchemyButton(
            label: 'Add employee',
            expand: context.isCompact,
            onPressed: () => _submit(orgId),
          ),
        ],
      ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  const _EmployeeCard({
    required this.employee,
    required this.courses,
    required this.onRemove,
  });

  final Employee employee;
  final int courses;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return PortalCard(
      padding: const EdgeInsets.all(Space.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(employee.name, style: AppText.label),
                const SizedBox(height: 2),
                Text(employee.email, style: AppText.small),
                const SizedBox(height: 2),
                Text(
                  '${employee.team}  |  $courses ${courses == 1 ? 'course' : 'courses'}',
                  style: AppText.small,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove ${employee.name}',
            onPressed: onRemove,
            icon: const AppIcon(HugeIcons.strokeRoundedDelete02, size: 22),
          ),
        ],
      ),
    );
  }
}

class _EmployeeTable extends StatelessWidget {
  const _EmployeeTable({
    required this.employees,
    required this.courseCount,
    required this.onRemove,
  });

  final List<Employee> employees;
  final int Function(Employee) courseCount;
  final ValueChanged<Employee> onRemove;

  @override
  Widget build(BuildContext context) {
    Widget row(List<Widget> cells, {Widget? action}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.sm),
      child: Row(
        children: [
          Expanded(flex: 3, child: cells[0]),
          Expanded(flex: 4, child: cells[1]),
          Expanded(flex: 2, child: cells[2]),
          Expanded(flex: 2, child: cells[3]),
          SizedBox(width: 48, child: action),
        ],
      ),
    );

    return PortalCard(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.lg,
        vertical: Space.xs,
      ),
      child: Column(
        children: [
          row([
            Text('Name', style: AppText.small),
            Text('Work email', style: AppText.small),
            Text('Team', style: AppText.small),
            Text('Courses', style: AppText.small),
          ]),
          const Divider(),
          for (final e in employees) ...[
            row(
              [
                Text(e.name, style: AppText.label),
                Text(e.email, style: AppText.body),
                Text(e.team, style: AppText.body),
                Text('${courseCount(e)}', style: AppText.body),
              ],
              action: IconButton(
                tooltip: 'Remove ${e.name}',
                onPressed: () => onRemove(e),
                icon: const AppIcon(HugeIcons.strokeRoundedDelete02, size: 22),
              ),
            ),
            if (e != employees.last) const Divider(),
          ],
        ],
      ),
    );
  }
}
