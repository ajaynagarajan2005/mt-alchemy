import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../data/mock/services.dart';
import '../../../data/models/course.dart';
import '../../../router/routes.dart';
import '../../../state/auth_store.dart';
import '../../../state/catalog_store.dart';
import '../../../theme/breakpoints.dart';
import '../../../theme/colors.dart';
import '../../../theme/radii.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../utils/validators.dart';
import '../../../widgets/common/alchemy_button.dart';
import '../../../widgets/common/app_icon.dart';
import '../../../widgets/common/arrow_link.dart';
import '../../../widgets/common/labeled_field.dart';
import '../portal_widgets.dart';

/// Create or edit a course and its lessons (video, PDF, reading, quiz).
/// [courseId] 'new' starts a blank course.
class CourseEditorScreen extends StatefulWidget {
  const CourseEditorScreen({super.key, required this.courseId});

  final String courseId;

  @override
  State<CourseEditorScreen> createState() => _CourseEditorScreenState();
}

class _ModuleDraft {
  _ModuleDraft(CourseModule m)
    : id = m.id,
      type = m.type,
      title = TextEditingController(text: m.title),
      minutes = TextEditingController(text: '${m.minutes}'),
      body = TextEditingController(text: m.body),
      media = TextEditingController(text: m.mediaUrl ?? ''),
      questions = [for (final q in m.quiz) _QuestionDraft(q)];

  final String id;
  LessonType type;
  final TextEditingController title, minutes, body, media;
  final List<_QuestionDraft> questions;

  CourseModule build() => CourseModule(
    id: id,
    title: title.text.trim(),
    minutes: int.tryParse(minutes.text) ?? 10,
    body: body.text.trim(),
    type: type,
    mediaUrl: media.text.trim().isEmpty ? null : media.text.trim(),
    quiz: type == LessonType.quiz
        ? [for (final q in questions) q.build()]
        : const [],
  );

  void dispose() {
    for (final c in [title, minutes, body, media]) {
      c.dispose();
    }
    for (final q in questions) {
      q.dispose();
    }
  }
}

class _QuestionDraft {
  _QuestionDraft(QuizQuestion q)
    : prompt = TextEditingController(text: q.prompt),
      options = TextEditingController(text: q.options.join('\n')),
      answer = q.answer;

  final TextEditingController prompt, options;
  int answer;

  List<String> get optionList => options.text
      .split('\n')
      .map((o) => o.trim())
      .where((o) => o.isNotEmpty)
      .toList();

  QuizQuestion build() => QuizQuestion(
    prompt: prompt.text.trim(),
    options: optionList,
    answer: answer.clamp(0, optionList.isEmpty ? 0 : optionList.length - 1),
  );

  void dispose() {
    prompt.dispose();
    options.dispose();
  }
}

class _CourseEditorScreenState extends State<CourseEditorScreen> {
  // FORM: one key validates the course and every lesson on save.
  final _formKey = GlobalKey<FormState>();
  final _id = TextEditingController();
  final _title = TextEditingController();
  final _price = TextEditingController();
  final _trainer = TextEditingController();
  final _summary = TextEditingController();
  final _outcomes = TextEditingController();
  String _service = services.first.slug;
  CourseLevel _level = CourseLevel.foundation;
  bool _published = false;
  final List<_ModuleDraft> _modules = [];
  bool _loaded = false;
  bool _saving = false;

