import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:photo_view/photo_view.dart';

class GalleryScreen extends StatelessWidget {
  GalleryScreen({super.key});

  // Custom cache manager with specific cache control
  final CacheManager _customCacheManager = CacheManager(
    Config(
      'customGalleryCacheKey', // Unique cache key
      stalePeriod: const Duration(days: 7), // Cache for 7 days
      maxNrOfCacheObjects: 100, // Max 100 images cached
    ),
  );

  Future<Map<String, Map<String, dynamic>>> _fetchGalleryImages() async {
    final storageRef = FirebaseStorage.instance.ref('Gallery');
    final ListResult result = await storageRef.listAll();
    final Map<String, Map<String, dynamic>> allImages = {};

    for (var prefix in result.prefixes) {
      final ListResult subFolderResult = await prefix.listAll();
      final List<String> urls = await Future.wait(
        subFolderResult.items.map((ref) => ref.getDownloadURL()).toList(),
      );

      // Extract the folder name and date
      final folderNameParts = prefix.name.split('_');
      final name = folderNameParts[0];
      final date =
          folderNameParts.length > 1 ? folderNameParts[1] : 'Unknown Date';

      allImages[prefix.name] = {
        'name': name,
        'date': date,
        'urls': urls,
      };
    }

    return allImages;
  }

  Widget _buildShimmerPreview() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.0),
        child: Container(
          width: 80,
          height: 80,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildFolderTile(
      BuildContext context, String folderKey, Map<String, dynamic> folderData) {
    final name = folderData['name'] as String;
    final date = folderData['date'] as String;
    final imageUrls = folderData['urls'] as List<String>;

    return Column(
      children: [
        ClipRRect(
          borderRadius:
              BorderRadius.circular(12.0), // Border radius for ListTile
          child: Container(
            color: const Color(0xffe7e0ff), // Background color for ListTile
            child: ListTile(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      FolderViewScreen(folderName: name, imageUrls: imageUrls),
                ),
              ),
              leading: ClipRRect(
                borderRadius:
                    BorderRadius.circular(10.0), // Border radius for the image
                child: CachedNetworkImage(
                  imageUrl: imageUrls.isNotEmpty ? imageUrls.first : '',
                  placeholder: (context, url) => _buildShimmerPreview(),
                  errorWidget: (context, url, error) => Container(
                    width: 90,
                    height: 90,
                    color: Colors.grey[200],
                    child: const Icon(Icons.error, color: Colors.red),
                  ),
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  cacheManager: _customCacheManager, // Use custom cache manager
                ),
              ),
              title: Text(
                name,
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                date,
                style: const TextStyle(
                  fontSize: 14.0,
                  color: Colors.grey,
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
            ),
          ),
        ),
        const SizedBox(height: 16.0), // Space between folder tiles
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gallery',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xff986ae7),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<Map<String, Map<String, dynamic>>>(
        future: _fetchGalleryImages(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView(
              padding: const EdgeInsets.all(8.0),
              children: [
                _buildShimmerPreview(),
              ],
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No images available.'));
          } else {
            return ListView(
              padding: const EdgeInsets.all(8.0),
              children: snapshot.data!.entries.map((entry) {
                return _buildFolderTile(context, entry.key, entry.value);
              }).toList(),
            );
          }
        },
      ),
    );
  }
}

class FolderViewScreen extends StatelessWidget {
  final String folderName;
  final List<String> imageUrls;

  const FolderViewScreen(
      {super.key, required this.folderName, required this.imageUrls});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          folderName,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xff986ae7),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Two columns for grid layout
          crossAxisSpacing: 6.0,
          mainAxisSpacing: 6.0,
          childAspectRatio: 1, // 1:1 aspect ratio
        ),
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius:
                BorderRadius.circular(12.0), // Border radius for grid items
            child: GestureDetector(
              onTap: () => _showEnlargedImage(context, imageUrls[index]),
              child: CachedNetworkImage(
                imageUrl: imageUrls[index],
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Container(
                      color: Colors.white,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: Colors.red),
                      SizedBox(height: 8.0),
                      Text('Failed to load image'),
                    ],
                  ),
                ),
                fit: BoxFit.cover, // Cover the grid cell completely
                cacheManager: CacheManager(
                  Config(
                    'customGalleryCacheKey',
                    stalePeriod: const Duration(days: 7),
                    maxNrOfCacheObjects: 100,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showEnlargedImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: PhotoView(
              imageProvider: CachedNetworkImageProvider(imageUrl),
              backgroundDecoration:
                  const BoxDecoration(color: Colors.transparent),
              minScale: PhotoViewComputedScale.contained *
                  1.3, // Start at device width
              maxScale:
                  PhotoViewComputedScale.covered * 4.0, // Allow up to 4x zoom
              loadingBuilder: (context, event) => Center(
                child: CircularProgressIndicator(
                  value: event == null
                      ? null
                      : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
                ),
              ),
              errorBuilder: (context, url, error) => Container(
                color: Colors.grey[200],
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, color: Colors.red),
                    SizedBox(height: 8.0),
                    Text('Failed to load image'),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
