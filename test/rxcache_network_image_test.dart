import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:rxcache_network_image/rxcache_network_image.dart';

import 'rxcache_network_image_test.mocks.dart';

@GenerateNiceMocks([MockSpec<BaseRxCacheManager>(), MockSpec<File>()])
void main() {
  final cacheManager = MockBaseRxCacheManager();

  group('test cache manager', () {
    test('download image success case test', () async {
      await cacheManager.download(url: "www://test.com/image.png");
      verify(cacheManager.download(url: 'www://test.com/image.png'));
    });
    test('download image add auth headers success case test', () async {
      await cacheManager.download(
        url: "www://test.com/image.png",
        headers: {"token": ""},
      );
      verify(
        cacheManager.download(
          url: 'www://test.com/image.png',
          headers: {"token": ""},
        ),
      );
    });
    test('download image failed case test', () async {
      const url = "www://test.com/image.png";
      when(cacheManager.download(url: url)).thenThrow(
        NetworkImageLoadException(statusCode: 400, uri: Uri.parse(url)),
      );

      verifyNever(cacheManager.download(url: url));
      expect(
        () async => cacheManager.download(url: url),
        throwsA(isA<NetworkImageLoadException>()),
      );
    });
    test('check memory size test', () async {
      cacheManager.setMemoryCache(20);
      when(cacheManager.currentMemoryCacheSize()).thenReturn(20);
      expect(cacheManager.currentMemoryCacheSize(), 20);
    });
    test('get cache from memory success test', () async {
      when(
        cacheManager.getFormMemoryCache("key"),
      ).thenReturn(Uint8List.fromList([12, 324]));
      cacheManager.getFormMemoryCache("key");

      verify(cacheManager.getFormMemoryCache("key")).called(1);
      expect(cacheManager.getFormMemoryCache("key"), isA<Uint8List>());
    });
    test('get cache path success test', () async {
      when(cacheManager.getCache()).thenAnswer((_) async => 'path/file/cache');
      final response = await cacheManager.getCache();

      verify(cacheManager.getCache()).called(1);
      expect(response, isA<String>());
    });
    test('get cache from file success test', () async {
      const url = "url";
      when(cacheManager.getFile(url: url)).thenAnswer((_) async => MockFile());
      final response = await cacheManager.getFile(url: url);

      verify(cacheManager.getFile(url: url)).called(1);
      expect(response, isA<MockFile>());
    });
    test('get cache from file success test', () async {
      const url = "url";
      when(
        cacheManager.downloadStream(url: url),
      ).thenAnswer((_) async => Uint8List.fromList([12, 324]));
      final response = await cacheManager.downloadStream(url: url);

      verify(cacheManager.downloadStream(url: url)).called(1);
      expect(response, isA<Uint8List>());
    });
  });
}
