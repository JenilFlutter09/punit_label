class LabelTemplateSelection {
  final int batchId;
  final int batchProductId;
  final List<int> selectedAttributeIds;
  final String labelTemplate;
  final int maxAllowed;

  const LabelTemplateSelection({
    required this.batchId,
    required this.batchProductId,
    required this.selectedAttributeIds,
    required this.labelTemplate,
    required this.maxAllowed,
  });

  Map<String, dynamic> toJson() {
    return {
      'data': {
        'batch_id': batchId,
        'batch_product_id': batchProductId,
        'selected_attribute_ids': selectedAttributeIds,
        'label_template': labelTemplate,
        'max_allowed': maxAllowed,
      },
    };
  }
}
