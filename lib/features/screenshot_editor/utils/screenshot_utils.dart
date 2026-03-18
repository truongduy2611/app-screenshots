import 'dart:math' as math;
import 'package:device_frame/device_frame.dart';
import 'package:flutter/material.dart';
import '../data/models/screenshot_design.dart';

/// Utility for screenshot dimensions by device category.
class ScreenshotUtils {
  /// Standard App Store screenshot dimensions by display type.
  static const _dimensions = <String, List<Size>>{
    // iPhone
    'APP_IPHONE_69': [Size(1320, 2868)],
    'APP_IPHONE_67': [Size(1290, 2796)],
    'APP_IPHONE_65': [Size(1284, 2778), Size(1242, 2688)],
    'APP_IPHONE_61': [Size(1179, 2556)],
    'APP_IPHONE_58': [Size(1125, 2436)],
    'APP_IPHONE_55': [Size(1242, 2208)],
    'APP_IPHONE_47': [Size(750, 1334)],
    'APP_IPHONE_40': [Size(640, 1136)],
    'APP_IPHONE_35': [Size(640, 960)],
    // iPad
    'APP_IPAD_PRO_3GEN_129': [Size(2048, 2732)],
    'APP_IPAD_PRO_3GEN_11': [Size(1668, 2388)],
    'APP_IPAD_PRO_129': [Size(2048, 2732)],
    'APP_IPAD_105': [Size(1668, 2224)],
    'APP_IPAD_97': [Size(1536, 2048)],
    // Mac
    'APP_DESKTOP': [Size(2880, 1800), Size(1280, 800)],
    // Apple TV
    'APP_APPLE_TV': [Size(3840, 2160), Size(1920, 1080)],
    // Watch
    'APP_WATCH_ULTRA': [Size(410, 502)],
    'APP_WATCH_S11_46MM': [Size(416, 496)],
    'APP_WATCH_S11_42MM': [Size(374, 446)],
    // Android / Google Play
    'ANDROID_PHONE': [Size(1080, 2400)],
    'ANDROID_PHONE_1080': [Size(1080, 1920)],
    'ANDROID_TABLET_7': [Size(1200, 1920)],
    'ANDROID_TABLET_10': [Size(1600, 2560)],
    // X / Twitter
    'TWITTER_POST': [Size(1200, 675)],
    'TWITTER_HEADER': [Size(1500, 500)],
    'TWITTER_CARD': [Size(800, 418)],
    // Instagram
    'INSTAGRAM_SQUARE': [Size(1080, 1080)],
    'INSTAGRAM_PORTRAIT': [Size(1080, 1350)],
    'INSTAGRAM_STORY': [Size(1080, 1920)],
    'INSTAGRAM_LANDSCAPE': [Size(1080, 566)],
    // Facebook
    'FACEBOOK_POST': [Size(1200, 630)],
    'FACEBOOK_COVER': [Size(1640, 924)],
    'FACEBOOK_STORY': [Size(1080, 1920)],
    // LinkedIn
    'LINKEDIN_POST': [Size(1200, 627)],
    'LINKEDIN_COVER': [Size(1584, 396)],
    // YouTube
    'YOUTUBE_THUMBNAIL': [Size(1280, 720)],
    'YOUTUBE_BANNER': [Size(2560, 1440)],
    // TikTok
    'TIKTOK_VIDEO': [Size(1080, 1920)],
    // Threads
    'THREADS_POST': [Size(1080, 1350)],
    // Generic
    'GENERIC_SQUARE': [Size(1080, 1080)],
    'GENERIC_16_9': [Size(1920, 1080)],
    'GENERIC_4K': [Size(3840, 2160)],
    'GENERIC_ULTRAWIDE': [Size(2560, 1080)],
  };

  static Size getDimensions(String displayType, Orientation orientation) {
    if (orientation == Orientation.landscape) {
      final size = _getPrimaryDimension(displayType);
      return Size(size.height, size.width);
    }
    return _getPrimaryDimension(displayType);
  }

  static Size _getPrimaryDimension(String displayType) {
    final dims = _dimensions[displayType];
    if (dims != null && dims.isNotEmpty) {
      return dims.first;
    }
    return const Size(1290, 2796); // Default: iPhone 16 Pro Max
  }

  static List<Size> getSupportedDimensions(String displayType) {
    return _dimensions[displayType] ?? [const Size(1290, 2796)];
  }

  /// All display type keys from the dimensions map.
  static List<String> get allDisplayTypes => _dimensions.keys.toList();

