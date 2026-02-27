import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/theme/shadcn_theme.dart';
import '../../../shared/components/shadcn_input.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final recipesProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, query) async {
    final api = ref.read(apiClientProvider);
    final data = await api.get<List<dynamic>>(
      '/recipes',
      queryParams: query.isEmpty ? null : {'q': query},
    );
    return data.cast<Map<String, dynamic>>();
  },
);

// ── Page ──────────────────────────────────────────────────────────────────────

class RecipesPage extends ConsumerStatefulWidget {
  const RecipesPage({super.key});
  @override
  ConsumerState<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends ConsumerState<RecipesPage> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _cuisineFilter;

  final _cuisines = ['All', 'Italian', 'Asian', 'Mexican', 'Indian', 'American', 'Mediterranean'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipesAsync = ref.watch(recipesProvider(_query));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recipes', style: Theme.of(context).textTheme.headlineMedium)
                      .animate().fadeIn(),
                  const SizedBox(height: 16),
                  // Search bar
                  ShadcnInput(
                    placeholder: 'Search recipes...',
                    controller: _searchController,
                    prefix: const Icon(LucideIcons.search, size: 16, color: AppTheme.mutedForeground),
                    onChanged: (v) => setState(() => _query = v),
                  ).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 12),
                  // Filter chips
                  SizedBox(
                    height: 32,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _cuisines.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final c = _cuisines[i];
                        final selected = (i == 0 && _cuisineFilter == null) || _cuisineFilter == c;
                        return _FilterChip(
                          label: c,
                          selected: selected,
                          onTap: () => setState(() => _cuisineFilter = i == 0 ? null : c),
                        );
                      },
                    ),
                  ).animate().fadeIn(delay: 150.ms),
                ],
              ),
            ),

            // ── Recipe list ───────────────────────────────────────────────────
            Expanded(
              child: recipesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary)),
                error: (e, _) => _ErrorState(message: e.toString()),
                data: (recipes) {
                  if (recipes.isEmpty) {
                    return _EmptyState(query: _query);
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: recipes.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => RecipeCard(
                      recipe: recipes[i],
                      onTap: () => context.push('/recipes/${recipes[i]['id']}'),
                    ).animate().fadeIn(delay: (i * 50).ms),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Recipe card ───────────────────────────────────────────────────────────────

class RecipeCard extends StatelessWidget {
  final Map<String, dynamic> recipe;
  final VoidCallback onTap;

  const RecipeCard({super.key, required this.recipe, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(AppTheme.radius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (recipe['image_url'] != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radius)),
                child: Image.network(
                  recipe['image_url'],
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _ImagePlaceholder(height: 160),
                ),
              )
            else
              _ImagePlaceholder(height: 160),

            // Info
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (recipe['cuisine'] != null)
                        _Badge(label: recipe['cuisine']),
                      if (recipe['difficulty'] != null) ...[
                        const SizedBox(width: 6),
                        _Badge(label: recipe['difficulty'], outline: true),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recipe['name'] ?? '',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(LucideIcons.clock, size: 13, color: AppTheme.mutedForeground),
                    const SizedBox(width: 4),
                    Text(
                      recipe['total_time_min'] != null ? '${recipe['total_time_min']} min' : '—',
                      style: const TextStyle(fontSize: 12, color: AppTheme.mutedForeground),
                    ),
                    const SizedBox(width: 12),
                    const Icon(LucideIcons.star, size: 13, color: AppTheme.mutedForeground),
                    const SizedBox(width: 4),
                    Text(
                      recipe['average_rating']?.toString() ?? '—',
                      style: const TextStyle(fontSize: 12, color: AppTheme.mutedForeground),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.background,
          border: Border.all(color: selected ? AppTheme.primary : AppTheme.border),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : AppTheme.onBackground,
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final bool outline;
  const _Badge({required this.label, this.outline = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: outline ? AppTheme.background : AppTheme.muted,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final double height;
  const _ImagePlaceholder({required this.height});
  @override
  Widget build(BuildContext context) => Container(
    height: height,
    width: double.infinity,
    decoration: const BoxDecoration(
      color: AppTheme.muted,
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radius)),
    ),
    child: const Icon(LucideIcons.chefHat, size: 40, color: AppTheme.mutedForeground),
  );
}

class _EmptyState extends StatelessWidget {
  final String query;
  const _EmptyState({required this.query});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(LucideIcons.search, size: 40, color: AppTheme.mutedForeground),
        const SizedBox(height: 12),
        Text(
          query.isEmpty ? 'No recipes yet.\nSeed the database to get started.' : 'No results for "$query"',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.mutedForeground),
        ),
      ],
    ),
  );
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.alertCircle, size: 40, color: AppTheme.destructive),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.mutedForeground)),
        ],
      ),
    ),
  );
}
