import 'package:flutter/material.dart';
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

    return RefreshIndicator(
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

  void _preview(MediaItem item) {
    if (item.isImage) {
      final url = _api.getDownloadUrl(item.path, disposition: 'inline');
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text(item.name)),
            body: InteractiveViewer(
              child: Center(
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
          ),
        ),
      );
    }
  }
}