  static DeviceCategory getDeviceCategory(String displayType) {
    if (displayType.startsWith('APP_IPHONE')) return DeviceCategory.iphone;
    if (displayType.startsWith('APP_IPAD')) return DeviceCategory.ipad;
    if (displayType.startsWith('APP_WATCH')) return DeviceCategory.watch;
    if (displayType.startsWith('APP_DESKTOP')) return DeviceCategory.mac;
    if (displayType.startsWith('APP_APPLE_TV')) return DeviceCategory.tv;
    if (displayType.startsWith('ANDROID')) return DeviceCategory.android;
    if (displayType.startsWith('TWITTER')) return DeviceCategory.twitter;
    if (displayType.startsWith('INSTAGRAM')) return DeviceCategory.instagram;
    if (displayType.startsWith('FACEBOOK')) return DeviceCategory.facebook;
    if (displayType.startsWith('LINKEDIN')) return DeviceCategory.linkedin;
    if (displayType.startsWith('YOUTUBE')) return DeviceCategory.youtube;
    if (displayType.startsWith('TIKTOK')) return DeviceCategory.tiktok;
    if (displayType.startsWith('THREADS')) return DeviceCategory.threads;
    if (displayType.startsWith('GENERIC')) return DeviceCategory.generic;
    return DeviceCategory.iphone;
  }

  /// Human-readable labels for each display type key.
  static const _friendlyNames = <String, String>{
    'APP_IPHONE_69': 'iPhone 6.9"',
    'APP_IPHONE_67': 'iPhone 6.7"',
    'APP_IPHONE_65': 'iPhone 6.5"',
    'APP_IPHONE_61': 'iPhone 6.1"',
    'APP_IPHONE_58': 'iPhone 5.8"',
    'APP_IPHONE_55': 'iPhone 5.5"',
    'APP_IPHONE_47': 'iPhone 4.7"',
    'APP_IPHONE_40': 'iPhone 4"',
    'APP_IPHONE_35': 'iPhone 3.5"',
    'APP_IPAD_PRO_3GEN_129': 'iPad Pro 12.9"',
    'APP_IPAD_PRO_3GEN_11': 'iPad Pro 11"',
    'APP_IPAD_PRO_129': 'iPad Pro 12.9"',
    'APP_IPAD_105': 'iPad 10.5"',
    'APP_IPAD_97': 'iPad 9.7"',
    'APP_DESKTOP': 'Mac',
    'APP_APPLE_TV': 'Apple TV',
    'APP_WATCH_ULTRA': 'Watch Ultra',
    'APP_WATCH_S11_46MM': 'Watch 46mm',
    'APP_WATCH_S11_42MM': 'Watch 42mm',
    'ANDROID_PHONE': 'Android Phone',
    'ANDROID_PHONE_1080': 'Android Phone',
    'ANDROID_TABLET_7': 'Android Tablet 7"',
    'ANDROID_TABLET_10': 'Android Tablet 10"',
    'TWITTER_POST': 'Twitter Post',
    'TWITTER_HEADER': 'Twitter Header',
    'TWITTER_CARD': 'Twitter Card',
    'INSTAGRAM_SQUARE': 'Square Post',
    'INSTAGRAM_PORTRAIT': 'Portrait Post',
    'INSTAGRAM_STORY': 'Story / Reel',
    'INSTAGRAM_LANDSCAPE': 'Landscape Post',
    'FACEBOOK_POST': 'Post Image',
    'FACEBOOK_COVER': 'Cover Photo',
    'FACEBOOK_STORY': 'Story',
    'LINKEDIN_POST': 'Post Image',
    'LINKEDIN_COVER': 'Cover Banner',
    'YOUTUBE_THUMBNAIL': 'Thumbnail',
    'YOUTUBE_BANNER': 'Channel Banner',
    'TIKTOK_VIDEO': 'Video Cover',
    'THREADS_POST': 'Post Image',
    'GENERIC_SQUARE': 'Square (1:1)',
    'GENERIC_16_9': 'FHD (16:9)',
    'GENERIC_4K': '4K (16:9)',
    'GENERIC_ULTRAWIDE': 'Ultrawide (21:9)',
  };

  /// Returns a human-readable name for a display type key.
  static String friendlyDisplayName(String? displayType) {
    if (displayType == null || displayType.isEmpty) return 'Design';
    return _friendlyNames[displayType] ?? 'Design';
  }

  static const _monthAbbr = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// Generates a default design name including the device type and a short
  /// date-time suffix, e.g. "iPhone 6.7\" Design · Feb 21, 12:09".
  static String defaultDesignName(String? displayType) {
    final now = DateTime.now();
    final suffix =
        '${_monthAbbr[now.month - 1]} ${now.day}, '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final friendly = friendlyDisplayName(displayType);
    if (friendly == 'Design') return 'Design · $suffix';
    return '$friendly Design · $suffix';
  }

