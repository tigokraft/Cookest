import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/theme/shadcn_theme.dart';
import '../../../shared/components/shadcn_button.dart';
import '../../../shared/components/shadcn_input.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final inventoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiClientProvider);
  final data = await api.get<List<dynamic>>('/inventory');
  return data.cast<Map<String, dynamic>>();
});

final expiringProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiClientProvider);
  final data = await api.get<List<dynamic>>('/inventory/expiring');
  return data.cast<Map<String, dynamic>>();
});

// ── Page ──────────────────────────────────────────────────────────────────────

class PantryPage extends ConsumerStatefulWidget {
  const PantryPage({super.key});
  @override
  ConsumerState<PantryPage> createState() => _PantryPageState();
}

class _PantryPageState extends ConsumerState<PantryPage> {
  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _AddItemSheet(onAdded: () {
        ref.invalidate(inventoryProvider);
        ref.invalidate(expiringProvider);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(inventoryProvider);
    final expiringAsync = ref.watch(expiringProvider);

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
                  Text('Pantry', style: Theme.of(context).textTheme.headlineMedium).animate().fadeIn(),
                  ShadcnButton(
                    text: 'Add Item',
                    icon: const Icon(LucideIcons.plus, size: 16),
                    onPressed: _showAddSheet,
                  ).animate().fadeIn(delay: 100.ms),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: inventoryAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary)),
                error: (e, _) => Center(child: Text(e.toString(), style: const TextStyle(color: AppTheme.destructive))),
                data: (items) {
                  // Show expiry warning banner
                  final expiring = expiringAsync.maybeWhen(data: (d) => d, orElse: () => <Map<String, dynamic>>[]);

                  return CustomScrollView(
                    slivers: [
                      // Expiry warning
                      if (expiring.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                            child: _ExpiryBanner(items: expiring),
                          ).animate().fadeIn(),
                        ),

                      if (items.isEmpty)
                        SliverFillRemaining(
                          child: Center(
                            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              const Icon(LucideIcons.package, size: 48, color: AppTheme.mutedForeground),
                              const SizedBox(height: 12),
                              const Text('Your pantry is empty', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              const Text('Add ingredients to track your inventory.', style: TextStyle(color: AppTheme.mutedForeground)),
                              const SizedBox(height: 24),
                              ShadcnButton(text: 'Add First Item', icon: const Icon(LucideIcons.plus, size: 16), onPressed: _showAddSheet),
                            ]),
                          ),
                        )
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => _InventoryRow(
                              item: items[i],
                              onDelete: () async {
                                final api = ref.read(apiClientProvider);
                                await api.delete('/inventory/${items[i]['id']}');
                                ref.invalidate(inventoryProvider);
                              },
                            ).animate().fadeIn(delay: (i * 40).ms),
                            childCount: items.length,
                          ),
                        ),
                    ],
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

// ── Inventory row ─────────────────────────────────────────────────────────────

class _InventoryRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onDelete;
  const _InventoryRow({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final expiry = item['expiry_date'] as String?;
    final isExpiring = expiry != null &&
        DateTime.tryParse(expiry)?.isBefore(DateTime.now().add(const Duration(days: 5))) == true;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: isExpiring ? const Color(0xFFFEF3C7) : AppTheme.border),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        color: isExpiring ? const Color(0xFFFFFBEB) : AppTheme.background,
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(item['ingredient_name'] ?? item['custom_name'] ?? '—',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              if (isExpiring) ...[
                const SizedBox(width: 6),
                const Icon(LucideIcons.alertTriangle, size: 13, color: Color(0xFFD97706)),
              ],
            ]),
            const SizedBox(height: 4),
            Text('${item['quantity']} ${item['unit']}${expiry != null ? ' · Expires $expiry' : ''}',
                style: const TextStyle(fontSize: 12, color: AppTheme.mutedForeground)),
          ]),
        ),
        GestureDetector(
          onTap: onDelete,
          child: const Icon(LucideIcons.trash2, size: 18, color: AppTheme.mutedForeground),
        ),
      ]),
    );
  }
}

// ── Expiry banner ─────────────────────────────────────────────────────────────

class _ExpiryBanner extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _ExpiryBanner({required this.items});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFFBEB),
      border: Border.all(color: const Color(0xFFFDE68A)),
      borderRadius: BorderRadius.circular(AppTheme.radius),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(LucideIcons.alertTriangle, size: 16, color: Color(0xFFD97706)),
      const SizedBox(width: 10),
      Expanded(child: Text(
        '${items.length} item(s) expiring within 5 days: ${items.map((i) => i['ingredient_name'] ?? '').join(', ')}',
        style: const TextStyle(fontSize: 13),
      )),
    ]),
  );
}

// ── Add item bottom sheet ─────────────────────────────────────────────────────

class _AddItemSheet extends ConsumerStatefulWidget {
  final VoidCallback onAdded;
  const _AddItemSheet({required this.onAdded});
  @override
  ConsumerState<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends ConsumerState<_AddItemSheet> {
  final _nameCtrl = TextEditingController();
  final _qtCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose(); _qtCtrl.dispose(); _unitCtrl.dispose(); _expiryCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.isEmpty || _qtCtrl.text.isEmpty || _unitCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.post<void>('/inventory', data: {
        'ingredient_id': 1, // placeholder — will need ingredient search
        'custom_name': _nameCtrl.text.trim(),
        'quantity': double.parse(_qtCtrl.text.trim()),
        'unit': _unitCtrl.text.trim(),
        if (_expiryCtrl.text.isNotEmpty) 'expiry_date': _expiryCtrl.text.trim(),
      });
      widget.onAdded();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.destructive));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Add Pantry Item', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 20),
        ShadcnInput(label: 'Ingredient name', placeholder: 'e.g. Chicken breast', controller: _nameCtrl),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: ShadcnInput(label: 'Quantity', placeholder: '500', controller: _qtCtrl, keyboardType: TextInputType.number)),
          const SizedBox(width: 12),
          Expanded(child: ShadcnInput(label: 'Unit', placeholder: 'g / ml / pcs', controller: _unitCtrl)),
        ]),
        const SizedBox(height: 12),
        ShadcnInput(label: 'Expiry date (optional)', placeholder: 'YYYY-MM-DD', controller: _expiryCtrl),
        const SizedBox(height: 20),
        ShadcnButton(text: 'Add to Pantry', fullWidth: true, isLoading: _loading, onPressed: _submit),
      ]),
    );
  }
}
