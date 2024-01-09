import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rxcache_network_image/rxcache_network_image.dart';
import 'dart:ui' as ui show Codec;

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
  ImageStreamCompleter loadBuffer(
      RxCacheImageProvider key, DecoderBufferCallback decode) {
    final chunkEvents = StreamController<ImageChunkEvent>();

    final imageStream = MultiFrameImageStreamCompleter(
      codec: _loadImageBufferAsync(key, chunkEvents, decode),
      scale: scale,
      chunkEvents: chunkEvents.stream,
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

  Future<ui.Codec> _loadImageBufferAsync(
      RxCacheImageProvider key,
      StreamController<ImageChunkEvent> chunkEvents,
      DecoderBufferCallback decode) {
    assert(key == this);
    return _loadImageBuffer(
      key,
      chunkEvents,
      decode,
      () => PaintingBinding.instance.imageCache.evict(key),
    );
  }

  Future<ui.Codec> _loadImageBuffer(
    RxCacheImageProvider key,
    StreamController<ImageChunkEvent> chunkEvents,
    DecoderBufferCallback decode,
    VoidCallback evict,
  ) async {
    assert(
        cacheManager == null,
        'To resize the image with a CacheManager the '
        'CacheManager needs to be an RxCacheManager. maxWidth and '
        'maxHeight will be ignored when a normal RxCacheManager is used.');

    try {
      final mKeyCache = cacheKey ?? Uri.parse(url).pathSegments.last;
      final cacheFolder = await cacheManager?.getCache();
      final mFile = File('$cacheFolder/$mKeyCache.bin');

      if (mFile.existsSync()) {
        ///load from dis
        final totalSize = mFile.lengthSync();
        final chunksStream = mFile.openRead();
        List<int> bytes = [];

        await for (final chunks in chunksStream) {
          bytes.addAll(chunks);
          await Future.forEach(chunks, (chunk) {
            chunkEvents.add(ImageChunkEvent(
              cumulativeBytesLoaded: chunk,
              expectedTotalBytes: totalSize,
            ));
          });
        }

        return decode(
            await ImmutableBuffer.fromUint8List(Uint8List.fromList(bytes)));
      } else {
        ///load from network
        ///and cache to disk
        final bytes = await cacheManager?.downloadStream(
          url: url,
          headers: headers,
          key: cacheKey,
          onBytesReceived: (cumulative, total) {
            chunkEvents.add(ImageChunkEvent(
              cumulativeBytesLoaded: cumulative,
              expectedTotalBytes: total,
            ));
          },
        );

        return decode(await ImmutableBuffer.fromUint8List(bytes!));
      }

      ///
    } on Object {
      scheduleMicrotask(() {
        evict();
      });
      rethrow;
    } finally {
      await chunkEvents.close();
    }
  }

  @override
  ImageStreamCompleter loadImage(
      RxCacheImageProvider key, ImageDecoderCallback decode) {
    final chunkEvents = StreamController<ImageChunkEvent>();
    final imageStream = MultiFrameImageStreamCompleter(
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

  Future<ui.Codec> _loadImageAsync(
      RxCacheImageProvider key,
      StreamController<ImageChunkEvent> chunkEvents,
      ImageDecoderCallback decode) async {
    try {
      final mKeyCache = cacheKey ?? Uri.parse(url).pathSegments.last;
      if (cacheManager?.cacheFolder == "") {
        await cacheManager?.getCache();
      }

      ///get file from memory cache
      final memoryCacheByte = cacheManager?.getFormMemoryCache(mKeyCache);
      if (memoryCacheByte != null) {
        final mCode = await ImmutableBuffer.fromUint8List(memoryCacheByte);
        return decode(mCode);
      }

      File? mFile = File('${cacheManager?.cacheFolder}/$mKeyCache.bin');
      if (await mFile.exists()) {
        ///load from dis
        final bytes = await mFile.readAsBytes();
        final mCode = await ImmutableBuffer.fromUint8List(bytes);

        ///set cache in memory
        cacheManager?.setImageCache(mKeyCache, bytes);

        return decode(mCode);
      } else {
        ///load from network
        ///and cache to disk
        final bytes = await cacheManager?.downloadStream(
          url: url,
          headers: headers,
          key: cacheKey,
          onBytesReceived: (cumulative, total) {
            chunkEvents.add(ImageChunkEvent(
              cumulativeBytesLoaded: cumulative,
              expectedTotalBytes: total,
            ));
          },
        );

        return decode(await ImmutableBuffer.fromUint8List(bytes!));
      }

      ///
    } on Object {
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
        other.scale == scale;
  }

  @override
  int get hashCode => Object.hash(url, scale);

  @override
  String toString() =>
      '${objectRuntimeType(this, 'RxCacheImageProvider')}("$url", scale: ${scale.toStringAsFixed(1)})';
}
