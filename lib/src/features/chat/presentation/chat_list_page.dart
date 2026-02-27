import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/theme/shadcn_theme.dart';
import '../../../shared/components/shadcn_button.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final chatSessionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final api = ref.read(apiClientProvider);
  final data = await api.get<List<dynamic>>('/chat/sessions');
  return data.cast<Map<String, dynamic>>();
});

// ── Page ──────────────────────────────────────────────────────────────────────

class ChatListPage extends ConsumerWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(chatSessionsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Cookest AI', style: Theme.of(context).textTheme.headlineMedium).animate().fadeIn(),
                    Text('Your kitchen assistant', style: Theme.of(context).textTheme.bodySmall).animate().fadeIn(delay: 100.ms),
                  ]),
                  ShadcnButton(
                    text: 'New Chat',
                    icon: const Icon(LucideIcons.plus, size: 16),
                    onPressed: () => context.push('/chat/new'),
                  ).animate().fadeIn(delay: 100.ms),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: sessionsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary)),
                error: (e, _) => Center(child: Text(e.toString())),
                data: (sessions) {
                  if (sessions.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(LucideIcons.messageCircle, size: 48, color: AppTheme.mutedForeground),
                          const SizedBox(height: 16),
                          const Text('No conversations yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          const Text('Ask about recipes, ingredient substitutions, cooking tips, and more.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.mutedForeground)),
                          const SizedBox(height: 24),
                          ShadcnButton(text: 'Start Chatting', icon: const Icon(LucideIcons.messageCircle, size: 16), onPressed: () => context.push('/chat/new')),
                        ]),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: sessions.length,
                    separatorBuilder: (context, index) => const Divider(color: AppTheme.border, height: 1),
                    itemBuilder: (context, i) => _SessionTile(
                      session: sessions[i],
                      onTap: () => context.push('/chat/${sessions[i]['id']}'),
                      onDelete: () async {
                        final api = ref.read(apiClientProvider);
                        await api.delete('/chat/sessions/${sessions[i]['id']}');
                        ref.invalidate(chatSessionsProvider);
                      },
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

class _SessionTile extends StatelessWidget {
  final Map<String, dynamic> session;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _SessionTile({required this.session, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 4),
    leading: Container(
      width: 40, height: 40,
      decoration: BoxDecoration(color: AppTheme.muted, shape: BoxShape.circle, border: Border.all(color: AppTheme.border)),
      child: const Icon(LucideIcons.messageCircle, size: 18, color: AppTheme.mutedForeground),
    ),
    title: Text(session['title'] ?? 'Chat', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
    subtitle: Text(session['updated_at'] ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.mutedForeground)),
    trailing: GestureDetector(onTap: onDelete, child: const Icon(LucideIcons.trash2, size: 16, color: AppTheme.mutedForeground)),
    onTap: onTap,
  );
}
