import 'package:flutter/material.dart';
import 'package:frontend/services/reaction/reaction.services.dart';

const _fbBlue = Color(0xFF1877F2);
const _fbGray = Color(0xFF65676B);

const _types = ['Like', 'Love', 'Haha', 'Wow', 'Sad', 'Angry'];
const _emojis = {
  'Like':  '👍',
  'Love':  '❤️',
  'Haha':  '😂',
  'Wow':   '😮',
  'Sad':   '😢',
  'Angry': '😡',
};

// ─── Compact bar (comments + replies only) ────────────────────────────────────

class CompactReactionBar extends StatelessWidget {
  const CompactReactionBar({
    super.key,
    required this.targetType,
    required this.targetId,
    required this.reactionCounts,
    required this.userReaction,
  });

  final String targetType;
  final String targetId;
  final Map<String, int> reactionCounts;
  final String? userReaction;

  int get _total => reactionCounts.values.fold(0, (s, v) => s + v);

  @override
  Widget build(BuildContext context) {
    final hasReaction = userReaction != null;
    final sorted = _types.where((t) => (reactionCounts[t] ?? 0) > 0).toList()
      ..sort((a, b) => (reactionCounts[b] ?? 0).compareTo(reactionCounts[a] ?? 0));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_total > 0) ...[
          Text(
            sorted.take(2).map((t) => _emojis[t]!).join(''),
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 3),
          Text('$_total', style: const TextStyle(fontSize: 12, color: _fbGray)),
          const SizedBox(width: 10),
        ],
        GestureDetector(
          onTap: () => ReactionService.instance.toggleReaction(
            targetType: targetType,
            targetId: targetId,
            type: userReaction ?? 'Like',
          ),
          onLongPress: () => _showPicker(context),
          child: Text(
            hasReaction ? '${_emojis[userReaction!]!} $userReaction' : 'Like',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: hasReaction ? _fbBlue : _fbGray,
            ),
          ),
        ),
      ],
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => _ReactionPicker(
        userReaction: userReaction,
        onSelect: (type) {
          Navigator.pop(ctx);
          ReactionService.instance.toggleReaction(
            targetType: targetType,
            targetId: targetId,
            type: type,
          );
        },
      ),
    );
  }
}

// ─── Full action bar (posts — feed cards + post detail) ───────────────────────

class FullReactionBar extends StatelessWidget {
  const FullReactionBar({
    super.key,
    required this.targetType,
    required this.targetId,
    required this.reactionCounts,
    required this.userReaction,
    this.onComment,
  });

  final String targetType;
  final String targetId;
  final Map<String, int> reactionCounts;
  final String? userReaction;
  final VoidCallback? onComment;

  @override
  Widget build(BuildContext context) {
    final hasReaction = userReaction != null;

    return SizedBox(
      height: 44,
      child: Row(
        children: [
          Expanded(
            child: _PostActionBtn(
              icon: hasReaction
                  ? Text(_emojis[userReaction!]!, style: const TextStyle(fontSize: 18))
                  : const Icon(Icons.thumb_up_outlined, size: 20, color: _fbGray),
              label: userReaction ?? 'Like',
              isActive: hasReaction,
              onTap: () => ReactionService.instance.toggleReaction(
                targetType: targetType,
                targetId: targetId,
                type: userReaction ?? 'Like',
              ),
              onLongPress: () => _showPicker(context),
            ),
          ),
          _vDivider(),
          Expanded(
            child: _PostActionBtn(
              icon: const Icon(Icons.chat_bubble_outline, size: 20, color: _fbGray),
              label: 'Comment',
              isActive: false,
              onTap: onComment ?? () {},
            ),
          ),
          _vDivider(),
          Expanded(
            child: _PostActionBtn(
              icon: const Icon(Icons.share_outlined, size: 20, color: _fbGray),
              label: 'Share',
              isActive: false,
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _vDivider() =>
      Container(width: 1, height: 44, color: const Color(0xFFE4E6EB));

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => _ReactionPicker(
        userReaction: userReaction,
        onSelect: (type) {
          Navigator.pop(ctx);
          ReactionService.instance.toggleReaction(
            targetType: targetType,
            targetId: targetId,
            type: type,
          );
        },
      ),
    );
  }
}

// ─── Shared sub-widgets ───────────────────────────────────────────────────────

class _PostActionBtn extends StatelessWidget {
  const _PostActionBtn({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.onLongPress,
  });

  final Widget icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        color: Colors.transparent,
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isActive ? _fbBlue : _fbGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReactionPicker extends StatelessWidget {
  const _ReactionPicker({required this.userReaction, required this.onSelect});

  final String? userReaction;
  final void Function(String type) onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _types.map((type) {
              final isSelected = userReaction == type;
              return GestureDetector(
                onTap: () => onSelect(type),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _fbBlue.withValues(alpha: 0.12)
                            : Colors.grey.shade100,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: _fbBlue, width: 2)
                            : null,
                      ),
                      child:
                          Text(_emojis[type]!, style: const TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      type,
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected ? _fbBlue : _fbGray,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
