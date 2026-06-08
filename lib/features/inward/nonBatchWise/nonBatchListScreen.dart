import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:punit_label/constants/app_layout.dart';
import 'package:punit_label/constants/colors.dart';
import 'package:punit_label/features/inward/nonBatchWise/models/nonBatchList.dart';
import 'package:punit_label/features/inward/nonBatchWise/nonBatchInwardScreen.dart';
import 'package:punit_label/widgets/adaptive_workflow_shell.dart';
import 'package:punit_label/widgets/customAppBar.dart';
import 'package:punit_label/widgets/customDrawer.dart';

import '../controller/inwardController.dart';

class NonBatchListScreen extends StatelessWidget {
  NonBatchListScreen({super.key});

  final controller = Get.put(NonInwardController());

  @override
  Widget build(BuildContext context) {
    final layout = context.layoutSpec;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: CustomAppBar(
        title: 'Non Batch INWARD',
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

        final filteredTransactions = controller.filteredBatchList;
        final selectedTransaction = controller.selectedTransaction.value;

        return RefreshIndicator(
          onRefresh: controller.refreshList,
          child: AdaptiveWorkflowShell(
            title: 'Non Batch Inward',
            subtitle:
                'Select an existing transaction to continue, or start a new one for a fresh inward session.',
            headerBadge: '${controller.batchList.length} transactions',
            compactContent: _TransactionListCard(
              controller: controller,
              items: filteredTransactions,
              layout: layout,
            ),
            leftPanel: _TransactionListCard(
              controller: controller,
              items: filteredTransactions,
              layout: layout,
            ),
            rightPanel: _TransactionPreviewCard(
              data: selectedTransaction,
              layout: layout,
              onContinue: selectedTransaction == null
                  ? null
                  : () {
                      controller.selectTransaction(selectedTransaction);
                      Get.to(
                        () => NonBatchInwardScreen(),
                      )?.then((_) => controller.fetchNonBatchlist());
                    },
              onCreateNew: () {
                controller.selectTransaction(null);
                Get.to(
                  () => NonBatchInwardScreen(),
                )?.then((_) => controller.fetchNonBatchlist());
              },
            ),
          ),
        );
      }),
      floatingActionButton: layout.isExpandedTablet
          ? null
          : FloatingActionButton.extended(
              backgroundColor: ColorsValue.primaryColor,
              onPressed: () {
                controller.selectTransaction(null);
                Get.to(() => NonBatchInwardScreen());
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'New Transaction Inward',
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

class _TransactionListCard extends StatelessWidget {
  const _TransactionListCard({
    required this.controller,
    required this.items,
    required this.layout,
  });

  final NonInwardController controller;
  final List<Entity> items;
  final AppLayoutSpec layout;

  @override
  Widget build(BuildContext context) {
    return AdaptiveSectionCard(
      title: 'Select Transaction',
      subtitle:
          'Search by transaction name and continue the previously created inward session.',
      child: Column(
        children: [
          TextField(
            controller: controller.searchController,
            onChanged: controller.updateSearchQuery,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search transaction name',
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
            ),
          ),
          SizedBox(height: layout.sectionSpacing),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Text(
                'No transaction found',
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
                    controller.selectedTransaction.value?.id == data.id;
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    controller.selectTransaction(data);
                    if (!layout.isExpandedTablet) {
                      Get.to(
                        () => NonBatchInwardScreen(),
                      )?.then((_) => controller.fetchNonBatchlist());
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${data.name ?? 'Transaction'}-${data.id ?? ''}',
                                style: TextStyle(
                                  fontSize: layout.isTablet ? 17 : 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              if ((data.scaleMac ?? '').isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '${data.scaleName ?? 'Unnamed'} (${data.scaleMac})',
                                    style: TextStyle(
                                      fontSize: layout.isTablet ? 13 : 11,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                            ],
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

class _TransactionPreviewCard extends StatelessWidget {
  const _TransactionPreviewCard({
    required this.data,
    required this.layout,
    required this.onContinue,
    required this.onCreateNew,
  });

  final Entity? data;
  final AppLayoutSpec layout;
  final VoidCallback? onContinue;
  final VoidCallback onCreateNew;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AdaptiveSectionCard(
          title: 'Selected Transaction',
          subtitle: data == null
              ? 'Choose an existing transaction to continue the current inward session.'
              : 'Resume this transaction or create a brand new inward entry.',
          child: data == null
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
                        Icons.assignment_outlined,
                        size: 48,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No transaction selected',
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
                            '${data!.name ?? 'Transaction'}-${data!.id ?? ''}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: ColorsValue.primaryColor,
                            ),
                          ),
                          if ((data!.scaleMac ?? '').isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Scale: ${data!.scaleName ?? 'Unnamed'} (${data!.scaleMac})',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: layout.sectionSpacing),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onContinue,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Continue Transaction'),
                      ),
                    ),
                  ],
                ),
        ),
        SizedBox(height: layout.sectionSpacing),
        AdaptiveSectionCard(
          title: 'Create New',
          subtitle: 'Start a fresh non-batch inward transaction when needed.',
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onCreateNew,
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: const Text('Start New Transaction'),
            ),
          ),
        ),
      ],
    );
  }
}
