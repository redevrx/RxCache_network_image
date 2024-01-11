import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxcache_network_image/src/cache_manager/rx_cache_manager_mixing.dart';

class BaseRxCacheManager implements RxCacheManagerMixing {
  final String _folder;
  BaseRxCacheManager({required String folder}) : _folder = folder {
    _createCacheFolder();
  }

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

  final Map<String, Uint8List> _cacheImages = {};
  final Map<String, StreamController<bool>> _loadImageTask = {};

  String? _cacheFolder;
  int _maxMemoryCache = 16;

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
      final mFile = File("$cacheFolder/$fileName");

      ///exists file in disk
      if (await mFile.exists()) {
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
      resizeAndSave(fileName, mFile, bytes);
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
      mFile = File("$_cacheFolder/$mKey");

      ///check exit in memory
      if (_cacheImages.containsKey(mKey)) {
        mFile = File.fromRawPath(_cacheImages[mKey]!);
      } else {
        if (!await mFile.exists()) {
          mFile = null;
        } else {
          final bytes = await mFile.readAsBytes();
          setImageCache(mKey ?? '', bytes);
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
    final mFile = File("$cacheFolder/$fileName");
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

      if (await mFile.exists()) {
        final fileBytes = getFormMemoryCache(fileName ?? '');
        if (fileBytes != null) {
          return fileBytes;
        } else {
          final bytes = await mFile.readAsBytes();
          return bytes;
        }
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
      resizeAndSave(fileName ?? '', mFile, bytes);

      return bytes;
    } catch (_) {
      await _loadImageTask[fileName]?.close();
      _loadImageTask.remove(fileName);
      final bytes = getFormMemoryCache(fileName ?? '');

      return bytes;
    }
  }

  void resizeAndSave(String fileName, File filePath, Uint8List bytes) async {
    await filePath.writeAsBytes(bytes);
    _loadImageTask[fileName]
      ?..sink
      ..add(
        true,
      );
    await _loadImageTask[fileName]?.close();
    _loadImageTask.remove(fileName);
  }

  @override
  void setMemoryCache(int size) {
    if (size <= 1) return;
    _maxMemoryCache = size;
  }

  @override
  String get memorySize => '$_maxMemoryCache';

  @override
  void setImageCache(String key, Uint8List bytes) {
    if (_cacheImages.length >= _maxMemoryCache) {
      _cacheImages.clear();
    }

    if (!_cacheImages.containsKey(key)) {
      _cacheImages[key] = bytes;
    }
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

  @override
  int currentMemoryCacheSize() => _cacheImages.length;
}
