import 'package:flutter/material.dart';

enum AppLayoutBreakpoint { phone, tablet, expandedTablet }

class AppLayoutSpec {
  const AppLayoutSpec._({required this.width, required this.breakpoint});

  static const double phoneBreakpoint = 600;
  static const double expandedTabletBreakpoint = 980;

  final double width;
  final AppLayoutBreakpoint breakpoint;

  factory AppLayoutSpec.fromWidth(double width) {
    if (width >= expandedTabletBreakpoint) {
      return AppLayoutSpec._(
        width: width,
        breakpoint: AppLayoutBreakpoint.expandedTablet,
      );
    }
    if (width >= phoneBreakpoint) {
      return AppLayoutSpec._(
        width: width,
        breakpoint: AppLayoutBreakpoint.tablet,
      );
    }
    return AppLayoutSpec._(width: width, breakpoint: AppLayoutBreakpoint.phone);
  }

  bool get isPhone => breakpoint == AppLayoutBreakpoint.phone;
  bool get isTablet => breakpoint != AppLayoutBreakpoint.phone;
  bool get isExpandedTablet => breakpoint == AppLayoutBreakpoint.expandedTablet;

  double get pageHorizontalPadding {
    if (isExpandedTablet) return 28;
    if (isTablet) return 24;
    return 16;
  }

  double get pageVerticalPadding {
    if (isExpandedTablet) return 24;
    if (isTablet) return 20;
    return 14;
  }

  double get cardPadding {
    if (isExpandedTablet) return 20;
    if (isTablet) return 18;
    return 14;
  }

  double get sectionSpacing {
    if (isExpandedTablet) return 24;
    if (isTablet) return 20;
    return 14;
  }

  double get panelSpacing => isExpandedTablet ? 24 : 18;

  double get toolbarHeight {
    if (isExpandedTablet) return 76;
    if (isTablet) return 72;
    return 64;
  }

  double get appBarTitleFont {
    if (isExpandedTablet) return 24;
    if (isTablet) return 22;
    return 17;
  }

  double get contentMaxWidth {
    if (isExpandedTablet) return 1480;
    if (isTablet) return 1080;
    return double.infinity;
  }
}

extension AppLayoutContext on BuildContext {
  AppLayoutSpec get layoutSpec =>
      AppLayoutSpec.fromWidth(MediaQuery.sizeOf(this).width);
}
