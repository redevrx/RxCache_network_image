import 'dart:io';
import 'dart:typed_data';

mixin RxCacheManagerMixing {
  String get cacheFolder;

  String get memorySize;

  void clearCache();

  void clearMemoryCache();

  Future<void> download({
    String? url,
    Map<String, String>? headers,
    String? key,
  });

  Future<Uint8List?> downloadStream({
    String? url,
    Map<String, String>? headers,
    String? key,
    void Function(int, int?)? onBytesReceived,
  });

  Future<File?> getFile({String? url, String? key});

  Future<String> getCache();

  void setMemoryCache(int size);

  void setImageCache(String key, Uint8List bytes);

  Uint8List? getFormMemoryCache(String key, {String? url});

  int currentMemoryCacheSize();
}
