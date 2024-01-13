import 'package:flutter/material.dart';
import 'package:rxcache_network_image/src/image/fade_widget.dart';

import '../cache_manager/rx_cache_manager_mixing.dart';

class RxHeroImage extends StatefulWidget {
  RxHeroImage({
    super.key,
    required ImageProvider image,
    required this.imageUrl,
    required this.cacheManager,
    this.cacheKey,
    this.errorListener,
    this.width,
    this.height,
    this.fit,
    this.color,
    required this.gaplessPlayback,
    this.errorBuilder,
    this.opacity,
    required this.filterQuality,
    this.colorBlendMode,
    required this.alignment,
    required this.repeat,
    this.centerSlice,
    required this.matchTextDirection,
    required this.isAntiAlias,
    required this.excludeFromSemantics,
    this.semanticLabel,
    this.loadingBuilder,
    int? cacheHeight,
    int? cacheWidth,
  }) : image = ResizeImage.resizeIfNeeded(cacheWidth, cacheHeight, image);

  /// The image to display.
  final ImageProvider image;

  /// The target image that is displayed.
  final String imageUrl;

  /// Option to use cacheManager with other settings
  final RxCacheManagerMixing cacheManager;

  /// The target image's cache key.
  final String? cacheKey;

  /// Listener to be called when images fails to load.
  final ValueChanged<Object>? errorListener;

  /// If non-null, require the image to have this width.
  ///
  /// If null, the image will pick a size that best preserves its intrinsic
  /// aspect ratio. This may result in a sudden change if the size of the
  /// placeholder widget does not match that of the target image. The size is
  /// also affected by the scale factor.
  final double? width;

  /// If non-null, require the image to have this height.
  ///
  /// If null, the image will pick a size that best preserves its intrinsic
  /// aspect ratio. This may result in a sudden change if the size of the
  /// placeholder widget does not match that of the target image. The size is
  /// also affected by the scale factor.
  final double? height;

  /// How to inscribe the image into the space allocated during layout.
  ///
  /// The default varies based on the other fields. See the discussion at
  /// [paintImage].
  final BoxFit? fit;

  /// If non-null, this color is blended with each image pixel using [colorBlendMode].
  final Color? color;

  /// Whether to continue showing the old image (true), or briefly show nothing
  /// (false), when the image provider changes. The default value is false.
  ///
  /// ## Design discussion
  ///
  /// ### Why is the default value of [gaplessPlayback] false?
  ///
  /// Having the default value of [gaplessPlayback] be false helps prevent
  /// situations where stale or misleading information might be presented.
  /// Consider the following case:
  ///
  /// We have constructed a 'Person' widget that displays an avatar [Image] of
  /// the currently loaded person along with their name. We could request for a
  /// new person to be loaded into the widget at any time. Suppose we have a
  /// person currently loaded and the widget loads a new person. What happens
  /// if the [Image] fails to load?
  ///
  /// * Option A ([gaplessPlayback] = false): The new person's name is coupled
  /// with a blank image.
  ///
  /// * Option B ([gaplessPlayback] = true): The widget displays the avatar of
  /// the previous person and the name of the newly loaded person.
  ///
  /// This is why the default value is false. Most of the time, when you change
  /// the image provider you're not just changing the image, you're removing the
  /// old widget and adding a new one and not expecting them to have any
  /// relationship. With [gaplessPlayback] on you might accidentally break this
  /// expectation and re-use the old widget.
  final bool gaplessPlayback;

  /// A builder function that is called if an error occurs during image loading.
  ///
  /// If this builder is not provided, any exceptions will be reported to
  /// [FlutterError.onError]. If it is provided, the caller should either handle
  /// the exception by providing a replacement widget, or rethrow the exception.
  ///
  /// {@tool dartpad}
  /// The following sample uses [errorBuilder] to show a '😢' in place of the
  /// image that fails to load, and prints the error to the console.
  ///
  /// ** See code in examples/api/lib/widgets/image/image.error_builder.0.dart **
  /// {@end-tool}
  final ImageErrorWidgetBuilder? errorBuilder;