  bool get _isNew => widget.courseId == 'new';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    final course = _isNew
        ? null
        : context.read<CatalogStore>().courseById(widget.courseId);
    if (!_isNew && course == null) return;
    _loaded = true;
    if (course == null) {
      _trainer.text = context.read<AuthStore>().currentUser?.name ?? '';
      _price.text = '149';
      _addModule(LessonType.video);
      return;
    }
    _id.text = course.id;
    _title.text = course.title;
    _price.text = course.price.toStringAsFixed(0);
    _trainer.text = course.trainer;
    _summary.text = course.summary;
    _outcomes.text = course.outcomes.join('\n');
    _service = course.serviceSlug;
    _level = course.level;
    _published = course.published;
    _modules.addAll(course.modules.map(_ModuleDraft.new));
  }

  @override
  void dispose() {
    for (final c in [_id, _title, _price, _trainer, _summary, _outcomes]) {
      c.dispose();
    }
    for (final m in _modules) {
      m.dispose();
    }
    super.dispose();
  }

  void _addModule(LessonType type) {
    final id = 'm-${DateTime.now().microsecondsSinceEpoch}';
    setState(
      () => _modules.add(
        _ModuleDraft(
          CourseModule(
            id: id,
            title: '',
            minutes: 10,
            body: '',
            type: type,
            quiz: type == LessonType.quiz
                ? const [
                    QuizQuestion(prompt: '', options: ['', ''], answer: 0),
                  ]
                : const [],
          ),
        ),
      ),
    );
  }

  String _slug(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_modules.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Add at least one lesson.')));
      return;
    }
    final id = _isNew
        ? _slug(_id.text.isEmpty ? _title.text : _id.text)
        : _id.text;
    final course = Course(
      id: id,
      title: _title.text.trim(),
      serviceSlug: _service,
      level: _level,
      price: double.tryParse(_price.text) ?? 0,
      summary: _summary.text.trim(),
      outcomes: _outcomes.text
          .split('\n')
          .map((o) => o.trim())
          .where((o) => o.isNotEmpty)
          .toList(),
      modules: [for (final m in _modules) m.build()],
      trainer: _trainer.text.trim(),
      published: _published,
    );
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final back =
        context.read<AuthStore>().currentUser?.role.name == 'superAdmin'
        ? Routes.superCourses
        : Routes.admin;
    setState(() => _saving = true);
    final error = await context.read<CatalogStore>().saveCourse(course);
    if (!mounted) return;
    setState(() => _saving = false);
    messenger.showSnackBar(
      SnackBar(content: Text(error ?? '${course.title} saved.')),
    );
    if (error == null) router.go(back);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const EmptyState(
        title: 'Course not found',
        message: 'It may have been deleted.',
      );
    }
    const gap = SizedBox(height: Space.md);
    final details = PortalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Course details', style: AppText.h3),
          const SizedBox(height: Space.lg),
          LabeledField(
            label: 'Title',
            controller: _title,
            validator: (v) => Validators.required(v, 'a course title'),
          ),
          if (_isNew) ...[
            gap,
            LabeledField(
              label: 'Web address (optional)',
              controller: _id,
              helper: 'Left blank, it is made from the title, e.g. "calm-under-pressure".',
            ),
          ],
          gap,
          LabeledDropdown<String>(
            label: 'Practice area',
            value: _service,
            items: [
              for (final s in services)
                DropdownMenuItem(value: s.slug, child: Text(s.title)),
            ],
            onChanged: (v) => setState(() => _service = v ?? _service),
          ),
          gap,
          LabeledDropdown<CourseLevel>(
            label: 'Level',
            value: _level,
            items: [
              for (final l in CourseLevel.values)
                DropdownMenuItem(value: l, child: Text(l.label)),
            ],
            onChanged: (v) => setState(() => _level = v ?? _level),
          ),
          gap,
          LabeledField(
            label: 'Price (GBP)',
            controller: _price,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            validator: (v) => double.tryParse(v ?? '') == null
                ? 'Enter a price, for example 149.'
                : null,
          ),
          gap,
          LabeledField(
            label: 'Trainer',
            controller: _trainer,
            validator: (v) => Validators.required(v, 'the trainer name'),
          ),
          gap,
          LabeledField(
            label: 'Summary',
            controller: _summary,
            maxLines: 3,
            minLines: 2,
            validator: (v) => Validators.required(v, 'a one-line summary'),
          ),
          gap,
          LabeledField(
            label: 'Outcomes (one per line)',
            controller: _outcomes,
            maxLines: 5,
            minLines: 3,
          ),
          gap,
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              value: _published,
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.red,
              title: Text('Published', style: AppText.label),
              subtitle: Text(
                'Published courses appear in the learning library.',
                style: AppText.small,
              ),
              onChanged: (v) => setState(() => _published = v),
            ),
          ),
        ],
      ),
    );

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ArrowLink(label: 'All courses', onTap: () => context.pop()),
          const SizedBox(height: Space.md),
          PortalHeader(
            title: _isNew ? 'New course' : 'Edit course',
            trailing: AlchemyButton(
              label: 'Save course',
              loading: _saving,
              onPressed: _save,
            ),
          ),
          details,
          const SizedBox(height: Space.xl),
          Text('Lessons', style: AppText.h3),
          const SizedBox(height: Space.md),
          for (var i = 0; i < _modules.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.md),
              child: _ModuleEditor(
                key: ObjectKey(_modules[i]),
                draft: _modules[i],
                number: i + 1,
                onChanged: () => setState(() {}),
                onRemove: () => setState(() => _modules.removeAt(i).dispose()),
                onUp: i == 0
                    ? null
                    : () => setState(
                        () => _modules.insert(i - 1, _modules.removeAt(i)),
                      ),
              ),
            ),
          Wrap(
            spacing: Space.sm,
            runSpacing: Space.sm,
            children: [
              for (final t in LessonType.values)
                AlchemyButton(
                  label: 'Add ${t.label.toLowerCase()}',
                  icon: HugeIcons.strokeRoundedAdd01,
                  variant: ButtonVariant.secondary,
                  onPressed: () => _addModule(t),
                ),
            ],
          ),
          const SizedBox(height: Space.xl),
          AlchemyButton(
            label: 'Save course',
            loading: _saving,
            expand: context.isCompact,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

class _ModuleEditor extends StatelessWidget {
  const _ModuleEditor({
    super.key,
    required this.draft,
    required this.number,
    required this.onChanged,
    required this.onRemove,
    required this.onUp,
  });

  final _ModuleDraft draft;
  final int number;
  final VoidCallback onChanged;
  final VoidCallback onRemove;
  final VoidCallback? onUp;

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: Space.md);
    return PortalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Lesson $number', style: AppText.eyebrow),
              const Spacer(),
              IconButton(
                tooltip: 'Move up',
                onPressed: onUp,
                icon: const Icon(Icons.arrow_upward, size: 20),
              ),
              IconButton(
                tooltip: 'Remove lesson',
                onPressed: onRemove,
                icon: AppIcon(
                  HugeIcons.strokeRoundedDelete02,
                  size: 20,
                  color: AppColors.grey600,
                ),
              ),
            ],
          ),
          Wrap(
            spacing: Space.xs,
            children: [
              for (final t in LessonType.values)
                ChoiceChip(
                  label: Text(t.label),
                  selected: draft.type == t,
                  selectedColor: AppColors.redSoft,
                  onSelected: (_) {
                    draft.type = t;
                    if (t == LessonType.quiz && draft.questions.isEmpty) {
                      draft.questions.add(
                        _QuestionDraft(
                          const QuizQuestion(
                            prompt: '',
                            options: ['', ''],
                            answer: 0,
                          ),
                        ),
                      );
                    }
                    onChanged();
                  },
                ),
            ],
          ),
          gap,
          LabeledField(
            label: 'Lesson title',
            controller: draft.title,
            validator: (v) => Validators.required(v, 'a lesson title'),
          ),
          gap,
          LabeledField(
            label: 'Minutes',
            controller: draft.minutes,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          gap,
          LabeledField(
            label: draft.type == LessonType.quiz
                ? 'Instructions'
                : 'Lesson text',
            controller: draft.body,
            maxLines: 5,
            minLines: 2,
            validator: (v) => Validators.required(v, 'some lesson text'),
          ),
          if (draft.type == LessonType.video ||
              draft.type == LessonType.pdf) ...[
            gap,
            LabeledField(
              label: draft.type == LessonType.video ? 'Video URL' : 'PDF URL',
              controller: draft.media,
              helper: draft.type == LessonType.video
                  ? 'An https link to an .mp4, or asset:assets/videos/brand_intro.mp4'
                  : 'An https link, or a site path such as /downloads/x.pdf',
              validator: (v) => Validators.required(v, 'a link'),
            ),
          ],
          if (draft.type == LessonType.quiz) ...[
            gap,
            for (var q = 0; q < draft.questions.length; q++)
              _QuestionEditor(
                key: ObjectKey(draft.questions[q]),
                draft: draft.questions[q],
                number: q + 1,
                onChanged: onChanged,
                onRemove: draft.questions.length == 1
                    ? null
                    : () {
                        draft.questions.removeAt(q).dispose();
                        onChanged();
                      },
              ),
            TextButton.icon(
              onPressed: () {
                draft.questions.add(
                  _QuestionDraft(
                    const QuizQuestion(
                      prompt: '',
                      options: ['', ''],
                      answer: 0,
                    ),
                  ),
                );
                onChanged();
              },
              icon: const Icon(Icons.add),
              label: const Text('Add question'),
              style: TextButton.styleFrom(foregroundColor: AppColors.red),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuestionEditor extends StatelessWidget {
  const _QuestionEditor({
    super.key,
    required this.draft,
    required this.number,
    required this.onChanged,
    required this.onRemove,
  });

  final _QuestionDraft draft;
  final int number;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final options = draft.optionList;
    // CONTAINER (grouping): tinted block per quiz question.
    return Container(
      margin: const EdgeInsets.only(bottom: Space.md),
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: Radii.inputAll,
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Question $number', style: AppText.label),
              const Spacer(),
              if (onRemove != null)
                IconButton(
                  tooltip: 'Remove question',
                  onPressed: onRemove,
                  icon: const Icon(Icons.close, size: 18),
                ),
            ],
          ),
          LabeledField(
            label: 'Question',
            controller: draft.prompt,
            validator: (v) => Validators.required(v, 'the question'),
          ),
          const SizedBox(height: Space.sm),
          LabeledField(
            label: 'Answers (one per line)',
            controller: draft.options,
            maxLines: 4,
            minLines: 2,
            onChanged: (_) => onChanged(),
            validator: (_) => draft.optionList.length < 2
                ? 'Give at least two answers.'
                : null,
          ),
          if (options.length >= 2) ...[
            const SizedBox(height: Space.sm),
            LabeledDropdown<int>(
              label: 'Correct answer',
              value: draft.answer.clamp(0, options.length - 1),
              items: [
                for (var i = 0; i < options.length; i++)
                  DropdownMenuItem(
                    value: i,
                    child: Text(options[i], overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) {
                draft.answer = v ?? 0;
                onChanged();
              },
            ),
          ],
        ],
      ),
    );
  }
}
