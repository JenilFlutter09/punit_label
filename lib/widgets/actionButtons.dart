import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:punit_label/features/inward/batchWise/batchInwardController.dart';

import '../constants/enums.dart';

/// Professional, Animated & Reusable Action Bar for Inward/Dispatch
class InwardActionBar extends StatelessWidget {
  final BatchInwardController controller;
  final bool isTablet;
  final BuildContext context;
  const InwardActionBar({
    super.key,
    required this.controller,
    required this.isTablet,
    required this.context,
  });

  // Define button config based on state
  List<_ActionButtonConfig> _getButtons() {
    final bool isAutoEnabled = controller.isBatchAutoWeightEnabled.value;

    if (!isAutoEnabled) {
      final IconData mainIcon =
          controller.inwardState.value == InwardState.running
          ? Icons.pause_circle_filled
          : Icons.play_circle_filled;

      final Color mainColor =
          controller.inwardState.value == InwardState.running
          ? Colors.orange
          : Colors.green;

      final String mainLabel =
          controller.inwardState.value == InwardState.running
          ? "Pause"
          : (controller.inwardState.value == InwardState.paused
                ? "Resume"
                : "Start Auto");
      return [
        _ActionButtonConfig(
          icon: Icons.add_circle,
          color: Colors.blueAccent,
          label: "Add Entry",
          onTap: () async => await controller.addToList(),
        ),
        if (controller.isCustomTemplateSelected)
          _ActionButtonConfig(
            icon: Icons.visibility,
            color: Colors.teal,
            label: "Preview",
            onTap: () => controller.previewCurrentLabel(context),
          ),
        _ActionButtonConfig(
          icon: mainIcon,
          color: mainColor,
          label: mainLabel,
          onTap: () async {
            if (controller.inwardState.value == InwardState.running) {
              await controller.onTapMain();
            }
          },
        ),
        // _ActionButtonConfig(
        //   icon: Icons.picture_as_pdf,
        //   color: ColorsValue.primaryColor,
        //   label: "Generate PDF",
        //   onTap: ()=>controller.onTapPdf(context),
        // ),
        _ActionButtonConfig(
          icon: Icons.stop,
          color: Colors.red,
          label: "Stop",
          onTap: controller.onTapStop,
        ),
      ];
    }

    // Auto mode: Dynamic play/pause based on state
    final IconData mainIcon =
        controller.inwardState.value == InwardState.running
        ? Icons.pause_circle_filled
        : Icons.play_circle_filled;

    final Color mainColor = controller.inwardState.value == InwardState.running
        ? Colors.orange
        : Colors.green;

    final String mainLabel = controller.inwardState.value == InwardState.running
        ? "Pause"
        : (controller.inwardState.value == InwardState.paused
              ? "Resume"
              : "Start Auto");

    return [
      if (controller.isCustomTemplateSelected)
        _ActionButtonConfig(
          icon: Icons.visibility,
          color: Colors.teal,
          label: "Preview",
          onTap: () => controller.previewCurrentLabel(context),
        ),
      _ActionButtonConfig(
        icon: mainIcon,
        color: mainColor,
        label: mainLabel,
        onTap: controller.onTapMain,
        pulse:
            controller.inwardState.value ==
            InwardState.running, // Pulse when running
      ),
      // _ActionButtonConfig(
      //   icon: Icons.picture_as_pdf,
      //   color: ColorsValue.primaryColor,
      //   label: "PDF",
      //   onTap: ()=>controller.onTapPdf(context),
      // ),
      _ActionButtonConfig(
        icon: Icons.stop_circle,
        color: Colors.red,
        label: "Stop",
        onTap: controller.onTapStop,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final buttons = _getButtons();

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: buttons.map((config) {
          return AnimatedScaleButton(
            icon: config.icon,
            color: config.color,
            label: config.label,
            isTablet: isTablet,
            onTap: config.onTap,
            pulse: config.pulse,
          );
        }).toList(),
      );
    });
  }
}

// Config class
class _ActionButtonConfig {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  final bool pulse;

  _ActionButtonConfig({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    this.pulse = false,
  });
}

class AnimatedScaleButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final bool isTablet;
  final VoidCallback onTap;
  final bool pulse;

  const AnimatedScaleButton({
    Key? key,
    required this.icon,
    required this.color,
    required this.label,
    required this.isTablet,
    required this.onTap,
    this.pulse = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double size = isTablet ? 72 : 60;
    final double iconSize = isTablet ? 36 : 30;
    final double fontSize = isTablet ? 14 : 12;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: pulse
              ? _PulsingButton(
                  size: size,
                  iconSize: iconSize,
                  icon: icon,
                  color: color,
                  onTap: onTap,
                )
              : _StaticButton(
                  size: size,
                  iconSize: iconSize,
                  icon: icon,
                  color: color,
                  onTap: onTap,
                ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}

// Pulsing effect when auto-weighing is running
class _PulsingButton extends StatefulWidget {
  final double size;
  final double iconSize;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PulsingButton({
    required this.size,
    required this.iconSize,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_PulsingButton> createState() => _PulsingButtonState();
}

class _PulsingButtonState extends State<_PulsingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.18,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: _StaticButton(
            size: widget.size,
            iconSize: widget.iconSize,
            icon: widget.icon,
            color: widget.color,
            onTap: widget.onTap,
          ),
        );
      },
    );
  }
}

// Reusable static FAB-style button
class _StaticButton extends StatelessWidget {
  final double size;
  final double iconSize;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StaticButton({
    required this.size,
    required this.iconSize,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(size / 2),
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: iconSize),
        ),
      ),
    );
  }
}
