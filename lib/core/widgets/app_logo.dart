import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 72});

  @override
  Widget build(BuildContext context) {
    final pixels = (size * MediaQuery.devicePixelRatioOf(context)).ceil();
    return Image.asset(
      size >= 128 ? AppConstants.largeLogoAsset : AppConstants.logoAsset,
      width: size,
      height: size,
      cacheWidth: pixels,
      cacheHeight: pixels,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: '${AppConstants.appName} logo',
    );
  }
}
