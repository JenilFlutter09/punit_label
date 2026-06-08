import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:punit_label/constants/app_layout.dart';
import 'package:punit_label/constants/colors.dart';
import 'package:punit_label/constants/utility.dart';
import 'package:punit_label/features/dispatch/view/dispatchScreen.dart';
import 'package:punit_label/features/inward/view/inwardScreen.dart';
import 'package:punit_label/widgets/adaptive_workflow_shell.dart';
import 'package:punit_label/widgets/customAppBar.dart';
import 'package:punit_label/widgets/customDrawer.dart';

import 'dashboardController.dart';

class DashBoardView extends StatelessWidget {
  DashBoardView({super.key});

  final dash = Get.put(DashboardController());

  @override
  Widget build(BuildContext context) {
    final layout = context.layoutSpec;
    final today = DateFormat('dd MMM yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: ColorsValue.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Dashboard',
        showScale: false,
        showPrinter: false,
        showUser: true,
        showDrawer: true,
      ),
      drawer: CustomDrawer(),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: dash.refreshDashboard,
            child: AdaptiveWorkflowShell(
              title: 'Operations Dashboard',
              subtitle:
                  'Track daily inward and dispatch work, then review inventory highlights from one tablet-aware console.',
              headerBadge: today,
              compactContent: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DashboardQuickActions(layout: layout, dash: dash),
                  SizedBox(height: layout.sectionSpacing),
                  _InventoryPanel(layout: layout, dash: dash),
                ],
              ),
              leftPanel: Column(
                children: [
                  _DashboardHero(layout: layout, today: today, dash: dash),
                  SizedBox(height: layout.sectionSpacing),
                  _DashboardQuickActions(layout: layout, dash: dash),
                ],
              ),
              rightPanel: _InventoryPanel(layout: layout, dash: dash),
            ),
          ),
          Obx(
            () => dash.isLoading.value
                ? Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: const Center(child: CircularProgressIndicator()),
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({
    required this.layout,
    required this.today,
    required this.dash,
  });

  final AppLayoutSpec layout;
  final String today;
  final DashboardController dash;

  @override
  Widget build(BuildContext context) {
    return AdaptiveSectionCard(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(layout.cardPadding),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ColorsValue.primaryColor,
              ColorsValue.primaryColor.withValues(alpha: 0.78),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              today,
              style: TextStyle(
                color: Colors.white,
                fontSize: layout.isExpandedTablet ? 28 : 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Keep the tablet on this dashboard to move quickly between inward and dispatch workflows during the shift.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.35,
                fontSize: layout.isTablet ? 15 : 14,
              ),
            ),
            const SizedBox(height: 16),
            Obx(
              () => Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _HeroBadge(
                    label: 'Inventory',
                    value:
                        '${dash.dashboardDetails.value?.data?.totalInventory ?? '0'} Kg',
                  ),
                  _HeroBadge(
                    label: 'Filter',
                    value: dash.selectedFilter.value == 'top'
                        ? 'Top Products'
                        : 'Low Stock',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardQuickActions extends StatelessWidget {
  const _DashboardQuickActions({required this.layout, required this.dash});

  final AppLayoutSpec layout;
  final DashboardController dash;

  @override
  Widget build(BuildContext context) {
    return AdaptiveSectionCard(
      title: 'Primary Actions',
      subtitle: 'Jump into the main operator workflows from the dashboard.',
      child: Row(
        children: [
          Expanded(
            child: _ActionTile(
              title: 'Inward',
              icon: Icons.keyboard_double_arrow_down,
              accent: ColorsValue.primaryGrey,
              onTap: () {
                if (dash.enableInward.value) {
                  Get.to(() => InwardScreen());
                } else {
                  Utility.showDialog('Access Denied');
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionTile(
              title: 'Dispatch',
              icon: Icons.keyboard_double_arrow_up,
              accent: Colors.green,
              onTap: () {
                if (dash.enableDispatch.value) {
                  Get.to(() => DispatchScreen());
                } else {
                  Utility.showDialog('Access Denied');
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.title,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final layout = context.layoutSpec;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: layout.cardPadding,
          vertical: layout.isTablet ? 20 : 16,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: ColorsValue.primaryColor,
          boxShadow: [
            BoxShadow(
              color: ColorsValue.primaryColor.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: accent, size: layout.isTablet ? 40 : 34),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: layout.isTablet ? 20 : 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryPanel extends StatelessWidget {
  const _InventoryPanel({required this.layout, required this.dash});

  final AppLayoutSpec layout;
  final DashboardController dash;

  @override
  Widget build(BuildContext context) {
    return AdaptiveSectionCard(
      title: 'Inventory Highlights',
      subtitle:
          'Track high-performing products or the items that need restocking attention.',
      trailing: Obx(
        () => Text(
          '${dash.dashboardDetails.value?.data?.totalInventory ?? '0'} Kg',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade700,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(
            () => Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ChoiceChip(
                  label: const Text('Top Products'),
                  selected: dash.selectedFilter.value == 'top',
                  onSelected: (_) => dash.selectedFilter.value = 'top',
                ),
                ChoiceChip(
                  label: const Text('Low Stock'),
                  selected: dash.selectedFilter.value == 'low',
                  onSelected: (_) => dash.selectedFilter.value = 'low',
                ),
              ],
            ),
          ),
          SizedBox(height: layout.sectionSpacing),
          Obx(() {
            final List<dynamic> listToShow = dash.selectedFilter.value == 'top'
                ? dash.topProducts
                : dash.lowStockProducts;

            if (listToShow.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'No inventory highlights available yet.',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: listToShow.length,
              itemBuilder: (_, index) {
                final product = listToShow[index];
                return _InventoryCard(
                  title: product.productName ?? '',
                  qty: double.tryParse(product.qty ?? '0') ?? 0,
                  icon: dash.selectedFilter.value == 'top'
                      ? Icons.grade_sharp
                      : Icons.priority_high,
                  color: dash.selectedFilter.value == 'top'
                      ? ColorsValue.primaryColor
                      : ColorsValue.liked,
                  layout: layout,
                );
              },
            );
          }),
        ],
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({
    required this.title,
    required this.qty,
    required this.icon,
    required this.color,
    required this.layout,
  });

  final String title;
  final double qty;
  final IconData icon;
  final Color color;
  final AppLayoutSpec layout;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.symmetric(
        vertical: layout.isTablet ? 18 : 14,
        horizontal: layout.cardPadding,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: layout.isTablet ? 28 : 24,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, size: layout.isTablet ? 28 : 22, color: color),
          ),
          SizedBox(width: layout.isTablet ? 18 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: layout.isTablet ? 17 : 15,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Qty: ${qty.toStringAsFixed(2)} KG',
                    style: TextStyle(
                      fontSize: layout.isTablet ? 14 : 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
