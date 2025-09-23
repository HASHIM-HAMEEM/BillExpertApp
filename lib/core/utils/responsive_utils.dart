import 'package:flutter/material.dart';

/// Responsive utilities for handling different screen sizes and orientations
class ResponsiveUtils {
  // Breakpoints for different screen sizes
  static const double mobileMaxWidth = 600;
  static const double tabletMinWidth = 601;
  static const double tabletMaxWidth = 1024;
  static const double desktopMinWidth = 1025;

  // Screen type detection
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < tabletMinWidth;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= tabletMinWidth && width <= tabletMaxWidth;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width > tabletMaxWidth;
  }

  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  // Responsive sizing functions
  static double responsiveWidth(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.width * (percentage / 100);
  }

  static double responsiveHeight(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.height * (percentage / 100);
  }

  static double responsiveFontSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = screenWidth / 375.0; // Base width for iPhone 6/7/8
    return baseSize * scaleFactor.clamp(0.8, 2.0);
  }

  // Spacing utilities
  static EdgeInsets responsivePadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(16);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(24);
    } else {
      return const EdgeInsets.all(32);
    }
  }

  static EdgeInsets responsiveHorizontalPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.symmetric(horizontal: 16);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 32);
    } else {
      return const EdgeInsets.symmetric(horizontal: 48);
    }
  }

  static EdgeInsets responsiveVerticalPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.symmetric(vertical: 16);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(vertical: 24);
    } else {
      return const EdgeInsets.symmetric(vertical: 32);
    }
  }

  // Grid utilities
  static int responsiveGridCrossAxisCount(BuildContext context, {
    int mobile = 1,
    int tablet = 2,
    int desktop = 3,
  }) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return desktop;
    }
  }

  static double responsiveGridAspectRatio(BuildContext context, {
    double mobile = 1.0,
    double tablet = 1.2,
    double desktop = 1.5,
  }) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return desktop;
    }
  }

  // Container sizing
  static double responsiveCardWidth(BuildContext context, {
    double mobile = double.infinity,
    double tablet = 400,
    double desktop = 500,
  }) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return desktop;
    }
  }

  // Layout utilities
  static Widget responsiveBuilder({
    required BuildContext context,
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile;
    } else {
      return desktop ?? tablet ?? mobile;
    }
  }

  // App bar height
  static double responsiveAppBarHeight(BuildContext context) {
    if (isMobile(context)) {
      return kToolbarHeight;
    } else {
      return kToolbarHeight + 8;
    }
  }

  // Bottom navigation height
  static double responsiveBottomNavHeight(BuildContext context) {
    if (isMobile(context)) {
      return 80;
    } else {
      return 90;
    }
  }

  // Safe area handling
  static EdgeInsets responsiveSafeArea(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  // Dialog sizing
  static Size responsiveDialogSize(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    if (isMobile(context)) {
      return Size(screenSize.width * 0.9, screenSize.height * 0.7);
    } else if (isTablet(context)) {
      return Size(screenSize.width * 0.7, screenSize.height * 0.8);
    } else {
      return Size(600, 800);
    }
  }

  // Button sizing
  static Size responsiveButtonSize(BuildContext context, {
    double mobileWidth = double.infinity,
    double mobileHeight = 50,
    double tabletWidth = 200,
    double tabletHeight = 56,
    double desktopWidth = 250,
    double desktopHeight = 60,
  }) {
    if (isMobile(context)) {
      return Size(mobileWidth, mobileHeight);
    } else if (isTablet(context)) {
      return Size(tabletWidth, tabletHeight);
    } else {
      return Size(desktopWidth, desktopHeight);
    }
  }

  // Text field sizing
  static double responsiveTextFieldHeight(BuildContext context) {
    if (isMobile(context)) {
      return 48;
    } else {
      return 56;
    }
  }

  // Icon sizing
  static double responsiveIconSize(BuildContext context, {
    double mobile = 20,
    double tablet = 24,
    double desktop = 28,
  }) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return desktop;
    }
  }

  // Card elevation
  static double responsiveCardElevation(BuildContext context) {
    if (isMobile(context)) {
      return 2;
    } else {
      return 4;
    }
  }

  // Border radius
  static double responsiveBorderRadius(BuildContext context, {
    double mobile = 8,
    double tablet = 12,
    double desktop = 16,
  }) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return desktop;
    }
  }

  // Animation durations (slower on mobile for better UX)
  static Duration responsiveAnimationDuration(BuildContext context) {
    if (isMobile(context)) {
      return const Duration(milliseconds: 300);
    } else {
      return const Duration(milliseconds: 200);
    }
  }
}

