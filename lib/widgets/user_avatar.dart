import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? blurHash;

  const UserAvatar({
    super.key,
    this.imageUrl,
    this.blurHash,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      key: ValueKey(imageUrl), // Use a unique key to force rebuild
      radius: 30,
      backgroundColor: Colors.grey.shade300,
      child: ClipOval(
        child: imageUrl != null
            ? Stack(
          children: [
            BlurHash(
              hash: blurHash ?? 'LKO2?U%2Tw=w]~RBVZRi};RPxuwH',
              imageFit: BoxFit.cover,
              decodingWidth: 60,
              decodingHeight: 60,
            ),
            CachedNetworkImage(
              key: ValueKey(imageUrl), // Ensure proper caching
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              width: 60,
              height: 60,
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
