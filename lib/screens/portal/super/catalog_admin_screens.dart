import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../data/models/article.dart';
import '../../../data/models/product.dart';
import '../../../router/routes.dart';
import '../../../state/catalog_store.dart';
import '../../../theme/breakpoints.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../../../theme/typography.dart';
import '../../../utils/validators.dart';
import '../../../widgets/common/alchemy_button.dart';
import '../../../widgets/common/app_icon.dart';
import '../../../widgets/common/arrow_link.dart';
import '../../../widgets/common/labeled_field.dart';
import '../../../widgets/common/product_card.dart' show gbpExact;
import '../portal_widgets.dart';

Future<bool> _confirmDelete(BuildContext context, String name) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text('Delete $name?', style: AppText.h3),
      content: Text('This cannot be undone.', style: AppText.bodyMuted),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return ok == true;
}

Widget _rowActions(
  BuildContext context, {
  required String name,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
}) => Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    IconButton(
      tooltip: 'Edit $name',
      onPressed: onEdit,
      icon: AppIcon(
        HugeIcons.strokeRoundedEdit02,
        size: 20,
        color: AppColors.ink,
      ),
    ),
    IconButton(
      tooltip: 'Delete $name',
      onPressed: onDelete,
      icon: AppIcon(
        HugeIcons.strokeRoundedDelete02,
        size: 20,
        color: AppColors.grey600,
      ),
    ),
  ],
);

