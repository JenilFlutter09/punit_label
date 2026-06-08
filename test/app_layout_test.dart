import 'package:flutter_test/flutter_test.dart';
import 'package:punit_label/constants/app_layout.dart';

void main() {
  group('AppLayoutSpec', () {
    test('uses phone breakpoint below 600', () {
      final spec = AppLayoutSpec.fromWidth(390);

      expect(spec.breakpoint, AppLayoutBreakpoint.phone);
      expect(spec.isPhone, isTrue);
      expect(spec.isTablet, isFalse);
      expect(spec.isExpandedTablet, isFalse);
    });

    test('uses tablet breakpoint from 600 to 979', () {
      final spec = AppLayoutSpec.fromWidth(800);

      expect(spec.breakpoint, AppLayoutBreakpoint.tablet);
      expect(spec.isPhone, isFalse);
      expect(spec.isTablet, isTrue);
      expect(spec.isExpandedTablet, isFalse);
    });

    test('uses expanded tablet breakpoint from 980 up', () {
      final spec = AppLayoutSpec.fromWidth(1180);

      expect(spec.breakpoint, AppLayoutBreakpoint.expandedTablet);
      expect(spec.isPhone, isFalse);
      expect(spec.isTablet, isTrue);
      expect(spec.isExpandedTablet, isTrue);
    });
  });
}
