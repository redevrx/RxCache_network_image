import 'dart:developer';

import 'package:flutter/foundation.dart';

class Log {
  static const name = "RxCacheImage";

  void message(Object message) {
    if (!kDebugMode) return;
    log(name: name, "$message");
  }
}

final mLog = Log();
void println(Object message) => mLog.message(message);
