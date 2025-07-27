import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pexels/main.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/photo_model.dart';

class EnhancedPhotoSliverGrid extends StatelessWidget {
  final List<Photo> photos;
  const EnhancedPhotoSliverGrid({super.key, required this.photos});

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'No photos found!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(8),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.7,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final photo = photos[index];
          final imageUrl = photo.url.isNotEmpty
              ? photo.url
              : 'https://via.placeholder.com/400x600?text=No+Image';

          return GestureDetector(
            onTap: () => _showImageDialog(context, photo),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Text(
                      photo.photographer.isNotEmpty
                          ? photo.title
                          : photo.photographer,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildActionButton(
                          icon: Icons.download,
                          onTap: () => _downloadImage(context, imageUrl),
                        ),
                        const SizedBox(width: 4),
                        _buildActionButton(
                          icon: Icons.share,
                          onTap: () => _shareImage(imageUrl),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }, childCount: photos.length),
      ),
    );
  }

  void _showImageDialog(BuildContext context, Photo photo) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    photo.photographer,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Flexible(
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: photo.url,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () => _downloadImage(context, photo.url),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () => _shareImage(photo.url),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onTap,
        splashRadius: 22,
      ),
    );
  }

  Future<void> _downloadImage(BuildContext context, String url) async {
    try {
      bool permissionGranted = await requestStoragePermission();
      if (!permissionGranted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission denied')),
        );
        return;
      }

      final dir = await getExternalStorageDirectory();
      if (dir == null) throw Exception('Cannot access storage');

      debugPrint('Downloading image to: ${dir.path}');

      await FlutterDownloader.enqueue(
        url: url,
        savedDir: dir.path,
        fileName: 'pexels_photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
        showNotification: true,
        openFileFromNotification: true,
      );

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download started')),
      );
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    }
  }

  Future<void> _shareImage(String url) async {
    try {
      await Share.share(
        'Check out this amazing photo from Pexels: $url',
        subject: 'Pexels Photo',
      );
    } catch (e) {
      debugPrint('Sharing failed: $e');
    }
  }
}
