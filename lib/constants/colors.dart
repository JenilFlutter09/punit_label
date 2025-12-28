// coverage:ignore-file
import 'package:flutter/material.dart';

/// A list of custom color used in the application.
///
/// Will be ignored for test since all are static values and would not change.
abstract class ColorsValue {
  /// Colors
  static Color primaryColor = Color.fromRGBO(32, 66, 114, 1);
  //static Color primaryBlueColor = Color.fromRGBO(46, 80, 107, 1);
  static Color primaryGrey = const Color(0xFFED936E);
  static Color lightprimary = const Color(0xFF0D8798);
  static Color liked = const Color(0xFFDA062E);

  static Color secondaryColor = Colors.grey.shade300;
  static Color whiteColor = Colors.white;

  static Color scaffoldBackgroundColor = Colors.white;

  static Color hintTextColor = const Color(0xFF9498B4);

  static const Color shadowColor = Color(0xFFDDE3FD);

  static const Color calendarDateColor = Color(0xFFEEF1FF);

  static const Color calendarDateBorderColor = Color(0xFFC6CFFF);

  static const Color greyDividerColor = Color(0xFFAEB2CE);

  static const Color expansionColor = Color(0xFFE8EAFF);

  static const Color transparent = Colors.transparent;
}
