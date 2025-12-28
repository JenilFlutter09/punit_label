import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:get/get.dart';

import '../../constants/colors.dart';
import '../../constants/sizes.dart';
import '../../widgets/customAppBar.dart';
import 'barcodeController.dart';

class BarcodeScannerWidget extends StatelessWidget {
  final BarcodeController controller = Get.put(BarcodeController());

  BarcodeScannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cutOutWidth = size.width * 0.8;
    final cutOutHeight = size.height * 0.16;
    return Stack(
      children: [
        // Scanner camera
        MobileScanner(onDetect: controller.onDetect),
        //Container(height: Get.height, width: Get.width, color: Colors.grey),
        // Dark overlay with rectangular cutout
        Container(
          decoration: ShapeDecoration(
            shape: BarcodeScannerOverlay(
              borderColor: ColorsValue.primaryColor,
              cutOutWidth: cutOutWidth, // wide rectangle
              cutOutHeight: cutOutHeight, // not very tall
            ),
          ),
        ),
        // Laser animation
        ScannerLaser(cutOutWidth: cutOutWidth, cutOutHeight: cutOutHeight),
        // Show progress when paused
        Obx(() {
          if (!controller.isScanning.value) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 12),
                    Text(
                      "Processing...",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }
}

class ScannerLaser extends StatefulWidget {
  final double cutOutWidth;
  final double cutOutHeight;

  const ScannerLaser({
    super.key,
    required this.cutOutWidth,
    required this.cutOutHeight,
  });

  @override
  State<ScannerLaser> createState() => _ScannerLaserState();
}

class _ScannerLaserState extends State<ScannerLaser>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final cutOutRect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: widget.cutOutWidth,
      height: widget.cutOutHeight - Dimens.five,
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final yPos =
            cutOutRect.top +
            (cutOutRect.height * _controller.value); // animate top → bottom

        return Positioned(
          left: cutOutRect.left + Dimens.two,
          width: cutOutRect.width - Dimens.four,
          top: yPos - Dimens.thirtyFive,
          child: Container(height: 2, color: Colors.white.withOpacity(0.7)),
        );
      },
    );
  }
}

class BarcodeScannerOverlay extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final double borderLength;
  final double borderRadius;
  final double cutOutWidth;
  final double cutOutHeight;

  BarcodeScannerOverlay({
    required this.borderColor,
    this.borderWidth = 5.0,
    this.borderLength = 30.0,
    this.borderRadius = 8.0,
    required this.cutOutWidth,
    required this.cutOutHeight,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRect(rect);
  }

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection? textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius borderRadius = BorderRadius.zero,
  }) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    final cutOutRect = Rect.fromCenter(
      center: rect.center,
      width: cutOutWidth,
      height: cutOutHeight,
    );

    // Darken outside
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(rect),
        Path()..addRRect(
          RRect.fromRectXY(cutOutRect, this.borderRadius, this.borderRadius),
        ),
      ),
      paint,
    );

    // Border paint
    final borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke;

    // Draw corner borders
    final path = Path();

    // top-left
    path.moveTo(cutOutRect.left, cutOutRect.top + borderLength);
    path.lineTo(cutOutRect.left, cutOutRect.top);
    path.lineTo(cutOutRect.left + borderLength, cutOutRect.top);

    // top-right
    path.moveTo(cutOutRect.right - borderLength, cutOutRect.top);
    path.lineTo(cutOutRect.right, cutOutRect.top);
    path.lineTo(cutOutRect.right, cutOutRect.top + borderLength);

    // bottom-right
    path.moveTo(cutOutRect.right, cutOutRect.bottom - borderLength);
    path.lineTo(cutOutRect.right, cutOutRect.bottom);
    path.lineTo(cutOutRect.right - borderLength, cutOutRect.bottom);

    // bottom-left
    path.moveTo(cutOutRect.left + borderLength, cutOutRect.bottom);
    path.lineTo(cutOutRect.left, cutOutRect.bottom);
    path.lineTo(cutOutRect.left, cutOutRect.bottom - borderLength);

    canvas.drawPath(path, borderPaint);
  }

  @override
  ShapeBorder scale(double t) => this;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    // TODO: implement getInnerPath
    throw UnimplementedError();
  }
}