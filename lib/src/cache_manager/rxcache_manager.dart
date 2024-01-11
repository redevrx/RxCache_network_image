import 'package:rxcache_network_image/src/cache_manager/base_rx_cache_manager.dart';

class RxCacheManager extends BaseRxCacheManager {
  static RxCacheManager? _instance;

  RxCacheManager._({String folder = "rx_image_cache"}) : super(folder: folder);

  factory RxCacheManager({String folder = "rx_image_cache"}) {
    _instance ??= RxCacheManager._(folder: folder);
    return _instance!;
  }
}
