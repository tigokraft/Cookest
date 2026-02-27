import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/theme/shadcn_theme.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final chatMessagesProvider = FutureProvider.family<List<Map<String, dynamic>>, int>(
  (ref, sessionId) async {
    final api = ref.read(apiClientProvider);
    final data = await api.get<List<dynamic>>('/chat/sessions/$sessionId/messages');
    return data.cast<Map<String, dynamic>>();
  },
);

// ── Page ──────────────────────────────────────────────────────────────────────

class ChatPage extends ConsumerStatefulWidget {
  /// Pass 0 or -1 for a new session (no history)
  final int sessionId;
  const ChatPage({super.key, required this.sessionId});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _messages = <_Msg>[];
  int? _sessionId;
  bool _loading = false;

  bool get _isNew => widget.sessionId <= 0;

  @override
  void initState() {
    super.initState();
    _sessionId = _isNew ? null : widget.sessionId;
    if (!_isNew) _loadHistory();
  }

  Future<void> _loadHistory() async {
    final api = ref.read(apiClientProvider);
    final data = await api.get<List<dynamic>>('/chat/sessions/${widget.sessionId}/messages');
    final msgs = data.cast<Map<String, dynamic>>();
    setState(() {
      _messages.addAll(msgs.map((m) => _Msg(role: m['role'], content: m['content'])));
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _loading) return;

    _inputCtrl.clear();
    setState(() {
      _messages.add(_Msg(role: 'user', content: text));
      _loading = true;
    });
    _scrollToBottom();

    try {
      final api = ref.read(apiClientProvider);
      final resp = await api.post<Map<String, dynamic>>('/chat', data: {
        'message': text,
        if (_sessionId != null) 'session_id': _sessionId,
      });

      setState(() {
        _sessionId = resp['session_id'] as int?;
        _messages.add(_Msg(role: 'assistant', content: resp['reply'] ?? '…'));
        _loading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(_Msg(role: 'assistant', content: 'Error: ${e.toString()}'));
        _loading = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
            child: const Icon(LucideIcons.chefHat, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          const Text('Cookest AI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ]),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(color: AppTheme.border, height: 1)),
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _messages.isEmpty && !_loading
                ? _WelcomeState()
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_loading ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == _messages.length) return _TypingIndicator();
                      return _ChatBubble(msg: _messages[i])
                          .animate().fadeIn(delay: 50.ms).slideY(begin: 0.05);
                    },
                  ),
          ),

          // Input bar
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.border)),
              color: AppTheme.background,
            ),
            padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _inputCtrl,
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.newline,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Ask about recipes, substitutions, tips…',
                    hintStyle: const TextStyle(color: AppTheme.mutedForeground, fontSize: 14),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radius), borderSide: const BorderSide(color: AppTheme.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radius), borderSide: const BorderSide(color: AppTheme.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTheme.radius), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
                  ),
                  cursorColor: AppTheme.primary,
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _send,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: _loading ? AppTheme.muted : AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_loading ? LucideIcons.loader : LucideIcons.send, size: 18, color: _loading ? AppTheme.mutedForeground : Colors.white),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

// ── Message types ─────────────────────────────────────────────────────────────

class _Msg {
  final String role;
  final String content;
  _Msg({required this.role, required this.content});
}

class _ChatBubble extends StatelessWidget {
  final _Msg msg;
  const _ChatBubble({required this.msg});

  bool get isUser => msg.role == 'user';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
              child: const Icon(LucideIcons.chefHat, size: 14, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.primary : AppTheme.muted,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Text(
                msg.content,
                style: TextStyle(fontSize: 14, height: 1.4, color: isUser ? Colors.white : AppTheme.onBackground),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      Container(width: 28, height: 28, decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle), child: const Icon(LucideIcons.chefHat, size: 14, color: Colors.white)),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: AppTheme.muted, borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16), bottomRight: Radius.circular(16), bottomLeft: Radius.circular(4))),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) => Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) {
            final t = (_ctrl.value - i * 0.15).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  color: AppTheme.mutedForeground.withValues(alpha: 0.5 + 0.5 * (t < 0.5 ? t * 2 : 2 - t * 2)),
                  shape: BoxShape.circle,
                ),
              ),
            );
          })),
        ),
      ),
    ]),
  );
}

class _WelcomeState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
          child: const Icon(LucideIcons.chefHat, size: 32, color: Colors.white),
        ),
        const SizedBox(height: 16),
        const Text('How can I help?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Text('Ask me about recipes, what to cook with your pantry, meal planning, or cooking techniques.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.mutedForeground, fontSize: 13)),
        const SizedBox(height: 24),
        // Suggestion chips
        Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
          'What can I cook tonight?',
          'Suggest a healthy meal',
          'What\'s expiring soon?',
          'High protein dinner ideas',
        ].map((s) => _SuggestionChip(text: s)).toList()),
      ]),
    ),
  );
}

class _SuggestionChip extends StatelessWidget {
  final String text;
  const _SuggestionChip({required this.text});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: const TextStyle(fontSize: 12)),
  );
}
