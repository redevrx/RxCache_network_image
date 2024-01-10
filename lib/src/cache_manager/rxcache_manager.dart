import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

mixin RxCacheManagerMixing {
  String get cacheFolder;
  int _maxMemoryCache = 100 * 1024 * 1024;
  String get memorySize;
  final Map<String, Uint8List> _cacheImages = {};
  final Map<String, StreamController<bool>> _loadImageTask = {};

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
  Uint8List? getFormMemoryCache(String key);
}

class RxCacheManager with RxCacheManagerMixing {
  static String _folder = '';
  RxCacheManager._();
  static final _instance = RxCacheManager._();

  factory RxCacheManager({String folder = "images_cache"}) {
    _folder = folder;
    return _instance;
  }

  String? _cacheFolder;

  // Do not access this field directly; use [_httpClient] instead.
  // We set `autoUncompress` to false to ensure that we can trust the value of
  // the `Content-Length` HTTP header. We automatically uncompress the content
  // in our call to [consolidateHttpClientResponseBytes].
  static final HttpClient _sharedHttpClient = HttpClient()
    ..autoUncompress = false
    ..connectionTimeout = const Duration(seconds: 20)
    ..idleTimeout = const Duration(seconds: 20);

  static HttpClient get _httpClient {
    HttpClient? client;
    assert(() {
      if (debugNetworkImageHttpClientProvider != null) {
        client = debugNetworkImageHttpClientProvider!();
      }
      return true;
    }());
    return client ?? _sharedHttpClient;
  }

  @override
  void clearCache() async {
    final cache = await getCache();
    try {
      final folder = Directory(cache);
      if (folder.existsSync()) {
        await for (final file in folder.list()) {
          if (file is File) {
            await file.delete();
          }
        }
      }
    } catch (_) {}
  }

  ///[download]
  ///download file from url and check exits in disk
  @override
  Future<void> download({
    String? url,
    Map<String, String>? headers,
    String? key,
  }) async {
    if (_cacheFolder == '' || _cacheFolder == null) {
      await getCache();
    }
    if (url == null || url.isEmpty == true) return;
    final fileName = key ?? Uri.parse(url).pathSegments.lastOrNull;

    ///check waiting download
    if (!_loadImageTask.containsKey(fileName)) {
      _loadImageTask[fileName ?? ''] = StreamController();
      _queueLoad(fileName ?? '', url, headers, key);
    }
  }

  void _queueLoad(
    String fileName,
    String url,
    Map<String, String>? headers,
    String? key,
  ) async {
    if (_loadImageTask.isNotEmpty) {
      await _download(fileName, url, headers, key);
    }
  }