  /// If non-null, the value from the [Animation] is multiplied with the opacity
  /// of each image pixel before painting onto the canvas.
  ///
  /// This is more efficient than using [FadeTransition] to change the opacity
  /// of an image, since this avoids creating a new composited layer. Composited
  /// layers may double memory usage as the image is painted onto an offscreen
  /// render target.
  ///
  /// See also:
  ///
  ///  * [AlwaysStoppedAnimation], which allows you to create an [Animation]
  ///    from a single opacity value.
  final Animation<double>? opacity;

  /// The rendering quality of the image.
  ///
  /// {@template flutter.widgets.image.filterQuality}
  /// If the image is of a high quality and its pixels are perfectly aligned
  /// with the physical screen pixels, extra quality enhancement may not be
  /// necessary. If so, then [FilterQuality.none] would be the most efficient.
  ///
  /// If the pixels are not perfectly aligned with the screen pixels, or if the
  /// image itself is of a low quality, [FilterQuality.none] may produce
  /// undesirable artifacts. Consider using other [FilterQuality] values to
  /// improve the rendered image quality in this case. Pixels may be misaligned
  /// with the screen pixels as a result of transforms or scaling.
  ///
  /// See also:
  ///
  ///  * [FilterQuality], the enum containing all possible filter quality
  ///    options.
  /// {@endtemplate}
  final FilterQuality filterQuality;

  /// Used to combine [color] with this image.
  ///
  /// The default is [BlendMode.srcIn]. In terms of the blend mode, [color] is
  /// the source and this image is the destination.
  ///
  /// See also:
  ///
  ///  * [BlendMode], which includes an illustration of the effect of each blend mode.
  final BlendMode? colorBlendMode;

  /// How to align the image within its bounds.
  ///
  /// The alignment aligns the given position in the image to the given position
  /// in the layout bounds. For example, an [Alignment] alignment of (-1.0,
  /// -1.0) aligns the image to the top-left corner of its layout bounds, while an
  /// [Alignment] alignment of (1.0, 1.0) aligns the bottom right of the
  /// image with the bottom right corner of its layout bounds. Similarly, an
  /// alignment of (0.0, 1.0) aligns the bottom middle of the image with the
  /// middle of the bottom edge of its layout bounds.
  ///
  /// To display a subpart of an image, consider using a [CustomPainter] and
  /// [Canvas.drawImageRect].
  ///
  /// If the [alignment] is [TextDirection]-dependent (i.e. if it is a
  /// [AlignmentDirectional]), then an ambient [Directionality] widget
  /// must be in scope.
  ///
  /// Defaults to [Alignment.center].
  ///
  /// See also:
  ///
  ///  * [Alignment], a class with convenient constants typically used to
  ///    specify an [AlignmentGeometry].
  ///  * [AlignmentDirectional], like [Alignment] for specifying alignments
  ///    relative to text direction.
  final Alignment alignment;

  /// How to paint any portions of the layout bounds not covered by the image.
  final ImageRepeat repeat;

  /// The center slice for a nine-patch image.
  ///
  /// The region of the image inside the center slice will be stretched both
  /// horizontally and vertically to fit the image into its destination. The
  /// region of the image above and below the center slice will be stretched
  /// only horizontally and the region of the image to the left and right of
  /// the center slice will be stretched only vertically.
  final Rect? centerSlice;

  /// Whether to paint the image in the direction of the [TextDirection].
  ///
  /// If this is true, then in [TextDirection.ltr] contexts, the image will be
  /// drawn with its origin in the top left (the "normal" painting direction for
  /// images); and in [TextDirection.rtl] contexts, the image will be drawn with
  /// a scaling factor of -1 in the horizontal direction so that the origin is
  /// in the top right.
  ///
  /// This is occasionally used with images in right-to-left environments, for
  /// images that were designed for left-to-right locales. Be careful, when
  /// using this, to not flip images with integral shadows, text, or other
  /// effects that will look incorrect when flipped.
  ///
  /// If this is true, there must be an ambient [Directionality] widget in
  /// scope.
  final bool matchTextDirection;

