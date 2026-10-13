/// This file is a part of media_kit (https://github.com/media-kit/media-kit).
///
/// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
/// All rights reserved.
/// Use of this source code is governed by MIT license that can be found in the LICENSE file.
import 'dart:ffi';

import 'package:media_kit/generated/libmpv/bindings.dart' as generated;
import 'package:media_kit/src/player/native/core/initializer_isolate.dart';

/// {@template initializer}
///
/// Initializer
/// -----------
/// Initializes [Pointer<mpv_handle>] & notifies about events through the supplied callback.
///
/// {@endtemplate}
class Initializer {
  /// Singleton instance.
  static Initializer? _instance;

  /// {@macro initializer}
  Initializer._(this.mpv);

  /// {@macro initializer}
  factory Initializer(generated.MPV mpv) {
    _instance ??= Initializer._(mpv);
    return _instance!;
  }

  /// Generated libmpv C API bindings.
  final generated.MPV mpv;

  /// Creates [Pointer<mpv_handle>].
  Future<Pointer<generated.mpv_handle>> create(
    Future<void> Function(Pointer<generated.mpv_event>) callback, {
    Map<String, String> options = const {},
  }) async {
    // [mayogu] Force the isolate-based initializer. InitializerNativeCallable
    // hands a Dart trampoline to libmpv (mpv_set_wakeup_callback) that outlives
    // the isolate: libmpv keeps calling it after the engine is torn down, or
    // after Player.dispose() closes it while mpv_terminate_destroy still waits
    // its 5s delay, killing the process (SIGSEGV/SIGABRT).
    // InitializerIsolate blocks in mpv_wait_event() and never passes a Dart
    // pointer to libmpv. Same path upstream uses in debug (PR #1352).
    // Refs: https://github.com/media-kit/media-kit/issues/1443
    return InitializerIsolate().create(callback, options: options);
  }

  /// Disposes [Pointer<mpv_handle>].
  void dispose(Pointer<generated.mpv_handle> ctx) {
    InitializerIsolate().dispose(mpv, ctx);
  }
}