/// CRUD for Products: list with stock, edit and delete.
class ProductsAdminScreen extends StatelessWidget {
  const ProductsAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final products = context.watch<CatalogStore>().products;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PortalHeader(
          title: 'Products',
          subtitle: 'Digital downloads and shipped products in the store.',
          trailing: AlchemyButton(
            label: 'New product',
            icon: HugeIcons.strokeRoundedAdd01,
            onPressed: () => context.go(Routes.editProduct('new')),
          ),
        ),
        for (final p in products)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: PortalCard(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.lg,
                vertical: Space.sm,
              ),
              child: Row(
                children: [
                  AppIcon(
                    p.isDigital
                        ? HugeIcons.strokeRoundedDownload01
                        : HugeIcons.strokeRoundedPackage,
                    size: 24,
                    color: AppColors.red,
                  ),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name, style: AppText.h4),
                        Text(
                          '${p.category.label}  |  ${gbpExact.format(p.price)}  |  '
                          '${p.isDigital ? 'Digital' : '${p.stock} in stock'}',
                          style: AppText.small.copyWith(
                            color: !p.isDigital && p.stock < 10
                                ? AppColors.error
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _rowActions(
                    context,
                    name: p.name,
                    onEdit: () => context.go(Routes.editProduct(p.id)),
                    onDelete: () async {
                      if (!await _confirmDelete(context, p.name)) return;
                      if (!context.mounted) return;
                      final messenger = ScaffoldMessenger.of(context);
                      final error = await context
                          .read<CatalogStore>()
                          .deleteProduct(p.id);
                      messenger.showSnackBar(
                        SnackBar(content: Text(error ?? '${p.name} deleted.')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class ProductEditorScreen extends StatefulWidget {
  const ProductEditorScreen({super.key, required this.productId});

  final String productId;

  @override
  State<ProductEditorScreen> createState() => _ProductEditorScreenState();
}

class _ProductEditorScreenState extends State<ProductEditorScreen> {
  // FORM: product create/edit with validation.
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _summary = TextEditingController();
  final _description = TextEditingController();
  final _details = TextEditingController();
  final _stock = TextEditingController(text: '50');
  final _file = TextEditingController();
  ProductCategory _category = ProductCategory.toolkit;
  ProductType _type = ProductType.physical;
  bool _loaded = false;
  bool _busy = false;

  bool get _isNew => widget.productId == 'new';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final p = _isNew
        ? null
        : context.read<CatalogStore>().productById(widget.productId);
    if (p == null) return;
    _name.text = p.name;
    _price.text = p.price.toStringAsFixed(2);
    _summary.text = p.summary;
    _description.text = p.description;
    _details.text = p.details.join('\n');
    _stock.text = '${p.stock}';
    _file.text = p.fileUrl ?? '';
    _category = p.category;
    _type = p.type;
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _price,
      _summary,
      _description,
      _details,
      _stock,
      _file,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final id = _isNew
        ? _name.text
              .toLowerCase()
              .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
              .replaceAll(RegExp(r'^-|-$'), '')
        : widget.productId;
    final product = Product(
      id: id,
      name: _name.text.trim(),
      category: _category,
      price: double.parse(_price.text),
      summary: _summary.text.trim(),
      description: _description.text.trim(),
      details: _details.text
          .split('\n')
          .map((d) => d.trim())
          .where((d) => d.isNotEmpty)
          .toList(),
      type: _type,
      stock: int.tryParse(_stock.text) ?? 0,
      fileUrl: _type == ProductType.digital ? _file.text.trim() : null,
    );
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() => _busy = true);
    final error = await context.read<CatalogStore>().saveProduct(product);
    if (!mounted) return;
    setState(() => _busy = false);
    messenger.showSnackBar(
      SnackBar(content: Text(error ?? '${product.name} saved.')),
    );
    if (error == null) router.go(Routes.superProducts);
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: Space.md);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ArrowLink(
              label: 'All products',
              onTap: () => context.go(Routes.superProducts),
            ),
            const SizedBox(height: Space.md),
            PortalHeader(title: _isNew ? 'New product' : 'Edit product'),
            PortalCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LabeledField(
                    label: 'Name',
                    controller: _name,
                    validator: (v) => Validators.required(v, 'a product name'),
                  ),
                  gap,
                  LabeledDropdown<ProductCategory>(
                    label: 'Category',
                    value: _category,
                    items: [
                      for (final c in ProductCategory.values)
                        DropdownMenuItem(value: c, child: Text(c.label)),
                    ],
                    onChanged: (v) =>
                        setState(() => _category = v ?? _category),
                  ),
                  gap,
                  Text('Type', style: AppText.label),
                  const SizedBox(height: Space.xs),
                  SegmentedButton<ProductType>(
                    segments: const [
                      ButtonSegment(
                        value: ProductType.physical,
                        label: Text('Shipped'),
                      ),
                      ButtonSegment(
                        value: ProductType.digital,
                        label: Text('Digital download'),
                      ),
                    ],
                    selected: {_type},
                    onSelectionChanged: (s) => setState(() => _type = s.first),
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
                        ? 'Enter a price, for example 24.00.'
                        : null,
                  ),
                  gap,
                  if (_type == ProductType.physical)
                    LabeledField(
                      label: 'Stock',
                      controller: _stock,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    )
                  else
                    LabeledField(
                      label: 'Download file URL',
                      controller: _file,
                      helper: 'An https link or a site path such as /downloads/x.pdf',
                      validator: (v) => Validators.required(v, 'a file link'),
                    ),
                  gap,
                  LabeledField(
                    label: 'Summary',
                    controller: _summary,
                    validator: (v) => Validators.required(v, 'a summary'),
                  ),
                  gap,
                  LabeledField(
                    label: 'Description',
                    controller: _description,
                    maxLines: 5,
                    minLines: 3,
                    validator: (v) => Validators.required(v, 'a description'),
                  ),
                  gap,
                  LabeledField(
                    label: 'Details (one per line)',
                    controller: _details,
                    maxLines: 4,
                    minLines: 2,
                  ),
                  const SizedBox(height: Space.lg),
                  AlchemyButton(
                    label: 'Save product',
                    loading: _busy,
                    expand: context.isCompact,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Articles (Insights) and impact stories: list, edit in a dialog, delete.
class ContentAdminScreen extends StatelessWidget {
  const ContentAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogStore>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PortalHeader(
          title: 'Content',
          subtitle:
              'Insights articles and the impact stories on the home page.',
        ),
        Row(
          children: [
            Expanded(child: Text('Articles', style: AppText.h3)),
            AlchemyButton(
              label: 'New article',
              icon: HugeIcons.strokeRoundedAdd01,
              variant: ButtonVariant.secondary,
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const _ArticleDialog(),
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.md),
        for (final a in catalog.articles)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: PortalCard(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.lg,
                vertical: Space.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.title, style: AppText.h4),
                        Text(
                          '${a.category}  |  ${formatDate(a.published)}  |  ${a.readMinutes} min',
                          style: AppText.small,
                        ),
                      ],
                    ),
                  ),
                  _rowActions(
                    context,
                    name: a.title,
                    onEdit: () => showDialog<void>(
                      context: context,
                      builder: (_) => _ArticleDialog(article: a),
                    ),
                    onDelete: () async {
                      if (!await _confirmDelete(context, a.title)) return;
                      if (context.mounted) {
                        await context.read<CatalogStore>().deleteArticle(
                          a.slug,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: Space.xl),
        Row(
          children: [
            Expanded(child: Text('Impact stories', style: AppText.h3)),
            AlchemyButton(
              label: 'New story',
              icon: HugeIcons.strokeRoundedAdd01,
              variant: ButtonVariant.secondary,
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const _StoryDialog(),
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.md),
        for (final s in catalog.stories)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.sm),
            child: PortalCard(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.lg,
                vertical: Space.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('“${s.quote}”', style: AppText.body),
                        Text(
                          '${s.name}, ${s.role}${s.metric == null ? '' : '  |  ${s.metric}'}',
                          style: AppText.small,
                        ),
                      ],
                    ),
                  ),
                  _rowActions(
                    context,
                    name: s.name,
                    onEdit: () => showDialog<void>(
                      context: context,
                      builder: (_) => _StoryDialog(story: s),
                    ),
                    onDelete: () async {
                      if (s.id.isEmpty) return;
                      if (!await _confirmDelete(context, 'this story')) return;
                      if (context.mounted) {
                        await context.read<CatalogStore>().deleteStory(s.id);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ArticleDialog extends StatefulWidget {
  const _ArticleDialog({this.article});
  final Article? article;

  @override
  State<_ArticleDialog> createState() => _ArticleDialogState();
}

class _ArticleDialogState extends State<_ArticleDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.article?.title);
  late final _category = TextEditingController(
    text: widget.article?.category ?? 'Leadership',
  );
  late final _excerpt = TextEditingController(text: widget.article?.excerpt);
  late final _body = TextEditingController(
    text: widget.article?.body.join('\n\n'),
  );
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_title, _category, _excerpt, _body]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final paragraphs = _body.text
        .split(RegExp(r'\n\s*\n'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    final words = paragraphs.join(' ').split(RegExp(r'\s+')).length;
    final a = Article(
      slug:
          widget.article?.slug ??
          _title.text
              .toLowerCase()
              .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
              .replaceAll(RegExp(r'^-|-$'), ''),
      title: _title.text.trim(),
      category: _category.text.trim(),
      readMinutes: (words / 200).ceil().clamp(1, 60),
      published: widget.article?.published ?? DateTime.now(),
      excerpt: _excerpt.text.trim(),
      body: paragraphs,
    );
    setState(() => _busy = true);
    final error = await context.read<CatalogStore>().saveArticle(a);
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context);
    } else {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: Space.md);
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        widget.article == null ? 'New article' : 'Edit article',
        style: AppText.h3,
      ),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LabeledField(
                  label: 'Title',
                  controller: _title,
                  validator: (v) => Validators.required(v, 'a title'),
                ),
                gap,
                LabeledField(label: 'Category', controller: _category),
                gap,
                LabeledField(
                  label: 'Excerpt',
                  controller: _excerpt,
                  maxLines: 2,
                  validator: (v) => Validators.required(v, 'an excerpt'),
                ),
                gap,
                LabeledField(
                  label: 'Body (blank line between paragraphs)',
                  controller: _body,
                  maxLines: 10,
                  minLines: 6,
                  validator: (v) => Validators.required(v, 'the article text'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        AlchemyButton(label: 'Save', loading: _busy, onPressed: _save),
      ],
    );
  }
}

class _StoryDialog extends StatefulWidget {
  const _StoryDialog({this.story});
  final Testimonial? story;

  @override
  State<_StoryDialog> createState() => _StoryDialogState();
}

class _StoryDialogState extends State<_StoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _quote = TextEditingController(text: widget.story?.quote);
  late final _name = TextEditingController(text: widget.story?.name);
  late final _role = TextEditingController(text: widget.story?.role);
  late final _metric = TextEditingController(text: widget.story?.metric);
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_quote, _name, _role, _metric]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final error = await context.read<CatalogStore>().saveStory(
      Testimonial(
        id: widget.story?.id ?? '',
        quote: _quote.text.trim(),
        name: _name.text.trim(),
        role: _role.text.trim(),
        metric: _metric.text.trim().isEmpty ? null : _metric.text.trim(),
      ),
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context);
    } else {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: Space.md);
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        widget.story == null ? 'New impact story' : 'Edit impact story',
        style: AppText.h3,
      ),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LabeledField(
                label: 'Quote',
                controller: _quote,
                maxLines: 4,
                minLines: 2,
                validator: (v) => Validators.required(v, 'the quote'),
              ),
              gap,
              LabeledField(
                label: 'Name',
                controller: _name,
                validator: (v) => Validators.required(v, 'a name'),
              ),
              gap,
              LabeledField(
                label: 'Role and organisation',
                controller: _role,
                validator: (v) => Validators.required(v, 'a role'),
              ),
              gap,
              LabeledField(
                label: 'Headline result (optional)',
                controller: _metric,
                hint: 'e.g. Team engagement up 24 points',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        AlchemyButton(label: 'Save', loading: _busy, onPressed: _save),
      ],
    );
  }
}
