import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../shared/theme/shadcn_theme.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ────────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Good morning 👋',
                            style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 2),
                        Text('What are we cooking?',
                            style: Theme.of(context).textTheme.headlineSmall),
                      ],
                    ).animate().fadeIn().slideX(begin: -0.05),
                    GestureDetector(
                      onTap: () => context.push('/profile'),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.muted,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: const Icon(LucideIcons.user, size: 20, color: AppTheme.mutedForeground),
                      ),
                    ).animate().fadeIn(delay: 100.ms),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // ── Today's meals ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SectionHeader(
                  title: "Today's Meals",
                  action: 'See plan',
                  onAction: () => context.go('/meal-plan'),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: SizedBox(
                height: 160,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  scrollDirection: Axis.horizontal,
                  itemCount: 2,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, i) => _MealCard(
                    mealType: i == 0 ? 'Lunch' : 'Dinner',
                    recipeName: i == 0 ? 'Generate your plan' : 'to get meal ideas',
                    isEmpty: true,
                    onTap: () => context.go('/meal-plan'),
                  ).animate().fadeIn(delay: (200 + i * 100).ms).slideY(begin: 0.05),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // ── Quick actions ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionHeader(title: 'Quick Actions'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                            icon: LucideIcons.calendarDays,
                            label: 'Generate\nMeal Plan',
                            onTap: () => context.go('/meal-plan'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickActionCard(
                            icon: LucideIcons.plus,
                            label: 'Add to\nPantry',
                            onTap: () => context.go('/pantry'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickActionCard(
                            icon: LucideIcons.messageCircle,
                            label: 'Ask\nCookest AI',
                            onTap: () => context.go('/chat'),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 400.ms),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // ── Browse recipes ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SectionHeader(
                  title: 'Browse Recipes',
                  action: 'See all',
                  onAction: () => context.go('/recipes'),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                child: _EmptyStateCard(
                  icon: LucideIcons.bookOpen,
                  message: 'Recipes will appear here once the database is seeded',
                  action: 'Browse Recipes',
                  onAction: () => context.go('/recipes'),
                ),
              ).animate().fadeIn(delay: 500.ms),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const _SectionHeader({required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(action!, style: const TextStyle(fontSize: 12, color: AppTheme.mutedForeground, decoration: TextDecoration.underline)),
          ),
      ],
    );
  }
}

class _MealCard extends StatelessWidget {
  final String mealType;
  final String recipeName;
  final bool isEmpty;
  final VoidCallback onTap;

  const _MealCard({
    required this.mealType,
    required this.recipeName,
    required this.isEmpty,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isEmpty ? AppTheme.muted : AppTheme.primary,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(mealType, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isEmpty ? AppTheme.mutedForeground : Colors.white70)),
            Text(recipeName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isEmpty ? AppTheme.mutedForeground : Colors.white)),
            if (!isEmpty)
              const Row(children: [
                Icon(LucideIcons.checkCircle2, size: 14, color: Colors.white70),
                SizedBox(width: 4),
                Text('Mark done', style: TextStyle(fontSize: 11, color: Colors.white70)),
              ]),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(AppTheme.radius),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: AppTheme.primary),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, height: 1.3)),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final String action;
  final VoidCallback onAction;

  const _EmptyStateCard({required this.icon, required this.message, required this.action, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        color: AppTheme.muted,
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: AppTheme.mutedForeground),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppTheme.mutedForeground)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onAction,
            child: Text(action, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, decoration: TextDecoration.underline)),
          ),
        ],
      ),
    );
  }
}
