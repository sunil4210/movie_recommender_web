import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';

/// Single source for rendering a movie poster image.
///
/// Layering:
///   1. BlurHash placeholder (instant, ~30 bytes payload) — only if hash present.
///   2. CachedNetworkImage fades in over the placeholder once decoded.
///   3. Disk + memory caching via cached_network_image.
///   4. `fallback` builder is shown when both url is null/empty AND there is no hash.
///
/// `memCacheWidth` is set from the requested width to avoid decoding 1500px posters
/// into a 140px slot, which crushes scroll perf on web.
class MoviePoster extends StatelessWidget {
  const MoviePoster({
    required this.url,
    required this.blurHash,
    required this.width,
    required this.height,
    required this.fallbackBuilder,
    this.borderRadius = BorderRadius.zero,
    super.key,
  });

  final String? url;
  final String? blurHash;
  final double width;
  final double height;
  final WidgetBuilder fallbackBuilder;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final bool hasUrl = url != null && url!.isNotEmpty;
    final bool hasHash = blurHash != null && blurHash!.isNotEmpty;
    final int? memCacheWidth = width.isFinite && width > 0
        ? (width * MediaQuery.of(context).devicePixelRatio).round()
        : null;

    Widget placeholder = hasHash
        ? BlurHash(hash: blurHash!, decodingWidth: 32, decodingHeight: 32)
        : fallbackBuilder(context);

    Widget image;
    if (hasUrl) {
      image = CachedNetworkImage(
        imageUrl: url!,
        fit: BoxFit.cover,
        width: width,
        height: height,
        memCacheWidth: memCacheWidth,
        fadeInDuration: const Duration(milliseconds: 250),
        placeholder: (BuildContext c, String _) => placeholder,
        errorWidget: (BuildContext c, String _, Object __) =>
            fallbackBuilder(c),
      );
    } else {
      image = placeholder;
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(width: width, height: height, child: image),
    );
  }
}
