import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    this.onPressed,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.borderRadius,
    this.padding,
    this.iconSize,
    this.elevation,
    this.shadowColor,
    this.text,
    this.textStyle,
    this.width,
    this.height,
  });

  // Optional customization parameters
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? iconSize;
  final double? elevation;
  final Color? shadowColor;
  final String? text;
  final TextStyle? textStyle;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: iconSize ?? 24,
          color: foregroundColor ?? Colors.white,
        ),
        iconAlignment: text != null ? IconAlignment.start : IconAlignment.start,
        label: text != null
            ? Text(
          text!,
          style: textStyle ??
              TextStyle(
                color: foregroundColor ?? Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
        )
            : const SizedBox.shrink(),

        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
          foregroundColor: foregroundColor ?? Colors.white,
          padding: padding ??
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 12),
            side: borderColor != null
                ? BorderSide(color: borderColor!)
                : BorderSide.none,
          ),
          elevation: elevation ?? 3,
          shadowColor: shadowColor ?? Colors.black45,
        ),
      ),
    );
  }
}