  /// Whether to paint the image with anti-aliasing.
  ///
  /// Anti-aliasing alleviates the sawtooth artifact when the image is rotated.
  final bool isAntiAlias;

  /// Whether to exclude this image from semantics.
  ///
  /// Useful for images which do not contribute meaningful information to an
  /// application.
  final bool excludeFromSemantics;

  /// A Semantic description of the image.
  ///
  /// Used to provide a description of the image to TalkBack on Android, and
  /// VoiceOver on iOS.
  final String? semanticLabel;

  final ImageLoadingBuilder? loadingBuilder;

  @override
  State<RxHeroImage> createState() => _RxHeroImageState();
}

class _RxHeroImageState extends State<RxHeroImage> {
  late Image _image;
  int retryCount = 0;

  @override
  void initState() {
    _image = Image(
      image: widget.image,
      color: widget.color,
      fit: widget.fit,
      height: widget.height,
      width: widget.width,
      key: ValueKey(widget.image),
      alignment: widget.alignment,
      colorBlendMode: widget.colorBlendMode,
      errorBuilder: errorBuilder,
      filterQuality: widget.filterQuality,
      gaplessPlayback: widget.gaplessPlayback,
      matchTextDirection: widget.matchTextDirection,
      repeat: widget.repeat,
      semanticLabel: widget.semanticLabel,
      isAntiAlias: widget.isAntiAlias,
      opacity: widget.opacity,
      excludeFromSemantics: widget.excludeFromSemantics,
      centerSlice: widget.centerSlice,
      frameBuilder: loadFrameBuilder,
      loadingBuilder: widget.loadingBuilder ?? loadingProgress,
    );
    super.initState();
  }

  Widget errorBuilder(context, error, stackTrace) {
    if (widget.imageUrl.isNotEmpty) {
      if (retryCount <= 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            retryCount += 1;
          });
        });
      }
    }

    if (widget.errorBuilder != null) {
      return widget.errorBuilder!(context, error, stackTrace);
    }
    return const SizedBox.shrink();
  }

  @override
  void didUpdateWidget(covariant RxHeroImage oldWidget) {
    if (oldWidget.image != widget.image) {
      retryCount = 0;
      _image = Image(
        image: widget.image,
        color: widget.color,
        fit: widget.fit,
        height: widget.height,
        width: widget.width,
        key: ValueKey(widget.image),
        alignment: widget.alignment,
        colorBlendMode: widget.colorBlendMode,
        errorBuilder: errorBuilder,
        filterQuality: widget.filterQuality,
        gaplessPlayback: widget.gaplessPlayback,
        matchTextDirection: widget.matchTextDirection,
        repeat: widget.repeat,
        semanticLabel: widget.semanticLabel,
        isAntiAlias: widget.isAntiAlias,
        opacity: widget.opacity,
        excludeFromSemantics: widget.excludeFromSemantics,
        centerSlice: widget.centerSlice,
        frameBuilder: loadFrameBuilder,
        loadingBuilder: widget.loadingBuilder ?? loadingProgress,
      );
    }
    super.didUpdateWidget(oldWidget);
  }

  Widget loadingProgress(
    BuildContext context,
    Widget child,
    ImageChunkEvent? loadingProgress,
  ) {
    return child;
  }

  Widget loadFrameBuilder(
    BuildContext context,
    Widget child,
    int? frame,
    bool wasSynchronouslyLoaded,
  ) {
    if (wasSynchronouslyLoaded) {
      return child;
    }

    return FadeWidget(child: child);
  }

  @override
  Widget build(BuildContext context) {
    return _image;
  }
}
