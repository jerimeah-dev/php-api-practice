import 'package:flutter/material.dart';
import 'package:frontend/models/post/post.model.dart';
import 'package:frontend/services/post/post.services.dart';

const _types = ['like', 'love', 'haha', 'wow', 'sad', 'angry'];
const _emojis = {
  'like': '👍',
  'love': '❤️',
  'haha': '😂',
  'wow': '😮',
  'sad': '😢',
  'angry': '😡',
};

// ─── Compact bar (for PostCard) ───────────────────────────────────────────────

/// Shows top-reaction summary + a "React" pill that opens an emoji picker.
class CompactReactionBar extends StatelessWidget {
  const CompactReactionBar({super.key, required this.post});
  final PostModel post;

  int get _total => post.reactionCounts.values.fold(0, (s, v) => s + v);

  @override
  Widget build(BuildContext context) {
    final sorted = _types
        .where((t) => (post.reactionCounts[t] ?? 0) > 0)
        .toList()
      ..sort((a, b) =>
          (post.reactionCounts[b] ?? 0).compareTo(post.reactionCounts[a] ?? 0));

    return Row(
      children: [
        if (_total > 0) ...[
          Text(
            sorted.take(2).map((t) => _emojis[t]!).join(''),
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 4),
          Text(
            '$_total',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const Spacer(),
        ] else
          const Spacer(),
        _ReactPill(post: post),
      ],
    );
  }
}

// ─── Full bar (for PostDetail) ────────────────────────────────────────────────

/// Shows all 6 reaction buttons with counts; selected one is highlighted.
class FullReactionBar extends StatelessWidget {
  const FullReactionBar({super.key, required this.post});
  final PostModel post;

  int get _total => post.reactionCounts.values.fold(0, (s, v) => s + v);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_total > 0) _buildSummary(),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _types
              .map((type) => _ReactionButton(
                    emoji: _emojis[type]!,
                    type: type,
                    count: post.reactionCounts[type] ?? 0,
                    isSelected: post.userReaction == type,
                    onTap: () => PostService.instance
                        .toggleReaction(postId: post.id, type: type),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildSummary() {
    final sorted = _types
        .where((t) => (post.reactionCounts[t] ?? 0) > 0)
        .toList()
      ..sort((a, b) =>
          (post.reactionCounts[b] ?? 0).compareTo(post.reactionCounts[a] ?? 0));

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          ...sorted
              .take(3)
              .map((t) => Text(_emojis[t]!, style: const TextStyle(fontSize: 16))),
          const SizedBox(width: 6),
          Text(
            '$_total',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─── Shared sub-widgets ───────────────────────────────────────────────────────

class _ReactPill extends StatelessWidget {
  const _ReactPill({required this.post});
  final PostModel post;

  @override
  Widget build(BuildContext context) {
    final hasReaction = post.userReaction != null;
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: hasReaction
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: hasReaction
              ? Border.all(color: Theme.of(context).colorScheme.primary)
              : null,
        ),
        child: Text(
          hasReaction
              ? '${_emojis[post.userReaction]!} ${_capitalize(post.userReaction!)}'
              : '👍 React',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: hasReaction
                ? Theme.of(context).colorScheme.primary
                : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('React',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _types
                  .map((type) => GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          PostService.instance
                              .toggleReaction(postId: post.id, type: type);
                        },
                        child: Column(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: post.userReaction == type
                                    ? Theme.of(ctx).colorScheme.primaryContainer
                                    : Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Text(_emojis[type]!,
                                  style: const TextStyle(fontSize: 26)),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _capitalize(type),
                              style: TextStyle(
                                fontSize: 11,
                                color: post.userReaction == type
                                    ? Theme.of(ctx).colorScheme.primary
                                    : Colors.grey[600],
                                fontWeight: post.userReaction == type
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _ReactionButton extends StatelessWidget {
  const _ReactionButton({
    required this.emoji,
    required this.type,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final String emoji;
  final String type;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary, width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            if (count > 0)
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey[600],
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
