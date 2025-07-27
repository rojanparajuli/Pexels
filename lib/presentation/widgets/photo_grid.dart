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

    final crossAxisCount = _getCrossAxisCount(context);

    return SliverPadding(
      padding: const EdgeInsets.all(8),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.65,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final photo = photos[index];
          final imageUrl = photo.imageUrl.isNotEmpty
              ? photo.imageUrl
              : 'https://via.placeholder.com/400x600?text=No+Image';

          return GestureDetector(
            onTap: () => _openFullScreenViewer(context, photo),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'photo_${photo.id}',
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                    ),
                  ),

                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.6),
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
                      photo.title.isNotEmpty ? photo.title : photo.photographer,
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
                          icon: Icons.download_rounded,
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

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  void _openFullScreenViewer(BuildContext context, Photo photo) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _FullScreenPhotoViewer(photo: photo)),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
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
      final permissionGranted = await requestStoragePermission();
      if (!permissionGranted) {
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Download started')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
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

class _FullScreenPhotoViewer extends StatelessWidget {
  final Photo photo;
  const _FullScreenPhotoViewer({required this.photo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: Hero(
              tag: 'photo_${photo.id}',
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: photo.imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    photo.photographer,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.download),
                  label: const Text('Download'),
                  onPressed: () => _downloadImage(context, photo.imageUrl),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                  onPressed: () => _shareImage(photo.imageUrl),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _downloadImage(BuildContext context, String url) async {
  try {
    final permissionGranted = await requestStoragePermission();
    if (!permissionGranted) {
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

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Download started')));
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
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
