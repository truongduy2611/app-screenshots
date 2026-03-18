import 'package:flutter/material.dart';

import 'info/device_type.dart';
import 'info/info.dart';

/// Simulate a physical device and embedding a virtual
/// [screen] into it.
///
/// The [screen] media query's `padding`, `devicePixelRatio`, `size` are also
/// simulated from the device's info by overriding the default values.
///
/// The [screen]'s [Theme] will also have the `platform` of the simulated device.
///
/// Using the [DeviceFrame.identifier] constructor will load an
/// svg file from assets first to get device frame visuals, but also
/// device info.
///
/// To preload the info, the [DeviceFrame.info] constructor can be
/// used instead.
///
/// See also:
///
/// * [Devices] to get all available devices.
///
class DeviceFrame extends StatelessWidget {
  /// The screen that should be inserted into the simulated
  /// device.
  ///
  /// It is cropped with the device screen shape and its size
  /// is the [info]'s screensize.
  final Widget screen;

  /// All information related to the device.
  final DeviceInfo device;

  /// The current frame simulated orientation.
  ///
  /// It will also affect the media query.
  final Orientation orientation;

  /// Indicates whether the device frame is visible, else
  /// only the screen is displayed.
  final bool isFrameVisible;

  /// Displays the given [screen] into the given [info]
  /// simulated device.
  ///
  /// The orientation of the device can be updated if the frame supports
  /// it (else it is ignored).
  ///
  /// If [isFrameVisible] is `true`, only the [screen] is displayed, but clipped with
  /// the device screen shape.
  const DeviceFrame({
    super.key,
    required this.device,
    required this.screen,
    this.orientation = Orientation.portrait,
    this.isFrameVisible = true,
  });

