import 'package:go_router/go_router.dart';

import '../../widgets/common/search_field.dart';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../state/catalog_store.dart';

import '../../data/models/product.dart';
import '../../router/routes.dart';
import '../../state/cart_store.dart';
import '../../theme/breakpoints.dart';
import '../../theme/colors.dart';
import '../../theme/radii.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/common/product_card.dart';
import '../../widgets/common/reveal.dart';
import 'shop_widgets.dart';

/// Adds [product] to the cart and confirms with a SnackBar offering the cart.
void addToCartWithFeedback(
  BuildContext context,
  Product product, {
  int quantity = 1,
}) {
  context.read<CartStore>().add(product, quantity: quantity);
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('Added ${product.name}'),
        action: SnackBarAction(
          label: 'View cart',
          onPressed: () => GoRouter.of(context).go(Routes.cart),
        ),
      ),
    );
}

/// Store: category filter chips and a responsive product grid.
class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  ProductCategory? _category;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final shown = [
      for (final p in context.watch<CatalogStore>().products)
        if ((_category == null || p.category == _category) &&
            matchesQuery(_query, [p.name, p.summary, p.description]))
          p,
    ];

    // Columns: 1 on compact, 2 on medium, 3 on expanded.
    final columns = switch (context.screenSize) {
      ScreenSize.compact => 1,
      ScreenSize.medium => 2,
      ScreenSize.expanded => 3,
    };

    return ShopPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Reveal(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Store', style: AppText.h1(context)),
                const SizedBox(height: Space.md),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Text(
                    'Cards, toolkits, books and workshop kits to carry the work into your everyday conversations.',
                    style: AppText.lead,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.xl),
          SearchField(
            hint: 'Search the store',
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: Space.md),
          // CONTAINER (grouping): keeps the filter chips together as one row.
          Container(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _category == null,
                  onTap: () => setState(() => _category = null),
                ),
                for (final c in ProductCategory.values)
                  _FilterChip(
                    label: c.label,
                    selected: _category == c,
                    onTap: () => setState(() => _category = c),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Space.xl),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.xl),
              child: Text(
                'Nothing in the store matches that search. Try fewer words.',
                style: AppText.bodyMuted,
              ),
            ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: Space.lg,
              crossAxisSpacing: Space.lg,
              mainAxisExtent: 440,
            ),
            itemCount: shown.length,
            itemBuilder: (context, i) {
              final p = shown[i];
              return ProductCard(
                product: p,
                onOpen: () => context.go(Routes.product(p.id)),
                onAdd: () => addToCartWithFeedback(context, p),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: Radii.pillAll,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: Radii.pillAll,
            color: selected ? AppColors.redSoft : AppColors.surface,
            border: Border.all(
              color: selected ? AppColors.red : AppColors.grey300,
            ),
          ),
          child: Text(
            label,
            style: AppText.label.copyWith(
              color: selected ? AppColors.redDeep : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
