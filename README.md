<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

## Features

- Cache Image in disk
- Cache Image in memory
- Preload image in RxCacheManager

## Getting started

```dart
rxcache_network_image: 1.0.8
```

## Issue

หากใช้งานแล้วติดปัญหาสามารถเข้ามาสอบถามได้ที่เพจเฟส ได้เลยนะครับ
<a href="https://www.facebook.com/profile.php?id=100094077041664" target="_blank">Facebook Page</a>

## Usage

```dart
RxImage.cacheNetwork(
url: urls[index],
);


///set memory cache
cacheManager.setMemoryCache(size)

///download image
cacheManager.download()

///get file cache
cacheManager.getFile()
```

## Create Custom CacheManager

```dart
class CustomCacheManager extends BaseRxCacheManager {
  static CustomCacheManager? _instance;

  CustomCacheManager._({String folder = "rx_image_cache"}) : super(folder: folder);

  factory CustomCacheManager({String folder = "rx_image_cache"}) {
    _instance ??= CustomCacheManager._(folder: folder);
    return _instance!;
  }
}
```

## Example

```dart
class _MyHomePageState extends State<MyHomePage> {
  final cacheManager = RxCacheManager();
  @override
  void initState() {
    ///preload and cache disk
    for (final url in urls) {
      cacheManager.download(url: url).then((value) => null);
    }
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Expanded(
              child: ListView.builder(
                itemCount: urls.length,
                itemBuilder: (context, index) {
                  return RxImage.cacheNetwork(
                    url: urls[index],
                  );
                },
              ))
        ],
      ),
    );
  }
}
```

## Preview

<img src="https://github.com/redevrx/RxCache_network_image/blob/main/assets/example_preview.gif?raw=true" width="350"  alt="Example Video App"/>
