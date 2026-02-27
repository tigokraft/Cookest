import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/api/api_client.dart';
import '../../../features/auth/data/auth_repository.dart';
import '../../../shared/theme/shadcn_theme.dart';
import '../../../shared/components/shadcn_button.dart';
import '../../../shared/components/shadcn_input.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final profileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  return await api.get<Map<String, dynamic>>('/me');
});

// ── Page ──────────────────────────────────────────────────────────────────────

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});
  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _nameCtrl = TextEditingController();
  final _householdCtrl = TextEditingController();
  bool _editing = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _householdCtrl.dispose();
    super.dispose();
  }

  void _startEdit(Map<String, dynamic> profile) {
    _nameCtrl.text = profile['name'] ?? '';
    _householdCtrl.text = '${profile['household_size'] ?? 1}';
    setState(() => _editing = true);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.put<void>('/me', data: {
        'name': _nameCtrl.text.trim(),
        'household_size': int.tryParse(_householdCtrl.text.trim()) ?? 1,
      });
      ref.invalidate(profileProvider);
      if (mounted) setState(() => _editing = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.destructive, behavior: SnackBarBehavior.floating));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary)),
          error: (e, _) => Center(child: Text(e.toString())),
          data: (profile) => CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Profile', style: Theme.of(context).textTheme.headlineMedium).animate().fadeIn(),
                          _editing
                              ? Row(children: [
                                  ShadcnButton(text: 'Cancel', variant: ShadcnButtonVariant.outline, onPressed: () => setState(() => _editing = false)),
                                  const SizedBox(width: 8),
                                  ShadcnButton(text: 'Save', isLoading: _saving, onPressed: _save),
                                ])
                              : ShadcnButton(text: 'Edit', variant: ShadcnButtonVariant.outline, icon: const Icon(LucideIcons.pencil, size: 14), onPressed: () => _startEdit(profile)),
                        ],
                      ).animate().fadeIn(),

                      const SizedBox(height: 28),

                      // Avatar
                      Center(
                        child: Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(color: AppTheme.muted, shape: BoxShape.circle, border: Border.all(color: AppTheme.border, width: 2)),
                          child: const Icon(LucideIcons.user, size: 36, color: AppTheme.mutedForeground),
                        ),
                      ).animate().fadeIn(delay: 100.ms),
                      const SizedBox(height: 8),
                      Center(child: Text(profile['email'] ?? '', style: const TextStyle(fontSize: 13, color: AppTheme.mutedForeground))).animate().fadeIn(delay: 150.ms),

                      const SizedBox(height: 28),
                      const Divider(color: AppTheme.border),
                      const SizedBox(height: 20),

                      // Fields
                      if (_editing) ...[
                        ShadcnInput(label: 'Display name', placeholder: 'Your name', controller: _nameCtrl),
                        const SizedBox(height: 16),
                        ShadcnInput(label: 'Household size', placeholder: '2', controller: _householdCtrl, keyboardType: TextInputType.number),
                      ] else ...[
                        _ProfileRow(label: 'Name', value: profile['name'] ?? '—'),
                        _ProfileRow(label: 'Household', value: '${profile['household_size'] ?? 1} people'),
                        _ProfileRow(label: 'Dietary', value: _parsedList(profile['dietary_restrictions'])),
                        _ProfileRow(label: 'Allergies', value: _parsedList(profile['allergies'])),
                        _ProfileRow(label: 'Member since', value: _formatDate(profile['created_at'])),
                      ],

                      const SizedBox(height: 28),
                      const Divider(color: AppTheme.border),
                      const SizedBox(height: 20),

                      // Quick links
                      _ProfileLink(icon: LucideIcons.history, label: 'Cooking History', onTap: () {}),
                      _ProfileLink(icon: LucideIcons.heart, label: 'Favourite Recipes', onTap: () {}),

                      const SizedBox(height: 20),
                      const Divider(color: AppTheme.border),
                      const SizedBox(height: 20),

                      // Logout
                      ShadcnButton(
                        text: 'Sign Out',
                        variant: ShadcnButtonVariant.outline,
                        fullWidth: true,
                        icon: const Icon(LucideIcons.logOut, size: 16),
                        onPressed: () async {
                          await ref.read(authNotifierProvider.notifier).logout();
                          if (context.mounted) context.go('/login');
                        },
                      ).animate().fadeIn(delay: 300.ms),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _parsedList(dynamic val) {
    if (val == null) return 'None';
    if (val is List) return val.isEmpty ? 'None' : val.join(', ');
    return val.toString();
  }

  String _formatDate(String? iso) {
    if (iso == null) return '—';
    try {
      final dt = DateTime.parse(iso);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) { return iso; }
  }
}

class _ProfileRow extends StatelessWidget {
  final String label, value;
  const _ProfileRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.mutedForeground)),
      Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
    ]),
  );
}

class _ProfileLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ProfileLink({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        Icon(icon, size: 18, color: AppTheme.mutedForeground),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const Spacer(),
        const Icon(LucideIcons.chevronRight, size: 16, color: AppTheme.mutedForeground),
      ]),
    ),
  );
}
