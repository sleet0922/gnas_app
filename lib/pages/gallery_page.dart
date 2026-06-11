import 'package:flutter/material.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import '../services/api_service.dart';
import '../models/media_item.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage>
    with AutomaticKeepAliveClientMixin {
  final _api = ApiService();
  List<MediaItem> _items = [];
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadGallery();
  }

  Future<void> _loadGallery() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await _api.getGallery();
    if (!mounted) return;
    if (res.isSuccess && res.data != null) {
      setState(() {
        _items = res.data!;
        _loading = false;
      });
    } else {
      setState(() {
        _error = res.message ?? '加载失败';
        _loading = false;
      });
    }
  }

  Future<void> _uploadMedia() async {
    final assets = await AssetPicker.pickAssets(
      context,
      pickerConfig: const AssetPickerConfig(
        maxAssets: 99,
        requestType: RequestType.common,
      ),
    );
    if (assets == null || assets.isEmpty) return;

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('正在上传...')),
    );

    int success = 0;
    int failed = 0;
    for (final asset in assets) {
      final file = await asset.originFile;
      if (file == null) {
        failed++;
        continue;
      }
      final res = await _api.uploadFile('/', file);
      if (res.isSuccess) {
        success++;
      } else {
        failed++;
      }
    }

    if (!mounted) return;
    if (failed == 0) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('上传完成，成功 $success 个'),
          backgroundColor: Colors.green.shade600,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text('成功 $success 个，失败 $failed 个'),
          backgroundColor: Colors.orange.shade600,
        ),
      );
    }
    _loadGallery();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton.tonal(
                onPressed: _loadGallery, child: const Text('重试')),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined,
                size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('暂无媒体文件',
                style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadGallery,
          child: LayoutBuilder(
            builder: (_, constraints) {
              final crossAxisCount = constraints.maxWidth > 600 ? 4 : 3;
              return GridView.builder(
                padding: const EdgeInsets.all(4),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                ),
                itemCount: _items.length,
                itemBuilder: (_, i) {
                  final item = _items[i];
                  return GestureDetector(
                    onTap: () => _preview(item),
                    onLongPress: () => _deleteItem(item),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (item.isImage)
                          Image.network(
                            _api.getThumbUrl(item.path),
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _placeholder(item),
                          )
                        else
                          _placeholder(item),
                        if (item.isVideo)
                          const Center(
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.play_arrow,
                                    color: Colors.white, size: 32),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        // Upload button at bottom-right
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.small(
            heroTag: 'gallery_upload',
            onPressed: _uploadMedia,
            tooltip: '上传媒体文件',
            child: const Icon(Icons.upload),
          ),
        ),
      ],
    );
  }

  Widget _placeholder(MediaItem item) {
    return Container(
      color: Colors.grey.shade200,
      child: Icon(
        item.isImage ? Icons.image : Icons.videocam,
        color: Colors.grey.shade400,
        size: 40,
      ),
    );
  }

  Future<void> _deleteItem(MediaItem item) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final dialogTheme = Theme.of(ctx);
        return AlertDialog(
          title: const Text('确认删除'),
          content: Text('确定要删除 "${item.name}" 吗？'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消')),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: dialogTheme.colorScheme.error,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
    if (confirm != true) return;

    final res = await _api.deleteFile(item.path);
    if (!mounted) return;
    if (res.isSuccess) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('已删除 "${item.name}"'),
          backgroundColor: Colors.green.shade600,
        ),
      );
      _loadGallery();
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(res.message ?? '删除失败'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  void _preview(MediaItem item) {
    final images = _items.where((m) => m.isImage).toList();
    final initialIndex = images.indexWhere((m) => m.path == item.path);
    if (initialIndex < 0) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _GalleryPreviewPage(
          images: images,
          initialIndex: initialIndex,
          api: _api,
        ),
      ),
    );
  }
}

class _GalleryPreviewPage extends StatefulWidget {
  final List<MediaItem> images;
  final int initialIndex;
  final ApiService api;

  const _GalleryPreviewPage({
    required this.images,
    required this.initialIndex,
    required this.api,
  });

  @override
  State<_GalleryPreviewPage> createState() => _GalleryPreviewPageState();
}

class _GalleryPreviewPageState extends State<_GalleryPreviewPage> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_currentIndex + 1} / ${widget.images.length}',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (_, i) {
          final item = widget.images[i];
          final url = widget.api.getDownloadUrl(item.path, disposition: 'inline');
          return InteractiveViewer(
            minScale: 1.0,
            maxScale: 4.0,
            child: Center(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded /
                              progress.expectedTotalBytes!
                          : null,
                      color: Colors.white54,
                    ),
                  );
                },
                errorBuilder: (_, _, _) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.broken_image,
                        color: Colors.white38, size: 64),
                    const SizedBox(height: 8),
                    Text(
                      item.name,
                      style: const TextStyle(color: Colors.white38),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}