  /// Clones a design to a new format, scaling its coordinates and properties proportionally.
  static ScreenshotDesign cloneDesignToFormat(
    ScreenshotDesign original,
    String newDisplayType,
  ) {
    if (original.displayType == newDisplayType) {
      return original;
    }

    final originalDims = getDimensions(
      original.displayType ?? 'APP_IPHONE_69',
      original.orientation,
    );
    final newDims = getDimensions(newDisplayType, original.orientation);

    final scaleX = newDims.width / originalDims.width;
    final scaleY = newDims.height / originalDims.height;
    // We typically want to scale things like font sizes by the diagonal or a primary axis,
    // but scaling by the minimum of scaleX and scaleY often looks better so text doesn't overflow.
    final scaleP = math.min(scaleX, scaleY);

    // 1. Scale image overlays
    final newImageOverlays = original.imageOverlays.map((io) {
      return io.copyWith(
        position: Offset(io.position.dx * scaleX, io.position.dy * scaleY),
        width: io.width * scaleX,
        height: io.height * scaleY,
        cornerRadius: io.cornerRadius * scaleP,
        shadowOffset: Offset(
          io.shadowOffset.dx * scaleP,
          io.shadowOffset.dy * scaleP,
        ),
        shadowBlurRadius: io.shadowBlurRadius * scaleP,
      );
    }).toList();

    // 2. Scale text overlays
    final newTextOverlays = original.overlays.map((to) {
      return to.copyWith(
        position: Offset(to.position.dx * scaleX, to.position.dy * scaleY),
        style: to.style.copyWith(fontSize: (to.style.fontSize ?? 20) * scaleP),
        // We won't automatically scale constraints to not break auto-wrap too aggressively,
        // but it could be scaled if necessary. Let's scale width.
        width: to.width != null ? to.width! * scaleX : null,
      );
    }).toList();

    // 3. Scale icon overlays
    final newIconOverlays = original.iconOverlays.map((io) {
      return io.copyWith(
        position: Offset(io.position.dx * scaleX, io.position.dy * scaleY),
        size: io.size * scaleP,
        shadowOffset: Offset(
          io.shadowOffset.dx * scaleP,
          io.shadowOffset.dy * scaleP,
        ),
        shadowBlurRadius: io.shadowBlurRadius * scaleP,
      );
    }).toList();

    // 4. Scale magnifier overlays
    final newMagnifierOverlays = original.magnifierOverlays.map((mo) {
      return mo.copyWith(
        position: Offset(mo.position.dx * scaleX, mo.position.dy * scaleY),
        width: mo.width * scaleP,
        height: mo.height * scaleP,
        borderWidth: mo.borderWidth * scaleP,
        shadowBlurRadius: mo.shadowBlurRadius * scaleP,
        sourceOffset: Offset(
          mo.sourceOffset.dx * scaleX,
          mo.sourceOffset.dy * scaleY,
        ),
      );
    }).toList();

    // 5. Scale main image and padding
    final newPadding = original.padding * scaleP;
    final newImagePosition = Offset(
      original.imagePosition.dx * scaleX,
      original.imagePosition.dy * scaleY,
    );

    return original.copyWith(
      displayType: newDisplayType,
      overlays: newTextOverlays,
      imageOverlays: newImageOverlays,
      iconOverlays: newIconOverlays,
      magnifierOverlays: newMagnifierOverlays,
      padding: newPadding,
      imagePosition: newImagePosition,
      // Set the correct device frame for the new display type.
      deviceFrame: getDefaultDeviceFrame(newDisplayType),
    );
  }

  /// Returns the default [DeviceInfo] for a given display type string.
  static DeviceInfo getDefaultDeviceFrame(String? displayType) {
    if (displayType == null) return Devices.ios.iPhone17ProMax;
    final lowerType = displayType.toLowerCase();
    if (lowerType.contains('ipad')) {
      return Devices.ios.iPadPro13InchesM4;
    }
    if (lowerType.contains('desktop')) {
      return Devices.macOS.macBookPro14M4;
    }
    if (displayType == 'APP_WATCH_ULTRA') {
      return Devices.watch.watchUltra3;
    }
    if (displayType == 'APP_WATCH_S11_46MM') {
      return Devices.watch.watchS11_46mm;
    }
    if (lowerType.contains('watch')) {
      return Devices.watch.watchS11_42mm;
    }
    if (lowerType.contains('iphone')) {
      return _getIPhoneFrame(displayType);
    }
    return Devices.ios.iPhone17ProMax;
  }

  static DeviceInfo _getIPhoneFrame(String displayType) {
    switch (displayType) {
      case 'APP_IPHONE_69':
        return Devices.ios.iPhone17ProMax;
      case 'APP_IPHONE_67':
        return Devices.ios.iPhone16ProMax;
      case 'APP_IPHONE_65':
        return Devices.ios.iPhone16Plus;
      case 'APP_IPHONE_61':
        return Devices.ios.iPhone16;
      case 'APP_IPHONE_58':
        return Devices.ios.iPhone13ProMax;
      case 'APP_IPHONE_55':
        return Devices.ios.iPhone11ProMax;
      case 'APP_IPHONE_47':
      case 'APP_IPHONE_40':
      case 'APP_IPHONE_35':
        return Devices.ios.iPhoneSE;
      default:
        return Devices.ios.iPhone17ProMax;
    }
  }
}

enum DeviceCategory {
  iphone,
  ipad,
  watch,
  mac,
  tv,
  android,
  twitter,
  instagram,
  facebook,
  linkedin,
  youtube,
  tiktok,
  threads,
  generic,
}