  /// Creates a [MediaQuery] from the given device [info], and for the current device [orientation].
  ///
  /// All properties that are not simulated are inherited from the current [context]'s inherited [MediaQuery].
  static MediaQueryData mediaQuery({
    required BuildContext context,
    required DeviceInfo? info,
    required Orientation orientation,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final isRotated = info?.isLandscape(orientation) ?? false;
    final viewPadding = isRotated
        ? (info?.rotatedSafeAreas ?? info?.safeAreas)
        : (info?.safeAreas ?? mediaQuery.padding);

    final screenSize = info != null ? info.screenSize : mediaQuery.size;
    final width = isRotated ? screenSize.height : screenSize.width;
    final height = isRotated ? screenSize.width : screenSize.height;

    return mediaQuery.copyWith(
      size: Size(width, height),
      padding: viewPadding,
      viewInsets: EdgeInsets.zero,
      viewPadding: viewPadding,
      devicePixelRatio: info?.pixelRatio ?? mediaQuery.devicePixelRatio,
    );
  }

  ThemeData _theme(BuildContext context) {
    final density = [
      DeviceType.desktop,
      DeviceType.laptop,
    ].contains(device.identifier.type)
        ? VisualDensity.compact
        : null;
    return Theme.of(context).copyWith(
      platform: device.identifier.platform,
      visualDensity: density,
    );
  }

  /// Whether we have a dedicated landscape PNG for the current orientation.
  bool get _hasLandscapePng =>
      device.isLandscape(orientation) && device.landscapeFrameAssetPath != null;

  Widget _screen(BuildContext context, DeviceInfo? info) {
    final mediaQuery = MediaQuery.of(context);
    final isRotated = info?.isLandscape(orientation) ?? false;
    final screenSize = info != null ? info.screenSize : mediaQuery.size;
    final width = isRotated ? screenSize.height : screenSize.width;
    final height = isRotated ? screenSize.width : screenSize.height;

    // When a dedicated landscape PNG frame is used, the frame image is already
    // landscape-oriented so we must NOT rotate the screen content.
    final shouldRotateScreen = isRotated && !_hasLandscapePng;

    return RotatedBox(
      quarterTurns: shouldRotateScreen ? 1 : 0,
      child: SizedBox(
        width: width,
        height: height,
        child: MediaQuery(
          data: DeviceFrame.mediaQuery(
            info: info,
            orientation: orientation,
            context: context,
          ),
          child: Theme(
            data: _theme(context),
            child: screen,
          ),
        ),
      ),
    );
  }

  /// Resolves the correct frame asset path for the current orientation.
  String? _resolveFrameAssetPath() {
    final isRotated = device.isLandscape(orientation);
    if (isRotated && device.landscapeFrameAssetPath != null) {
      return device.landscapeFrameAssetPath;
    }
    return device.frameAssetPath;
  }

  Widget _buildFrame() {
    final assetPath = _resolveFrameAssetPath();
    if (assetPath != null) {
      return Image.asset(
        assetPath,
        key: ValueKey('${device.identifier}_$assetPath'),
        package: 'device_frame',
        filterQuality: FilterQuality.high,
      );
    }
    return CustomPaint(
      key: ValueKey(device.identifier),
      painter: device.framePainter,
    );
  }

  @override
  Widget build(BuildContext context) {
    final portraitFrameSize = device.frameSize;
    final portraitBounds = device.screenPath.getBounds();
    final isPngFrame = device.frameAssetPath != null;
    final isRotated = device.isLandscape(orientation);
    final landscapePng = _hasLandscapePng;

    // When using a dedicated landscape PNG, swap frame & screen dimensions
    // so FractionallySizedBox fractions match the landscape image.
    final frameSize = landscapePng
        ? Size(portraitFrameSize.height, portraitFrameSize.width)
        : portraitFrameSize;
    final bounds = landscapePng
        ? Rect.fromLTWH(
            portraitBounds.top,
            portraitBounds.left,
            portraitBounds.height,
            portraitBounds.width,
          )
        : portraitBounds;

    final Widget stack;

    if (isPngFrame &&
        isFrameVisible &&
        device.identifier.type == DeviceType.watch) {
      // ─── WATCH-SPECIFIC rendering ─────────────────────────────
      // Watches have bands creating asymmetric top/bottom margins.
      final leftFrac = portraitBounds.left / portraitFrameSize.width;
      final topFrac = portraitBounds.top / portraitFrameSize.height;
      final rightFrac = (portraitFrameSize.width - portraitBounds.right) /
          portraitFrameSize.width;
      final bottomFrac = (portraitFrameSize.height - portraitBounds.bottom) /
          portraitFrameSize.height;
      // Compute alignment for asymmetric margins (bands)
      final hMargin = leftFrac + rightFrac;
      final vMargin = topFrac + bottomFrac;
      final alignX = hMargin > 0 ? 2 * leftFrac / hMargin - 1 : 0.0;
      final alignY = vMargin > 0 ? 2 * topFrac / vMargin - 1 : 0.0;

      stack = Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(
            key: const Key('Screen'),
            child: FractionallySizedBox(
              alignment: Alignment(alignX, alignY),
              widthFactor: 1.0 - hMargin,
              heightFactor: 1.0 - vMargin,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cornerRadiusFrac = portraitBounds.width > 0
                      ? _extractCornerRadiusFraction(
                          device.screenPath,
                          portraitBounds,
                        )
                      : 0.0;
                  final radius = constraints.maxWidth * cornerRadiusFrac;
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(radius),
                    child: FittedBox(
                      fit: BoxFit.cover,
                      clipBehavior: Clip.hardEdge,
                      child: _screen(context, device),
                    ),
                  );
                },
              ),
            ),
          ),
          _buildFrame(),
        ],
      );
    } else if (isPngFrame && isFrameVisible) {
      // ─── NON-WATCH PNG rendering (iPhones, Macs) ──────────────
      // These have symmetric margins and matching aspect ratios.
      // When using a landscape PNG, we use swapped dimensions so
      // the fractions match the landscape frame.
      final leftFrac = bounds.left / frameSize.width;
      final topFrac = bounds.top / frameSize.height;
      final rightFrac = (frameSize.width - bounds.right) / frameSize.width;
      final bottomFrac = (frameSize.height - bounds.bottom) / frameSize.height;

      stack = Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(
            key: const Key('Screen'),
            child: FractionallySizedBox(
              alignment: Alignment.center,
              widthFactor: 1.0 - leftFrac - rightFrac,
              heightFactor: 1.0 - topFrac - bottomFrac,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cornerRadiusFrac = bounds.width > 0
                      ? _extractCornerRadiusFraction(
                          landscapePng
                              ? _swappedScreenPath(device.screenPath)
                              : device.screenPath,
                          bounds,
                        )
                      : 0.0;
                  final radius = constraints.maxWidth * cornerRadiusFrac;
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(radius),
                    child: FittedBox(
                      child: _screen(context, device),
                    ),
                  );
                },
              ),
            ),
          ),
          _buildFrame(),
        ],
      );
    } else {
      // Vector frame: existing approach (CustomPaint + ClipPath)
      stack = SizedBox(
        width: isFrameVisible ? frameSize.width : bounds.width,
        height: isFrameVisible ? frameSize.height : bounds.height,
        child: Stack(
          children: [
            if (isFrameVisible)
              Positioned.fill(
                key: const Key('frame'),
                child: _buildFrame(),
              ),
            Positioned(
              key: const Key('Screen'),
              left: isFrameVisible ? bounds.left : 0,
              top: isFrameVisible ? bounds.top : 0,
              width: bounds.width,
              height: bounds.height,
              child: ClipPath(
                clipper: _ScreenClipper(
                  device.screenPath,
                ),
                child: FittedBox(
                  child: _screen(context, device),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // When a landscape PNG is used, the frame is already landscape-oriented,
    // so skip the RotatedBox rotation.
    final shouldRotateFrame = isRotated && !landscapePng;

    return FittedBox(
      child: RotatedBox(
        quarterTurns: shouldRotateFrame ? -1 : 0,
        child: stack,
      ),
    );
  }

  /// Creates a landscape screen path by swapping x/y coordinates of the
  /// portrait screen path bounds. Used for corner radius extraction.
  static Path _swappedScreenPath(Path portraitPath) {
    final b = portraitPath.getBounds();
    return Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(b.top, b.left, b.height, b.width),
          Radius.circular(
            b.width > 0
                ? _extractCornerRadiusFraction(portraitPath, b) * b.width
                : 0,
          ),
        ),
      );
  }

  /// Extracts the corner radius as a fraction of screen width
  /// by probing the screenPath at the top-left corner diagonal.
  static double _extractCornerRadiusFraction(Path path, Rect bounds) {
    // Binary search: the point (left + d, top + d) is outside the RRect
    // when d < R * (1 - 1/√2), where R is the actual corner radius.
    double lo = 0, hi = bounds.width * 0.15;
    for (int i = 0; i < 20; i++) {
      final mid = (lo + hi) / 2;
      final testPoint = Offset(bounds.left + mid, bounds.top + mid);
      if (path.contains(testPoint)) {
        hi = mid;
      } else {
        lo = mid;
      }
    }
    final diagOffset = (lo + hi) / 2;
    // Correct for diagonal geometry: d = R * (1 - 1/√2)
    // So R = d / (1 - 1/√2) ≈ d × 3.414
    const correction = 1.0 - 0.7071067811865476; // 1 - 1/√2 ≈ 0.2929
    final actualRadius = diagOffset / correction;
    return bounds.width > 0 ? actualRadius / bounds.width : 0;
  }
}

class _ScreenClipper extends CustomClipper<Path> {
  const _ScreenClipper(this.path);

  final Path? path;

  @override
  Path getClip(Size size) {
    final path = (this.path ?? (Path()..addRect(Offset.zero & size)));
    final bounds = path.getBounds();
    var transform = Matrix4.translationValues(-bounds.left, -bounds.top, 0);

    return path.transform(transform.storage);
  }

  @override
  bool shouldReclip(_ScreenClipper oldClipper) {
    return oldClipper.path != path;
  }
}