  Future<void> _download(
    String fileName,
    String url,
    Map<String, String>? headers,
    String? key,
  ) async {
    try {
      if (fileName.isEmpty) return;
      final mFile = File("$cacheFolder/$fileName.bin");

      ///exists file in disk
      if (mFile.existsSync()) {
        await _loadImageTask[fileName]?.close();
        _loadImageTask.remove(fileName);
        return;
      }

      final Uri resolved = Uri.base.resolve(url);
      final HttpClientRequest request = await _httpClient.getUrl(resolved);
      headers?.forEach((String name, String value) {
        request.headers.add(name, value);
      });

      final HttpClientResponse response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<List<int>>(<int>[]);
        throw NetworkImageLoadException(
            statusCode: response.statusCode, uri: resolved);
      }
      final Uint8List bytes = await consolidateHttpClientResponseBytes(
        response,
        onBytesReceived: (_, __) {},
      );

      setImageCache(fileName, bytes);

      ///save file to dis
      File("$cacheFolder/$fileName.bin").writeAsBytes(bytes).then((_) async {
        _loadImageTask[fileName]
          ?..sink
          ..add(true);
        await _loadImageTask[fileName]?.close();
        _loadImageTask.remove(fileName);
      });
    } catch (_) {
      await _loadImageTask[fileName]?.close();
      _loadImageTask.remove(fileName);
    }
  }

  Future<void> _createCacheFolder() async {
    final path = await getApplicationCacheDirectory();
    final mFile = File("${path.path}/$_folder");
    Directory(mFile.path).createSync(recursive: true);
    _cacheFolder = mFile.path;
  }

  @override
  Future<File?> getFile({String? url, String? key}) async {
    File? mFile;
    try {
      if (cacheFolder.isEmpty) {
        await _createCacheFolder();
      }
      final mKey = url == null ? key : Uri.parse(url).pathSegments.last;
      mFile = File("$_cacheFolder/$mKey.bin");

      ///check exit in memory
      if (_cacheImages.containsKey(mKey)) {
        mFile = File.fromRawPath(_cacheImages[mKey]!);
      } else {
        if (!mFile.existsSync()) {
          mFile = null;
        } else {
          setImageCache(mKey ?? '', mFile.readAsBytesSync());
        }
      }
    } catch (_, __) {
      mFile = null;
    }

    return mFile;
  }

  @override
  String get cacheFolder => _cacheFolder ?? '';

  @override
  Future<String> getCache() async {
    if (_cacheFolder == null || _cacheFolder?.isEmpty == true) {
      await _createCacheFolder();
    }

    return cacheFolder;
  }

  ///[downloadStream]
  ///download file from url no check exits in disk
  ///and cache to memory
  @override
  Future<Uint8List?> downloadStream({
    String? url,
    Map<String, String>? headers,
    String? key,
    void Function(int, int?)? onBytesReceived,
  }) async {
    final Uri resolved = Uri.base.resolve(url ?? '');
    final fileName = key ?? resolved.pathSegments.lastOrNull;
    final mFile = File("$cacheFolder/$fileName.bin");
    if (url == null) return null;

    try {
      ///
      if (_loadImageTask.containsKey(fileName)) {
        ///wait for downloading
        await for (final _ in _loadImageTask[fileName]!.stream) {}
        final fileBytes = getFormMemoryCache(fileName ?? '');
        if (fileBytes != null) {
          return fileBytes;
        }
      }

      if (mFile.existsSync()) {
        return await mFile.readAsBytes();
      }

      _loadImageTask[fileName ?? ''] = StreamController();
      final HttpClientRequest request = await _httpClient.getUrl(resolved);
      headers?.forEach((String name, String value) {
        request.headers.add(name, value);
      });

      final HttpClientResponse response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<List<int>>(<int>[]);
        throw NetworkImageLoadException(
            statusCode: response.statusCode, uri: resolved);
      }

      final Uint8List bytes = await consolidateHttpClientResponseBytes(
        response,
        onBytesReceived: onBytesReceived,
      );

      ///set to memory cache
      setImageCache(fileName ?? '', bytes);

      ///save file to disk
      mFile.writeAsBytes(bytes).then((_) async {
        _loadImageTask[fileName]
          ?..sink
          ..add(
            true,
          );
        await _loadImageTask[fileName]?.close();
        _loadImageTask.remove(fileName);
      });

      return bytes;
    } catch (_) {
      await _loadImageTask[fileName]?.close();
      _loadImageTask.remove(fileName);
      return getFormMemoryCache(fileName ?? '');
    }
  }

  @override
  void setMemoryCache(int size) {
    if (size < 10) return;
    _maxMemoryCache = size;
  }

  @override
  String get memorySize => '$_maxMemoryCache';

  @override
  void setImageCache(String key, Uint8List bytes) {
    final currentSize = _calculateSizeOf(_cacheImages);
    if (currentSize >= _maxMemoryCache) {
      _cacheImages.clear();
    }

    if (!_cacheImages.containsKey(key)) {
      _cacheImages[key] = bytes;
    }
  }

  int _calculateSizeOf(dynamic value) {
    if (value == null) {
      return 0;
    }
    if (value is Map) {
      int size = 0;
      for (var entry in value.entries) {
        size += _calculateSizeOf(entry.key) + _calculateSizeOf(entry.value);
      }
      return size;
    }
    if (value is Iterable) {
      return value.fold(
          0, (int size, dynamic element) => size + _calculateSizeOf(element));
    }
    if (value is String) {
      return value.length * 2;
    }
    return 1;
  }

  @override
  void clearMemoryCache() {
    _cacheImages.clear();
  }

  @override
  Uint8List? getFormMemoryCache(String key) {
    if (_cacheImages.containsKey(key)) {
      return _cacheImages[key];
    }

    return null;
  }
}
