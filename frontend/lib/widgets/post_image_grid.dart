import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// FB-style image grid shared by post cards and post detail.
/// 1 image → full width 260px
/// 2 images → side by side
/// 3 images → 1 large left + 2 stacked right
/// 4+ images → 2x2 with +N overlay
class PostImageGrid extends StatelessWidget {
  const PostImageGrid({
    super.key,
    required this.imageUrls,
    this.onTap,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  final List<String> imageUrls;
  final void Function(int index)? onTap;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final urls = imageUrls;

    if (urls.length == 1) {
      return GestureDetector(
        onTap: () => onTap?.call(0),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: _img(urls[0], height: 260),
        ),
      );
    }

    if (urls.length == 2) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: Row(children: [
          Expanded(child: GestureDetector(onTap: () => onTap?.call(0), child: _img(urls[0], height: 180))),
          const SizedBox(width: 2),
          Expanded(child: GestureDetector(onTap: () => onTap?.call(1), child: _img(urls[1], height: 180))),
        ]),
      );
    }

    if (urls.length == 3) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: Row(children: [
          Expanded(flex: 3, child: GestureDetector(onTap: () => onTap?.call(0), child: _img(urls[0], height: 200))),
          const SizedBox(width: 2),
          Expanded(
            flex: 2,
            child: Column(children: [
              GestureDetector(onTap: () => onTap?.call(1), child: _img(urls[1], height: 99)),
              const SizedBox(height: 2),
              GestureDetector(onTap: () => onTap?.call(2), child: _img(urls[2], height: 99)),
            ]),
          ),
        ]),
      );
    }

    // 4+
    final shown = urls.take(4).toList();
    final extra = urls.length - 4;
    return ClipRRect(
      borderRadius: borderRadius,
      child: Column(children: [
        Row(children: [
          Expanded(child: GestureDetector(onTap: () => onTap?.call(0), child: _img(shown[0], height: 140))),
          const SizedBox(width: 2),
          Expanded(child: GestureDetector(onTap: () => onTap?.call(1), child: _img(shown[1], height: 140))),
        ]),
        const SizedBox(height: 2),
        Row(children: [
          Expanded(child: GestureDetector(onTap: () => onTap?.call(2), child: _img(shown[2], height: 140))),
          const SizedBox(width: 2),
          Expanded(
            child: GestureDetector(
              onTap: () => onTap?.call(3),
              child: Stack(fit: StackFit.passthrough, children: [
                _img(shown[3], height: 140),
                if (extra > 0)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black54,
                      alignment: Alignment.center,
                      child: Text('+$extra',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ]),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _img(String url, {required double height}) => CachedNetworkImage(
        imageUrl: url,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (_, _) => Container(height: height, color: Colors.grey.shade200),
        errorWidget: (_, _, _) => Container(
          height: height,
          color: Colors.grey.shade100,
          child: Icon(Icons.broken_image_outlined, color: Colors.grey.shade400),
        ),
      );
}
