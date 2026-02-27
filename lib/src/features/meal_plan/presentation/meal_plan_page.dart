import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/theme/shadcn_theme.dart';
import '../../../shared/components/shadcn_button.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final currentMealPlanProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final api = ref.read(apiClientProvider);
  final data = await api.get<Map<String, dynamic>>('/meal-plans/current');
  if (data.containsKey('message')) return null;
  return data;
});

final shoppingListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiClientProvider);
  final data = await api.get<Map<String, dynamic>>('/meal-plans/current/shopping-list');
  return (data['items'] as List? ?? []).cast<Map<String, dynamic>>();
});

// ── Page ──────────────────────────────────────────────────────────────────────

class MealPlanPage extends ConsumerStatefulWidget {
  const MealPlanPage({super.key});
  @override
  ConsumerState<MealPlanPage> createState() => _MealPlanPageState();
}

class _MealPlanPageState extends ConsumerState<MealPlanPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _generatePlan() async {
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final weekStart = DateFormat('yyyy-MM-dd').format(monday);

    try {
      final api = ref.read(apiClientProvider);
      await api.post<void>('/meal-plans/generate', data: {'week_start': weekStart});
      ref.invalidate(currentMealPlanProvider);
      ref.invalidate(shoppingListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Meal plan generated!'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppTheme.destructive,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final planAsync = ref.watch(currentMealPlanProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Meal Plan', style: Theme.of(context).textTheme.headlineMedium)
                      .animate().fadeIn(),
                  ShadcnButton(
                    text: 'Generate',
                    icon: const Icon(LucideIcons.sparkles, size: 14),
                    onPressed: _generatePlan,
                  ).animate().fadeIn(delay: 100.ms),
                ],
              ),
            ),

            // Tabs
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.mutedForeground,
                indicatorColor: AppTheme.primary,
                indicatorSize: TabBarIndicatorSize.label,
                tabs: const [Tab(text: 'This Week'), Tab(text: 'Shopping List')],
              ),
            ),

            const Divider(height: 1, color: AppTheme.border),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // ── Week view ──────────────────────────────────────────────
                  planAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary)),
                    error: (e, _) => Center(child: Text(e.toString())),
                    data: (plan) => plan == null
                        ? _EmptyPlan(onGenerate: _generatePlan)
                        : _WeekGrid(plan: plan, ref: ref),
                  ),

                  // ── Shopping list ──────────────────────────────────────────
                  Consumer(builder: (context, ref, child) {
                    final listAsync = ref.watch(shoppingListProvider);
                    return listAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary)),
                      error: (e, _) => Center(child: Text(e.toString())),
                      data: (items) => items.isEmpty
                          ? const Center(child: Text('No items needed — pantry is stocked!', style: TextStyle(color: AppTheme.mutedForeground)))
                          : ListView.separated(
                              padding: const EdgeInsets.all(20),
                              itemCount: items.length,
                              separatorBuilder: (context, index) => const Divider(color: AppTheme.border, height: 1),
                              itemBuilder: (context, i) => _ShoppingItem(item: items[i]),
                            ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Week grid ─────────────────────────────────────────────────────────────────

class _WeekGrid extends StatelessWidget {
  final Map<String, dynamic> plan;
  final WidgetRef ref;
  const _WeekGrid({required this.plan, required this.ref});

  @override
  Widget build(BuildContext context) {
    final slots = (plan['slots'] as List? ?? []).cast<Map<String, dynamic>>();
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: 7,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, dayIndex) {
        final daySlots = slots.where((s) => s['day_of_week'] == dayIndex).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(days[dayIndex], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.mutedForeground)),
            const SizedBox(height: 8),
            ...daySlots.map((slot) => _SlotCard(slot: slot, planId: plan['id'], ref: ref)),
            if (daySlots.isEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppTheme.muted, borderRadius: BorderRadius.circular(AppTheme.radius), border: Border.all(color: AppTheme.border)),
                child: const Text('No meal planned', style: TextStyle(fontSize: 13, color: AppTheme.mutedForeground)),
              ),
          ],
        );
      },
    );
  }
}

class _SlotCard extends StatelessWidget {
  final Map<String, dynamic> slot;
  final int planId;
  final WidgetRef ref;
  const _SlotCard({required this.slot, required this.planId, required this.ref});

  @override
  Widget build(BuildContext context) {
    final recipe = slot['recipe'] as Map<String, dynamic>?;
    final isDone = slot['is_completed'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDone ? AppTheme.muted : AppTheme.background,
        border: Border.all(color: isDone ? AppTheme.border : AppTheme.primary.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(slot['meal_type']?.toString().toUpperCase() ?? '', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.mutedForeground)),
            const SizedBox(height: 4),
            Text(recipe?['name'] ?? 'Unknown recipe', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            if (recipe?['total_time_min'] != null) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(LucideIcons.clock, size: 12, color: AppTheme.mutedForeground),
                const SizedBox(width: 4),
                Text('${recipe!['total_time_min']} min', style: const TextStyle(fontSize: 11, color: AppTheme.mutedForeground)),
              ]),
            ],
          ]),
        ),
        if (!isDone)
          GestureDetector(
            onTap: () async {
              final api = ref.read(apiClientProvider);
              await api.put<void>('/meal-plans/$planId/slots/${slot['id']}/complete');
              ref.invalidate(currentMealPlanProvider);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppTheme.muted, borderRadius: BorderRadius.circular(6)),
              child: const Icon(LucideIcons.check, size: 16, color: AppTheme.mutedForeground),
            ),
          ),
        if (isDone)
          const Icon(LucideIcons.checkCircle2, size: 20, color: AppTheme.primary),
      ]),
    );
  }
}

class _ShoppingItem extends StatelessWidget {
  final Map<String, dynamic> item;
  const _ShoppingItem({required this.item});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item['name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text('Need ${item['to_buy_grams']}g', style: const TextStyle(fontSize: 12, color: AppTheme.mutedForeground)),
        ]),
      ),
      if (item['in_inventory'] == true)
        const Text('Partially in pantry', style: TextStyle(fontSize: 11, color: AppTheme.mutedForeground)),
    ]),
  );
}

class _EmptyPlan extends StatelessWidget {
  final VoidCallback onGenerate;
  const _EmptyPlan({required this.onGenerate});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(LucideIcons.calendarDays, size: 48, color: AppTheme.mutedForeground),
        const SizedBox(height: 16),
        const Text('No meal plan this week', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Text('Generate an AI-powered weekly plan based on your pantry and preferences.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.mutedForeground)),
        const SizedBox(height: 24),
        ShadcnButton(text: 'Generate Plan', icon: const Icon(LucideIcons.sparkles, size: 16), onPressed: onGenerate),
      ]),
    ),
  );
}
