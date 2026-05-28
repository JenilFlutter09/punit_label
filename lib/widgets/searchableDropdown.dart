import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:punit_label/constants/enums.dart';

import '../constants/sizes.dart';
import '../features/bluetooth/bluetoothController.dart';
import '../features/dashboard/dashboardController.dart';
class SearchableStringDropdown extends StatelessWidget {
  final String label;
  final List<String> items;
  final RxString selectedValue;
  final double modalHeightFactor;
  /// 🔹 New: callback when an item is selected
  final void Function(String)? onItemSelected;
  const SearchableStringDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.selectedValue,
    this.modalHeightFactor = 0.75,
    this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final displayText =
          selectedValue.value.isEmpty ? label : selectedValue.value;

      return GestureDetector(
        onTap: () => _openSearchModal(context),
        child: InputDecorator(
          decoration: InputDecoration(
            // labelText: label,
            contentPadding: Dimens.edgeInsets10_0_10_0,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            suffixIcon: const Icon(Icons.arrow_drop_down),
          ),
          child: Text(
            displayText,
            style: TextStyle(
              fontSize: 16,
              color:
                  selectedValue.value.isEmpty ? Colors.grey[600] : Colors.black,
            ),
          ),
        ),
      );
    });
  }

  void _openSearchModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return FractionallySizedBox(
          heightFactor: modalHeightFactor,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: _SearchStringModalContent(
              label: label,
              items: items,
              selectedValue: selectedValue,
              onItemSelected: onItemSelected, // 👈 pass down
            ),
          ),
        );
      },
    );
  }
}
class _SearchStringModalContent extends StatelessWidget {
  final String label;
  final List<String> items;
  final RxString selectedValue;
  final void Function(String)? onItemSelected; // 👈
  const _SearchStringModalContent({
    required this.label,
    required this.items,
    required this.selectedValue,
    this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    String search = "";
    final filtered = <String>[];

    return StatefulBuilder(
      builder: (context, setState) {
        filtered
          ..clear()
          ..addAll(
            items.where((e) => e.toLowerCase().contains(search.toLowerCase())),
          );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select $label',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              autofocus: false,
              decoration: InputDecoration(
                hintText: "Search $label...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (v) => setState(() => search = v),
            ),
            const SizedBox(height: 12),
            Expanded(
              child:
                  filtered.isEmpty
                      ? Center(
                        child: Text(
                          "No item found",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                      : Scrollbar(
                        child: ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            final isSelected = selectedValue.value == item;
                            return ListTile(
                              title: Text(item),
                              trailing:
                                  isSelected
                                      ? const Icon(
                                        Icons.check,
                                        color: Colors.green,
                                      )
                                      : null,
                              onTap: () {
                                selectedValue.value = item;

                                // 🔹 Call the callback if provided
                                if (onItemSelected != null) {
                                  onItemSelected!(item);
                                }

                                Navigator.of(context).pop();
                              },
                            );
                          },
                        ),
                      ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    selectedValue.value = "";
                    Navigator.of(context).pop();
                  },
                  child: const Text("Clear"),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Done"),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}


class SearchableMapDropdown extends StatelessWidget {
  final String label;
  final List<module> items;
  final Rxn<module> selectedValue;
  final double modalHeightFactor;
  final void Function(module)? onItemSelected;

  const SearchableMapDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.selectedValue,
    this.modalHeightFactor = 0.75,
    this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final displayText =
          selectedValue.value?.name;

      return GestureDetector(
        onTap: () => _openSearchModal(context),
        child: InputDecorator(
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            suffixIcon: const Icon(Icons.arrow_drop_down),
          ),
          child: Text(
            displayText ?? "",
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
          ),
        ),
      );
    });
  }

  void _openSearchModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return FractionallySizedBox(
          heightFactor: modalHeightFactor,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: _SearchMapModalContent(
              label: label,
              items: items,
              selectedValue: selectedValue,
              onItemSelected: onItemSelected,
            ),
          ),
        );
      },
    );
  }
}
class _SearchMapModalContent extends StatelessWidget {
  final String label;
  final List<module> items;
  final Rxn<module> selectedValue;
  final void Function(module)? onItemSelected;

  const _SearchMapModalContent({
    required this.label,
    required this.items,
    required this.selectedValue,
    this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    String search = "";
    final filtered = <module>[];

    return StatefulBuilder(
      builder: (context, setState) {
        filtered
          ..clear()
          ..addAll(
            items.where(
                  (e) => (e.name)
                  .toLowerCase()
                  .contains(search.toLowerCase()),
            ),
          );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select $label',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              autofocus: false,
              decoration: InputDecoration(
                hintText: "Search $label...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (v) => setState(() => search = v),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                child: Text(
                  "No item found",
                  style: TextStyle(color: Colors.grey[600]),
                ),
              )
                  : Scrollbar(
                child: ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final isSelected =
                        selectedValue.value?.id == item.id;
                    return ListTile(
                      title: Text(item.name),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: Colors.green)
                          : null,
                      onTap: () {
                        selectedValue.value = item;

                        if (onItemSelected != null) {
                          onItemSelected!(item);
                        }

                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    selectedValue.value?.id;
                    Navigator.of(context).pop();
                  },
                  child: const Text("Clear"),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Done"),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class LabelFormatElement{
  final int id;
  final String nameOfLabel;
  final LabelFormat labelFormat;
  final int elementsAllowedToPrint;
  LabelFormatElement(this.id, this.nameOfLabel, this.elementsAllowedToPrint, this.labelFormat);
}