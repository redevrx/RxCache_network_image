import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxcache_network_image/src/cache_manager/rx_cache_manager_mixing.dart';
import 'package:rxcache_network_image/src/utils/log.dart';

class BaseRxCacheManager implements RxCacheManagerMixing {
  final String _folder;

  BaseRxCacheManager({required String folder}) : _folder = folder {
    _createCacheFolder();
  }

  static const timeOut = Duration(minutes: 2);

  // Do not access this field directly; use [_httpClient] instead.
  // We set `autoUncompress` to false to ensure that we can trust the value of
  // the `Content-Length` HTTP header. We automatically uncompress the content
  // in our call to [consolidateHttpClientResponseBytes].
  static final HttpClient _sharedHttpClient =
      HttpClient()
        ..connectionTimeout = timeOut
        ..idleTimeout = timeOut;

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
  final List<String> _loadImageTask = [];

  String? _cacheFolder;
  int _maxMemoryCache = 26;

  @override
  void clearCache() async {
    println("start clearCache");
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

      println("clearCache success");
    } catch (e) {
      println("clearCache error: $e");
    }
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
    String? fileName = key ?? Uri.parse(url).pathSegments.lastOrNull;
    fileName = fileName?.replaceAll(RegExp('[,\\/\\\\]'), '');

    ///check waiting download
    if (!_loadImageTask.contains(fileName ?? '')) {
      ///first download in queue
      _loadImageTask.add(fileName ?? '');
      return await _download(fileName ?? '', url, headers, key);
    }

    return;
  }

  Future<void> _download(
    String fileName,
    String? url,
    Map<String, String>? headers,
    String? key,
  ) async {
    try {
      if (fileName == "" || '$url'.length < 6) return;
      final mFile = File("$cacheFolder/$fileName");

      ///exists file in disk
      if (await mFile.exists()) {
        _loadImageTask.remove(fileName);
        return;
      }

      final Uri resolved = Uri.base.resolve(url!);

      final request = await _httpClient.getUrl(resolved);
      headers?.forEach((String name, String value) {
        request.headers.add(name, value);
      });

      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<List<int>>(<int>[]);
        throw NetworkImageLoadException(
          statusCode: response.statusCode,
          uri: resolved,
        );
      }

      // final request = http.Request("GET", resolved);
      // request.headers.addAll(headers ?? {});
      // final response = await request.send();
      //
      // if (response.statusCode != HttpStatus.ok) {
      //   throw NetworkImageLoadException(
      //       statusCode: response.statusCode, uri: resolved);
      // }

      final ioSink = mFile.openWrite();
      List<int> bytes = [];
      await for (final List<int> byte in response) {
        bytes.addAll(byte);
        ioSink.add(byte);
      }

      setImageCache(fileName, Uint8List.fromList(bytes));

      ///save file to dis
      await ioSink.close();
      _loadImageTask.remove(fileName);
      println("download image: $url");
    } catch (e) {
      _loadImageTask.remove(fileName);
      println("download image: $url \nfailed: $e");
    }
  }

  Future<void> _createCacheFolder() async {
    final path = await getApplicationCacheDirectory();
    final mFile = File("${path.path}/$_folder");
    await Directory(mFile.path).create(recursive: true);
    _cacheFolder = mFile.path;
    println("Create Cache Folder Success");
  }

  @override
  Future<File?> getFile({String? url, String? key}) async {
    File? mFile;
    try {
      if (cacheFolder.isEmpty) {
        await _createCacheFolder();
      }
      String? mKey = url == null ? key : Uri.parse(url).pathSegments.last;
      mKey = mKey?.replaceAll(RegExp('[,\\/\\\\]'), '');
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
    } catch (_) {
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
    String? fileName = key ?? resolved.pathSegments.lastOrNull;
    fileName = fileName?.replaceAll(RegExp('[,\\/\\\\]'), '');
    final mFile = File("$cacheFolder/$fileName");

    try {
      ///
      if (await mFile.exists()) {
        final bytes = await mFile.readAsBytes();
        return bytes;
      }

      final fileBytes = getFormMemoryCache(fileName ?? '');
      if (fileBytes != null) {
        return fileBytes;
      }

      println("download image url: $url");
      final request = await _httpClient.getUrl(resolved);
      headers?.forEach((String name, String value) {
        request.headers.add(name, value);
      });

      final HttpClientResponse response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<List<int>>(<int>[]);
        throw NetworkImageLoadException(
          statusCode: response.statusCode,
          uri: resolved,
        );
      }

      List<int> bytes = [];
      int receiverBytes = 0;
      if (_loadImageTask.contains(fileName)) {
        final total = response.contentLength;
        await for (final List<int> byte in response) {
          bytes.addAll(byte);

          if (onBytesReceived != null) {
            receiverBytes += byte.length;
            final progress = ((receiverBytes / total) * 100).toInt();
            if (progress >= 0) {
              onBytesReceived(progress, total);
            }
          }
        }
      } else {
        final total = response.contentLength;
        final ioSink = mFile.openWrite();
        await for (final List<int> byte in response) {
          bytes.addAll(byte);
          ioSink.add(byte);

          if (onBytesReceived != null) {
            receiverBytes += byte.length;
            final progress = ((receiverBytes / total) * 100).toInt();
            if (progress >= 0) {
              onBytesReceived(progress, total);
            }
          }
        }

        ///save file to disk
        ioSink.close();
      }

      final mBytes = Uint8List.fromList(bytes);

      ///set to memory cache
      setImageCache(fileName ?? '', mBytes);
      return mBytes;
    } catch (e) {
      final bytes = getFormMemoryCache(fileName ?? '');
      println("download image stream failed: $e");

      return bytes;
    }
  }

  // void resizeAndSave(String fileName, File filePath, List<int> bytes) {
  //   _loadImageTask.remove(fileName);
  //   filePath.writeAsBytes(bytes);
  // }

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
      if (_cacheImages.isNotEmpty) {
        _cacheImages.remove(_cacheImages.keys.last);
      }
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
  Uint8List? getFormMemoryCache(String key, {String? url}) {
    final mKey =
        url != null
            ? Uri.parse(
              url,
            ).pathSegments.last.replaceAll(RegExp('[,\\/\\\\]'), '')
            : key;

    if (_cacheImages.containsKey(mKey)) {
      return _cacheImages[mKey];
    }

    return null;
  }

  @override
  int currentMemoryCacheSize() => _cacheImages.length;
}
