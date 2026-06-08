import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:punit_label/constants/app_layout.dart';
import 'package:punit_label/constants/colors.dart';
import 'package:punit_label/features/inward/batchWise/batchInwardScreen.dart';
import 'package:punit_label/features/inward/batchWise/models/batchList.dart';
import 'package:punit_label/features/inward/nonBatchWise/nonBatchListScreen.dart';
import 'package:punit_label/widgets/adaptive_workflow_shell.dart';
import 'package:punit_label/widgets/customAppBar.dart';
import 'package:punit_label/widgets/customDrawer.dart';

import '../controller/inwardController.dart';

class InwardScreen extends StatelessWidget {
  InwardScreen({super.key});

  final controller = Get.put(InwardController());

  @override
  Widget build(BuildContext context) {
    final layout = context.layoutSpec;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: CustomAppBar(
        title: 'INWARD',
        showScale: false,
        showPrinter: false,
        showUser: false,
        showDrawer: true,
      ),
      drawer: CustomDrawer(),
      body: Obx(() {
        if (controller.initLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final filteredBatchList = controller.filteredBatchList;
        final selectedBatch = controller.selectedBatch.value;

        return RefreshIndicator(
          onRefresh: controller.refreshList,
          child: AdaptiveWorkflowShell(
            title: 'Inward Workflows',
            subtitle:
                'Choose a batch to continue batch-wise inward, or jump to the non-batch flow for ad hoc transactions.',
            headerBadge: '${controller.batchList.length} batches',
            compactContent: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BatchListCard(
                  controller: controller,
                  items: filteredBatchList,
                  layout: layout,
                ),
              ],
            ),
            leftPanel: _BatchListCard(
              controller: controller,
              items: filteredBatchList,
              layout: layout,
            ),
            rightPanel: _BatchSelectionPanel(
              selectedBatch: selectedBatch,
              layout: layout,
              onOpenBatch: selectedBatch == null
                  ? null
                  : () => Get.to(
                      () => BatchInwardScreen(
                        selectedBatchId: selectedBatch.id.toString(),
                      ),
                    ),
              onOpenNonBatch: () => Get.to(() => NonBatchListScreen()),
            ),
          ),
        );
      }),
      floatingActionButton: layout.isExpandedTablet
          ? null
          : FloatingActionButton.extended(
              backgroundColor: ColorsValue.primaryColor,
              onPressed: () => Get.to(() => NonBatchListScreen()),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'Non Batch Wise Inward',
                style: TextStyle(
                  fontSize: layout.isTablet ? 16 : 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
    );
  }
}

class _BatchListCard extends StatelessWidget {
  const _BatchListCard({
    required this.controller,
    required this.items,
    required this.layout,
  });

  final InwardController controller;
  final List<batch> items;
  final AppLayoutSpec layout;

  @override
  Widget build(BuildContext context) {
    return AdaptiveSectionCard(
      title: 'Select Batch',
      subtitle:
          'Search the available batch list and open the selected workflow.',
      child: Column(
        children: [
          TextField(
            controller: controller.searchController,
            onChanged: controller.updateSearchQuery,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search batch name',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Obx(() {
                if (controller.searchQuery.value.isEmpty) {
                  return const SizedBox.shrink();
                }
                return IconButton(
                  onPressed: () {
                    controller.searchController.clear();
                    controller.updateSearchQuery('');
                  },
                  icon: const Icon(Icons.close),
                );
              }),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: layout.cardPadding,
                vertical: layout.isTablet ? 16 : 14,
              ),
            ),
          ),
          SizedBox(height: layout.sectionSpacing),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Text(
                'No batch found',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  SizedBox(height: layout.sectionSpacing - 8),
              itemBuilder: (context, index) {
                final data = items[index];
                final isSelected =
                    controller.selectedBatch.value?.id == data.id;

                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    controller.selectBatch(data);
                    if (!layout.isExpandedTablet) {
                      Get.to(
                        () => BatchInwardScreen(
                          selectedBatchId: data.id.toString(),
                        ),
                      );
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: EdgeInsets.symmetric(
                      horizontal: layout.cardPadding,
                      vertical: layout.isTablet ? 16 : 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? ColorsValue.primaryColor.withValues(alpha: 0.08)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? ColorsValue.primaryColor
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: layout.isTablet ? 24 : 22,
                          backgroundColor: ColorsValue.primaryColor.withValues(
                            alpha: 0.18,
                          ),
                          child: Icon(
                            Icons.inventory_2_rounded,
                            color: ColorsValue.primaryColor,
                            size: layout.isTablet ? 26 : 22,
                          ),
                        ),
                        SizedBox(width: layout.isTablet ? 16 : 12),
                        Expanded(
                          child: Text(
                            data.batchName ?? 'Batch',
                            style: TextStyle(
                              fontSize: layout.isTablet ? 17 : 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Icon(
                          layout.isExpandedTablet
                              ? Icons.arrow_outward_rounded
                              : Icons.chevron_right,
                          size: layout.isTablet ? 28 : 24,
                          color: Colors.grey.shade600,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _BatchSelectionPanel extends StatelessWidget {
  const _BatchSelectionPanel({
    required this.selectedBatch,
    required this.layout,
    required this.onOpenBatch,
    required this.onOpenNonBatch,
  });

  final batch? selectedBatch;
  final AppLayoutSpec layout;
  final VoidCallback? onOpenBatch;
  final VoidCallback onOpenNonBatch;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AdaptiveSectionCard(
          title: 'Selected Batch',
          subtitle: selectedBatch == null
              ? 'Select a batch from the left panel to preview and continue.'
              : 'Open the selected batch to continue inward entry on the tablet workflow screen.',
          child: selectedBatch == null
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.playlist_add_check_circle_outlined,
                        size: 48,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No batch selected yet',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(layout.cardPadding),
                      decoration: BoxDecoration(
                        color: ColorsValue.primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedBatch!.batchName ?? 'Batch',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: ColorsValue.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Batch ID: ${selectedBatch!.id ?? '-'}',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: layout.sectionSpacing),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onOpenBatch,
                        icon: const Icon(Icons.keyboard_double_arrow_right),
                        label: const Text('Open Batch Inward'),
                      ),
                    ),
                  ],
                ),
        ),
        SizedBox(height: layout.sectionSpacing),
        AdaptiveSectionCard(
          title: 'Other Options',
          subtitle:
              'Use the non-batch flow when the operator needs a transaction-based inward process.',
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onOpenNonBatch,
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: const Text('Open Non Batch Inward'),
            ),
          ),
        ),
      ],
    );
  }
}
