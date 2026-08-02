import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class ResponsiveUtils {
  const ResponsiveUtils._();

  static bool get isMobilePlatform {
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static bool isHandsetWidth(double width) {
    return isMobilePlatform && width < 600;
  }

  static bool isHandsetLandscape(Size size) {
    return isMobilePlatform && size.width > size.height;
  }

  static bool get isDesktopCardPlatform {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS);
  }
}
