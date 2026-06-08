import 'package:flutter/material.dart';

class ResponsiveHelper {
  static int getCrossAxisCount(BuildContext context, {int mobile = 1, int tablet = 2, int desktop = 4}) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return desktop;
    if (width > 800) return tablet + 1;
    if (width > 500) return tablet;
    return mobile;
  }

  static double getChildAspectRatio(BuildContext context, {double mobile = 1.6, double tablet = 1.8, double desktop = 1.5}) {
    final width = MediaQuery.of(context).size.width;
    if (width > 800) return desktop;
    if (width > 500) return tablet;
    return mobile;
  }

  static EdgeInsets getPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 600) return const EdgeInsets.all(28);
    if (width > 400) return const EdgeInsets.all(16);
    return const EdgeInsets.all(12);
  }

  static bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < 600;
  static bool isTablet(BuildContext context) => MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 1200;
  static bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= 1200;
}