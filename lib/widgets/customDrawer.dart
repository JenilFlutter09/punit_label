import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:punit_label/constants/enums.dart';
import 'package:punit_label/constants/app_layout.dart';
import 'package:punit_label/features/dashboard/dashboardController.dart';
import 'package:punit_label/features/dispatch/view/dispatchScreen.dart';
import 'package:punit_label/features/inward/view/inwardScreen.dart';
import 'package:punit_label/features/settings/settingsScreen.dart';

import '../constants/colors.dart';
import '../constants/styles.dart';
import '../features/tare/tareView.dart';

class CustomDrawer extends StatelessWidget {
  CustomDrawer({super.key});

  final DashboardController dashController = Get.find();

  @override
  Widget build(BuildContext context) {
    final layout = context.layoutSpec;
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final isHorizontalTablet =
        layout.isTablet && media.orientation == Orientation.landscape;
    final isMobile = layout.isPhone;
    final isTablet = layout.isTablet && !layout.isExpandedTablet;
    final drawerWidth = isMobile
        ? width * 0.75
        : isHorizontalTablet
        ? (width * 0.36).clamp(380.0, 460.0)
        : isTablet
        ? 320.0
        : 360.0;

    return Drawer(
      width: drawerWidth,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: ColoredBox(
          color: const Color(0xFFF7F9FC),
          child: Column(
            children: [
              _header(
                dashboardController: dashController,
                isHorizontalTablet: isHorizontalTablet,
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    isHorizontalTablet ? 18 : 12,
                    10,
                    isHorizontalTablet ? 18 : 12,
                    18,
                  ),
                  children: [
                    _sectionTitle('Navigation'),
                    const SizedBox(height: 8),
                    _navigationPanel(
                      context,
                      isHorizontalTablet: isHorizontalTablet,
                    ),
                    const SizedBox(height: 18),
                    _sectionTitle('Quick Controls'),
                    const SizedBox(height: 8),
                    _controlCard(
                      title: 'Tare Weight Configuration',
                      subtitle:
                          'Choose how tare values are applied during inward flows.',
                      child: Obx(
                        () => ThreeLevelSelector(
                          value: dashController.tareState.value,
                          isTablet: layout.isTablet,
                          onChanged: (state) {
                            dashController.tareState.value = state;
                            if (state == TareState.off) {
                              dashController
                                      .manualBatchWeights
                                      .manualTare
                                      .value =
                                  '0';
                              dashController.manualBatchWeights.tareCtrl.text =
                                  '0';
                              dashController
                                      .manualNonBatchWeights
                                      .manualTare
                                      .value =
                                  '0';
                              dashController
                                      .manualNonBatchWeights
                                      .tareCtrl
                                      .text =
                                  '0';
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _controlCard(
                      title: 'Printer Configuration',
                      subtitle:
                          'Switch between label and receipt printing modes.',
                      child: Obx(
                        () => TwoLevelSelector(
                          value: dashController.labelState.value,
                          isTablet: layout.isTablet,
                          onChanged: (state) {
                            dashController.labelState.value = state;
                            if (state == LabelState.Receipt) {
                              if (dashController.isPrinterConnected.value ==
                                  true) {
                                dashController.disconnectPrinter();
                              }
                              dashController.isLabelPrinterMode.value = false;
                            } else {
                              dashController.isLabelPrinterMode.value = true;
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _controlCard(
                      title: 'Tower Light Configuration',
                      subtitle:
                          'Keep the tower light ready for operator alerts.',
                      child: Obx(
                        () => TowerLevelSelector(
                          value: dashController.isTowerLight.value,
                          isTablet: layout.isTablet,
                          onChanged: (state) {
                            dashController.isTowerLight.value = state;
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navigationPanel(
    BuildContext context, {
    required bool isHorizontalTablet,
  }) {
    final items = [
      _DrawerNavItem(
        icon: Icons.archive,
        label: 'Inward',
        subtitle: 'Batch and non-batch inward',
        enabled: dashController.enableInward.value,
        onTap: () {
          Get.back();
          Get.to(() => InwardScreen());
        },
      ),
      _DrawerNavItem(
        icon: Icons.local_shipping,
        label: 'Dispatch',
        subtitle: 'Barcode dispatch session',
        enabled: dashController.enableDispatch.value,
        onTap: () {
          Get.back();
          Get.to(() => DispatchScreen());
        },
      ),
      _DrawerNavItem(
        icon: Icons.line_weight,
        label: 'Tare',
        subtitle: 'Tare product setup',
        onTap: () {
          Get.back();
          Get.to(() => AddTareProductsView());
        },
      ),
      _DrawerNavItem(
        icon: Icons.settings_rounded,
        label: 'Settings',
        subtitle: 'Labels and devices',
        onTap: () {
          Get.back();
          Get.to(() => SettingsScreen());
        },
      ),
    ];

    return Obx(() {
      if (isHorizontalTablet) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.28,
          ),
          itemBuilder: (context, index) => _NavigationCard(item: items[index]),
        );
      }

      return Column(
        children: [
          Row(
            children: items.take(3).map((item) {
              return DrawerQuickAction(
                icon: item.icon,
                label: item.label,
                enabled: item.enabled,
                onTap: item.onTap,
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          _menuTile(
            icon: items.last.icon,
            title: items.last.label,
            subtitle: items.last.subtitle,
            onTap: items.last.onTap,
          ),
        ],
      );
    });
  }

  Widget _controlCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ColorsValue.shadowColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08163A66),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Styles.blackBold14),
          const SizedBox(height: 4),
          Text(subtitle, style: Styles.black12),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  /// 🔹 Header
  Widget _header({
    required DashboardController dashboardController,
    required bool isHorizontalTablet,
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        isHorizontalTablet ? 22 : 16,
        isHorizontalTablet ? 18 : 14,
        isHorizontalTablet ? 22 : 16,
        isHorizontalTablet ? 18 : 12,
      ),
      width: Get.width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorsValue.primaryColor,
            ColorsValue.primaryColor.withValues(alpha: 0.88),
          ],
        ),
        borderRadius: const BorderRadius.only(topRight: Radius.circular(24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: isHorizontalTablet ? 32 : 30,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.person,
              size: isHorizontalTablet ? 36 : 34,
              color: ColorsValue.primaryColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Welcome',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: isHorizontalTablet ? 13 : 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dashboardController.userDetails.value?.name ?? 'User',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isHorizontalTablet ? 21 : 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dashboardController.userDetails.value?.companyCode ??
                      'Operator Console',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: isHorizontalTablet ? 13 : 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 Section title
  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
      child: Text(text.toUpperCase(), style: Styles.primaryBold14),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: ColorsValue.shadowColor),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: ColorsValue.primaryColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: ColorsValue.primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Styles.blackBold14),
                    const SizedBox(height: 4),
                    Text(subtitle, style: Styles.black12),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade500,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ThreeLevelSelector extends StatelessWidget {
  final TareState value;
  final ValueChanged<TareState> onChanged;
  final bool isTablet;

  const ThreeLevelSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isTablet ? 14 : 10,
        horizontal: isTablet ? 18 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _option(
            label: "OFF",
            level: TareState.off,
            selected: value == TareState.off,
          ),
          // Divider(),
          _option(
            label: "ON",
            level: TareState.on,
            selected: value == TareState.on,
          ),
          // Divider(),
          _option(
            label: "Barcode",
            level: TareState.barcode,
            selected: value == TareState.barcode,
          ),
        ],
      ),
    );
  }

  Widget _option({
    required String label,
    required TareState level,
    required bool selected,
  }) {
    return GestureDetector(
      onTap: () => onChanged(level),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 18 : 12,
          vertical: isTablet ? 8 : 6,
        ),
        decoration: BoxDecoration(
          color: selected
              ? ColorsValue.primaryColor.withValues(alpha: 0.8)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 18 : 14,
            fontWeight: FontWeight.w600,
            color: selected ? ColorsValue.whiteColor : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}

class TwoLevelSelector extends StatelessWidget {
  final LabelState value;
  final ValueChanged<LabelState> onChanged;
  final bool isTablet;

  const TwoLevelSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isTablet ? 14 : 10,
        horizontal: isTablet ? 18 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _option(
            label: "Label",
            level: LabelState.Label,
            selected: value == LabelState.Label,
          ),
          // Divider(),
          _option(
            label: "Receipt",
            level: LabelState.Receipt,
            selected: value == LabelState.Receipt,
          ),
        ],
      ),
    );
  }

  Widget _option({
    required String label,
    required LabelState level,
    required bool selected,
  }) {
    return GestureDetector(
      onTap: () => onChanged(level),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 18 : 12,
          vertical: isTablet ? 8 : 6,
        ),
        decoration: BoxDecoration(
          color: selected
              ? ColorsValue.primaryColor.withValues(alpha: 0.8)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 18 : 14,
            fontWeight: FontWeight.w600,
            color: selected ? ColorsValue.whiteColor : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}

class TowerLevelSelector extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isTablet;

  const TowerLevelSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isTablet ? 14 : 10,
        horizontal: isTablet ? 18 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _option(label: "ON", level: true, selected: value == true),
          _divider(),
          _option(label: "OFF", level: false, selected: value == false),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(height: 24, width: 1.5, color: Colors.grey.shade300);
  }

  Widget _option({
    required String label,
    required bool level,
    required bool selected,
  }) {
    return GestureDetector(
      onTap: () => onChanged(level),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 18 : 12,
          vertical: isTablet ? 8 : 6,
        ),
        decoration: BoxDecoration(
          color: selected
              ? ColorsValue.primaryColor.withValues(alpha: 0.8)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 18 : 14,
            fontWeight: FontWeight.w600,
            color: selected ? ColorsValue.whiteColor : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}

class DrawerQuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  const DrawerQuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: enabled
                  ? ColorsValue.primaryColor.withValues(alpha: 0.1)
                  : Colors.grey.shade200,
              child: Icon(
                icon,
                color: enabled ? ColorsValue.primaryColor : Colors.grey,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: enabled ? Colors.black87 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerNavItem {
  const _DrawerNavItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;
}

class _NavigationCard extends StatelessWidget {
  const _NavigationCard({required this.item});

  final _DrawerNavItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: item.enabled ? item.onTap : null,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: item.enabled
                  ? ColorsValue.shadowColor
                  : Colors.grey.shade300,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item.enabled
                      ? ColorsValue.primaryColor.withValues(alpha: 0.1)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  item.icon,
                  color: item.enabled ? ColorsValue.primaryColor : Colors.grey,
                ),
              ),
              const Spacer(),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: item.enabled ? Colors.black87 : Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.25,
                  color: item.enabled ? Colors.grey.shade700 : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
