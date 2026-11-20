import 'package:flutter/material.dart';

import '../l10n_strings.dart';

class PostImage extends StatelessWidget {
  const PostImage({super.key, required this.image, this.maxHeight = 400, this.onRetry});

  final ImageProvider image;
  final double maxHeight;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => _FullScreenImage(image: image),
          )),
          child: Semantics(
            label: strings(context).postImageOpen,
            button: true,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: Image(
                image: image,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Center(
                  child: onRetry == null
                      ? Text(strings(context).postImageUnavailable)
                      : TextButton(onPressed: onRetry, child: Text(strings(context).postImageRetry)),
                ),
              ),
            ),
          ),
        ),
      );
}

class _FullScreenImage extends StatelessWidget {
  const _FullScreenImage({required this.image});
  final ImageProvider image;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(strings(context).postImageTitle),
        ),
        body: Center(
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Center(
              child: Image(
                image: image,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Text(
                  strings(context).postImageUnavailable,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      );
}
