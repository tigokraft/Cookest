import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/theme/shadcn_theme.dart';
import '../../../shared/components/shadcn_button.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final recipeDetailProvider = FutureProvider.family<Map<String, dynamic>, int>(
  (ref, id) async {
    final api = ref.read(apiClientProvider);
    return await api.get<Map<String, dynamic>>('/recipes/$id');
  },
);

// ── Page ──────────────────────────────────────────────────────────────────────

class RecipeDetailPage extends ConsumerWidget {
  final int id;
  const RecipeDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipeAsync = ref.watch(recipeDetailProvider(id));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: recipeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary)),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (recipe) => _RecipeDetailBody(recipe: recipe, ref: ref),
      ),
    );
  }
}

class _RecipeDetailBody extends StatelessWidget {
  final Map<String, dynamic> recipe;
  final WidgetRef ref;
  const _RecipeDetailBody({required this.recipe, required this.ref});

  @override
  Widget build(BuildContext context) {
    final ingredients = (recipe['ingredients'] as List? ?? []).cast<Map<String, dynamic>>();
    final steps = (recipe['steps'] as List? ?? []).cast<Map<String, dynamic>>();
    final nutrition = recipe['nutrition'] as Map<String, dynamic>?;

    return CustomScrollView(
      slivers: [
        // ── Hero image ────────────────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 260,
          pinned: true,
          backgroundColor: AppTheme.background,
          leading: GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)]),
              child: const Icon(LucideIcons.arrowLeft, size: 20),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: recipe['image_url'] != null
                ? Image.network(recipe['image_url'], fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: AppTheme.muted, child: const Icon(LucideIcons.chefHat, size: 60, color: AppTheme.mutedForeground)))
                : Container(color: AppTheme.muted, child: const Icon(LucideIcons.chefHat, size: 60, color: AppTheme.mutedForeground)),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + badges
                Row(children: [
                  if (recipe['cuisine'] != null) _SmallBadge(recipe['cuisine']),
                  if (recipe['difficulty'] != null) ...[const SizedBox(width: 6), _SmallBadge(recipe['difficulty'])],
                ]),
                const SizedBox(height: 10),
                Text(recipe['name'] ?? '', style: Theme.of(context).textTheme.headlineMedium)
                    .animate().fadeIn(),

                const SizedBox(height: 12),

                // Meta row
                Row(children: [
                  _MetaItem(icon: LucideIcons.clock, label: recipe['total_time_min'] != null ? '${recipe['total_time_min']} min' : '—'),
                  const SizedBox(width: 20),
                  _MetaItem(icon: LucideIcons.users, label: '${recipe['servings'] ?? '—'} servings'),
                  const SizedBox(width: 20),
                  _MetaItem(icon: LucideIcons.star, label: recipe['average_rating']?.toString() ?? '—'),
                ]).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 24),
                const Divider(color: AppTheme.border),
                const SizedBox(height: 20),

                // Nutrition card
                if (nutrition != null) ...[
                  Text('Nutrition per serving', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 12),
                  _NutritionRow(nutrition: nutrition),
                  const SizedBox(height: 24),
                  const Divider(color: AppTheme.border),
                  const SizedBox(height: 20),
                ],

                // Ingredients
                Text('Ingredients', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 12),
                ...ingredients.map((ing) => _IngredientRow(ingredient: ing)),

                const SizedBox(height: 24),
                const Divider(color: AppTheme.border),
                const SizedBox(height: 20),

                // Steps
                Text('Instructions', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 12),
                ...steps.asMap().entries.map((e) => _StepRow(step: e.key + 1, content: e.value['instruction'] ?? '')),

                const SizedBox(height: 32),

                // Actions
                Row(children: [
                  Expanded(
                    child: ShadcnButton(
                      text: 'Rate',
                      variant: ShadcnButtonVariant.outline,
                      icon: const Icon(LucideIcons.star, size: 16),
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ShadcnButton(
                      text: 'Favourite',
                      variant: ShadcnButtonVariant.outline,
                      icon: const Icon(LucideIcons.heart, size: 16),
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ShadcnButton(
                      text: "I Cooked It",
                      icon: const Icon(LucideIcons.chefHat, size: 16),
                      onPressed: () {},
                    ),
                  ),
                ]).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final String label;
  const _SmallBadge(this.label);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: AppTheme.muted, border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(4)),
    child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
  );
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 14, color: AppTheme.mutedForeground),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.mutedForeground)),
  ]);
}

class _NutritionRow extends StatelessWidget {
  final Map<String, dynamic> nutrition;
  const _NutritionRow({required this.nutrition});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppTheme.muted, borderRadius: BorderRadius.circular(AppTheme.radius), border: Border.all(color: AppTheme.border)),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      _NutritionItem(label: 'Calories', value: '${nutrition['calories'] ?? '—'}'),
      _NutritionItem(label: 'Protein', value: '${nutrition['protein_g'] ?? '—'}g'),
      _NutritionItem(label: 'Carbs', value: '${nutrition['carbs_g'] ?? '—'}g'),
      _NutritionItem(label: 'Fat', value: '${nutrition['fat_g'] ?? '—'}g'),
    ]),
  );
}

class _NutritionItem extends StatelessWidget {
  final String label, value;
  const _NutritionItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
    const SizedBox(height: 2),
    Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.mutedForeground)),
  ]);
}

class _IngredientRow extends StatelessWidget {
  final Map<String, dynamic> ingredient;
  const _IngredientRow({required this.ingredient});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle)),
      const SizedBox(width: 12),
      Text(ingredient['name'] ?? '', style: const TextStyle(fontSize: 14)),
      const Spacer(),
      Text(
        '${ingredient['quantity'] ?? ''} ${ingredient['unit'] ?? ''}'.trim(),
        style: const TextStyle(fontSize: 13, color: AppTheme.mutedForeground),
      ),
    ]),
  );
}

class _StepRow extends StatelessWidget {
  final int step;
  final String content;
  const _StepRow({required this.step, required this.content});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 26, height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
        child: Text('$step', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      const SizedBox(width: 12),
      Expanded(child: Text(content, style: const TextStyle(fontSize: 14, height: 1.5))),
    ]),
  );
}
