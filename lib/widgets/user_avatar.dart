import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? blurHash;
  final double radius;

  const UserAvatar({
    super.key,
    this.imageUrl,
    this.blurHash,
    this.radius = 25.0,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      key: ValueKey(imageUrl), // Use a unique key to force rebuild
      radius: radius,
      backgroundColor: Colors.grey.shade300,
      child: ClipOval(
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Stack(
          children: [
            BlurHash(
              hash: blurHash ?? 'LKO2?U%2Tw=w]~RBVZRi};RPxuwH',
              imageFit: BoxFit.cover,
              decodingWidth: 200,
              decodingHeight: 200,
            ),
            CachedNetworkImage(
              key: ValueKey(imageUrl),
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              width: 2 * radius,
              height: 2 * radius,
              placeholder: (context, url) => BlurHash(
                hash: blurHash ?? 'LKO2?U%2Tw=w]~RBVZRi};RPxuwH',
              ),
              errorWidget: (context, url, error) => BlurHash(
                hash: blurHash ?? 'LKO2?U%2Tw=w]~RBVZRi};RPxuwH',
              ),
            ),
          ],
        )
            : const Icon(
          Icons.person,
          color: Colors.grey,
        ),
      ),
    );
  }
}
