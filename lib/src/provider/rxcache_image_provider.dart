import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui show Codec;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rxcache_network_image/src/cache_manager/rx_cache_manager_mixing.dart';
import 'package:rxcache_network_image/src/provider/multi_image_stream_completer.dart';

/// Listener for errors
typedef ErrorListener = void Function(Object);

class RxCacheImageProvider extends ImageProvider<RxCacheImageProvider> {
  final String url;
  final RxCacheManagerMixing? cacheManager;
  final double scale;
  final String? cacheKey;

  /// Listener to be called when images fails to load.
  final ErrorListener? errorListener;
  final Map<String, String>? headers;

  RxCacheImageProvider({
    required this.url,
    this.cacheManager,
    this.scale = 0.1,
    this.errorListener,
    this.cacheKey,
    this.headers,
  });

  @override
  Future<RxCacheImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<RxCacheImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    RxCacheImageProvider key,
    ImageDecoderCallback decode,
  ) {
    final chunkEvents = StreamController<ImageChunkEvent>();
    final imageStream = MultiImageStreamCompleter(
      codec: _loadImageAsync(key, chunkEvents, decode),
      chunkEvents: chunkEvents.stream,
      scale: key.scale,
      informationCollector: () sync* {
        yield DiagnosticsProperty<ImageProvider>(
          'Image provider: $this \n Image key: $key',
          this,
          style: DiagnosticsTreeStyle.errorProperty,
        );
      },
    );

    if (errorListener != null) {
      imageStream.addListener(
        ImageStreamListener(
          (image, synchronousCall) {},
          onError: (Object error, StackTrace? trace) {
            errorListener?.call(error);
          },
        ),
      );
    }

    return imageStream;
  }

  Stream<ui.Codec> _loadImageAsync(
    RxCacheImageProvider key,
    StreamController<ImageChunkEvent> chunkEvents,
    ImageDecoderCallback decode,
  ) async* {
    assert(url.length > 5, "invalid url");
    try {
      final mKeyCache = cacheKey ?? Uri.parse(url).pathSegments.last;
      if (cacheManager?.cacheFolder == null ||
          cacheManager?.cacheFolder == "") {
        await cacheManager?.getCache();
      }

      ///get file from memory cache
      final memoryCacheByte = cacheManager?.getFormMemoryCache(mKeyCache);
      if (memoryCacheByte != null) {
        final bytes = await ImmutableBuffer.fromUint8List(memoryCacheByte);
        final decoded = await decode(bytes);
        yield decoded;
      }

      File? mFile = File('${cacheManager?.cacheFolder}/$mKeyCache');
      if (await mFile.exists()) {
        ///load from dis
        final bytes = await mFile.readAsBytes();
        final mCode = await ImmutableBuffer.fromUint8List(bytes);

        ///set cache in memory
        cacheManager?.setImageCache(mKeyCache, bytes);

        yield await decode(mCode);
      } else {
        ///load from network
        ///and cache to disk
        final bytes = await cacheManager?.downloadStream(
          url: url,
          headers: headers,
          key: cacheKey,
          onBytesReceived: (cumulative, total) {
            chunkEvents.add(
              ImageChunkEvent(
                cumulativeBytesLoaded: cumulative,
                expectedTotalBytes: total,
              ),
            );
          },
        );

        if (bytes == null) {
          throw NetworkImageLoadException(
            statusCode: HttpStatus.badRequest,
            uri: Uri.parse(url),
          );
        }

        final imByte = await ImmutableBuffer.fromUint8List(bytes);
        final decoded = await decode(imByte);
        yield decoded;
      }

      ///
    } on Object catch (_) {
      scheduleMicrotask(() {
        evict();
      });
      rethrow;
    } finally {
      await chunkEvents.close();
    }
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is RxCacheImageProvider &&
        other.url == url &&
        other.cacheKey == cacheKey &&
        other.scale == scale;
  }

  @override
  int get hashCode => Object.hash(url, scale);

  @override
  String toString() =>
      '${objectRuntimeType(this, 'RxCacheImageProvider')}("$url", scale: ${scale.toStringAsFixed(1)})';
}
