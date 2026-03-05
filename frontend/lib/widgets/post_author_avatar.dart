import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Shows a cached network avatar if URL is set, otherwise a colored initials circle.
class PostAuthorAvatar extends StatelessWidget {
  const PostAuthorAvatar({
    super.key,
    required this.name,
    required this.avatarUrl,
    required this.size,
  });

  final String name;
  final String avatarUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (avatarUrl.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatarUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, _) => _initials(),
          errorWidget: (_, _, _) => _initials(),
        ),
      );
    }
    return _initials();
  }

  Widget _initials() {
    final initial = name.isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    final color = _colorFromName(name);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _colorFromName(String name) {
    const colors = [
      Color(0xFF1A73E8),
      Color(0xFF34A853),
      Color(0xFFEA4335),
      Color(0xFFFBBC05),
      Color(0xFF9C27B0),
      Color(0xFF00BCD4),
      Color(0xFFFF5722),
      Color(0xFF607D8B),
    ];
    if (name.isEmpty) return colors[0];
    return colors[name.codeUnitAt(0) % colors.length];
  }
}