/// Extension methods for easier responsive design
extension ResponsiveExtensions on BuildContext {
  bool get isMobile => ResponsiveUtils.isMobile(this);
  bool get isTablet => ResponsiveUtils.isTablet(this);
  bool get isDesktop => ResponsiveUtils.isDesktop(this);
  bool get isLandscape => ResponsiveUtils.isLandscape(this);
  bool get isPortrait => ResponsiveUtils.isPortrait(this);

  double responsiveWidth(double percentage) => ResponsiveUtils.responsiveWidth(this, percentage);
  double responsiveHeight(double percentage) => ResponsiveUtils.responsiveHeight(this, percentage);
  double responsiveFontSize(double baseSize) => ResponsiveUtils.responsiveFontSize(this, baseSize);

  EdgeInsets get responsivePadding => ResponsiveUtils.responsivePadding(this);
  EdgeInsets get responsiveHorizontalPadding => ResponsiveUtils.responsiveHorizontalPadding(this);
  EdgeInsets get responsiveVerticalPadding => ResponsiveUtils.responsiveVerticalPadding(this);

  Size get responsiveDialogSize => ResponsiveUtils.responsiveDialogSize(this);
  double get responsiveTextFieldHeight => ResponsiveUtils.responsiveTextFieldHeight(this);
  double responsiveIconSize({double mobile = 20, double tablet = 24, double desktop = 28}) =>
      ResponsiveUtils.responsiveIconSize(this, mobile: mobile, tablet: tablet, desktop: desktop);
  double responsiveBorderRadius({double mobile = 8, double tablet = 12, double desktop = 16}) =>
      ResponsiveUtils.responsiveBorderRadius(this, mobile: mobile, tablet: tablet, desktop: desktop);
  Duration get responsiveAnimationDuration => ResponsiveUtils.responsiveAnimationDuration(this);
}

/// Responsive Layout Builder Widget
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveUtils.responsiveBuilder(
      context: context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
}

/// Responsive Grid Widget
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int mobileCrossAxisCount;
  final int tabletCrossAxisCount;
  final int desktopCrossAxisCount;
  final double mobileAspectRatio;
  final double tabletAspectRatio;
  final double desktopAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileCrossAxisCount = 1,
    this.tabletCrossAxisCount = 2,
    this.desktopCrossAxisCount = 3,
    this.mobileAspectRatio = 1.0,
    this.tabletAspectRatio = 1.2,
    this.desktopAspectRatio = 1.5,
    this.crossAxisSpacing = 16,
    this.mainAxisSpacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = ResponsiveUtils.responsiveGridCrossAxisCount(
          context,
          mobile: mobileCrossAxisCount,
          tablet: tabletCrossAxisCount,
          desktop: desktopCrossAxisCount,
        );

        final aspectRatio = ResponsiveUtils.responsiveGridAspectRatio(
          context,
          mobile: mobileAspectRatio,
          tablet: tabletAspectRatio,
          desktop: desktopAspectRatio,
        );

        return GridView.count(
          crossAxisCount: crossAxisCount,
          childAspectRatio: aspectRatio,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: children,
        );
      },
    );
  }
}
