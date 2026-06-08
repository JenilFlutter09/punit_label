// import 'dart:async';
//
// import '../inward/batchWise/models/batchDetails.dart';
// import 'models/custom_label_runtime_template.dart';
// import 'models/label_template_option.dart';
// import 'models/label_template_selection.dart';
//
// class CustomLabelRepository {
//   static final Map<int, String> _savedTemplateByBatchProductId = {};
//
//   void syncBatchSelectionsFromApi(List<Products> products) {
//     for (final product in products) {
//       final batchProductId = product.batchProductId;
//       if (batchProductId == null) continue;
//
//       final currentMode = product.labelMode?.trim().toLowerCase();
//       final hasTemplateKey =
//           product.labelTemplateKey != null &&
//           product.labelTemplateKey!.trim().isNotEmpty;
//       final hasLabelId =
//           product.labelId != null && product.labelId!.trim().isNotEmpty;
//
//       if (currentMode == 'custom' && hasTemplateKey) {
//         _savedTemplateByBatchProductId[batchProductId] = product
//             .labelTemplateKey!
//             .trim();
//         continue;
//       }
//
//       if (currentMode == 'existing' && hasLabelId) {
//         _savedTemplateByBatchProductId[batchProductId] = product.labelId!
//             .trim();
//       }
//     }
//   }
//
//   String defaultCustomTemplateKey(int productId) => 'custom_$productId';
//
//   Future<List<LabelTemplateOption>> getLabelTemplateOptions({
//     required String labelSize,
//     required int batchProductId,
//     required int productId,
//   }) async {
//     await Future<void>.delayed(const Duration(milliseconds: 120));
//
//     final existingOptions = [
//       {
//         'id': '1',
//         'name': 'Existing 1',
//         'mode': 'existing',
//         'label_size': labelSize,
//         'max_allowed': 3,
//       },
//       {
//         'id': '2',
//         'name': 'Existing 2',
//         'mode': 'existing',
//         'label_size': labelSize,
//         'max_allowed': 4,
//       },
//     ];
//
//     final customTemplateId =
//         _savedTemplateByBatchProductId[batchProductId] ??
//         defaultCustomTemplateKey(productId);
//     final customOption = {
//       'id': customTemplateId,
//       'name': 'v1',
//       'mode': 'custom',
//       'label_size': labelSize,
//       'product_id': productId,
//       'is_default': true,
//       'max_allowed': 4,
//     };
//
//     final response = LabelTemplateOptionsResponse.fromJson({
//       'status': true,
//       'data': {
//         'options': [...existingOptions, customOption],
//       },
//     });
//
//     return response.data.options;
//   }
//
//   Future<bool> saveBatchProductLabelSelection({
//     required LabelTemplateSelection selection,
//   }) async {
//     await Future<void>.delayed(const Duration(milliseconds: 120));
//     _savedTemplateByBatchProductId[selection.batchProductId] =
//         selection.labelTemplate;
//     return true;
//   }
//
//   Future<CustomLabelRuntimeData> getCustomLabelRuntime({
//     required String labelSize,
//     required int batchProductId,
//     required int productId,
//   }) async {
//     await Future<void>.delayed(const Duration(milliseconds: 120));
//
//     final selectedTemplateId =
//         _savedTemplateByBatchProductId[batchProductId] ??
//         defaultCustomTemplateKey(productId);
//
//     if (!selectedTemplateId.startsWith('custom_')) {
//       return CustomLabelRuntimeResponse.fromJson({
//         'status': true,
//         'data': {
//           'label_mode': 'existing',
//           'template_key': null,
//           'template': null,
//         },
//       }).data;
//     }
//
//     return CustomLabelRuntimeResponse.fromJson({
//       'status': true,
//       'data': {
//         'label_mode': 'custom',
//         'template_key': selectedTemplateId,
//         'company_profile': {
//           'company_name': 'Punit Instrument',
//           'company_email': 'info@punitinstrument.com',
//           'company_contact_no': '+91 98765 43210',
//           'company_gst_no': '24ABCDE1234F1Z5',
//           'company_website': 'www.punitinstrument.com',
//           'company_address': 'Ahmedabad, Gujarat, India',
//         },
//         'footer_text':
//             'Label generated from weighing ERP by punitinstrument.com',
//         'template': {
//           'label_size': labelSize,
//           'white_label': false,
//           'show_sr_no': true,
//           'show_datetime': true,
//           'fields': _mockFieldsForSize(labelSize),
//         },
//       },
//     }).data;
//   }
//
//   List<Map<String, dynamic>> _mockFieldsForSize(String labelSize) {
//     switch (labelSize) {
//       case '75x75':
//         return _squareFields();
//       case '100x150':
//         return _wholesaleFields();
//       case '50x75':
//         return _compactFields();
//       case '100x100':
//         return _largeFields();
//       case '75x100':
//       default:
//         return _defaultFields();
//     }
//   }
//
//   List<Map<String, dynamic>> _defaultFields() {
//     return [
//       _field('company_name', 3, 3, 52, 4.2, 3.4, 4.0, 700, 'left', 1),
//       _field('company_contact_no', 3, 8, 28, 2.4, 1.8, 2.2, 400, 'left', 2),
//       _field('company_email', 33, 8, 39, 2.4, 1.8, 2.2, 400, 'right', 3),
//       _field('product_name', 3, 14, 69, 5, 3.6, 4.2, 700, 'left', 4),
//       _field('attr_MACHINE', 3, 20, 33, 3, 2.2, 2.8, 500, 'left', 5),
//       _field('attr_SIZE', 39, 20, 33, 3, 2.2, 2.8, 500, 'left', 6),
//       _field('gross_weight', 3, 25, 20, 3, 2.1, 2.7, 500, 'left', 7),
//       _field('tare_weight', 26, 25, 20, 3, 2.1, 2.7, 500, 'left', 8),
//       _field('net_weight', 49, 25, 23, 3, 2.1, 2.7, 700, 'left', 9),
//       _field('barcode', 3, 36, 69, 15, 0, 0, 400, 'center', 10),
//       _field('barcode_text', 3, 52, 69, 2.4, 1.8, 2.2, 400, 'center', 11),
//       _field('sr_no', 3, 56, 18, 2.4, 1.8, 2.2, 400, 'left', 12),
//       _field('datetime', 43, 56, 29, 2.4, 1.8, 2.2, 400, 'right', 13),
//       _field('footer', 3, 94, 69, 2.2, 1.6, 2.0, 400, 'center', 14),
//     ];
//   }
//
//   List<Map<String, dynamic>> _squareFields() {
//     return [
//       _field('company_name', 3, 3, 54, 4, 3.0, 3.6, 700, 'left', 1),
//       _field('company_contact_no', 3, 7, 31, 2.2, 1.7, 2.1, 400, 'left', 2),
//       _field('company_email', 37, 7, 35, 2.2, 1.7, 2.1, 400, 'right', 3),
//       _field(
//         'company_gst_no',
//         3,
//         10,
//         30,
//         2.2,
//         1.7,
//         2.1,
//         400,
//         'left',
//         4,
//         isVisible: false,
//       ),
//       _field(
//         'company_website',
//         37,
//         10,
//         35,
//         2.2,
//         1.7,
//         2.1,
//         400,
//         'right',
//         5,
//         isVisible: false,
//       ),
//       _field('company_address', 3, 13, 69, 3, 1.8, 2.2, 400, 'left', 6),
//       _field('product_name', 3, 17.5, 69, 4.2, 3.2, 3.8, 700, 'left', 7),
//       _field('attr_MACHINE', 3, 23, 33, 2.6, 2.1, 2.6, 500, 'left', 8),
//       _field('attr_SIZE', 39, 23, 33, 2.6, 2.1, 2.6, 500, 'left', 9),
//       _field(
//         'attr_GSM',
//         3,
//         26,
//         33,
//         2.4,
//         1.8,
//         2.2,
//         500,
//         'left',
//         10,
//         isVisible: false,
//       ),
//       _field(
//         'attr_CUSTOMER',
//         39,
//         26,
//         33,
//         2.4,
//         1.8,
//         2.2,
//         500,
//         'left',
//         11,
//         isVisible: false,
//       ),
//       _field('gross_weight', 3, 30, 22, 2.6, 2.0, 2.4, 500, 'left', 12),
//       _field('tare_weight', 27, 30, 22, 2.6, 2.0, 2.4, 500, 'left', 13),
//       _field('net_weight', 51, 30, 21, 2.6, 2.0, 2.4, 700, 'left', 14),
//       _field('barcode', 3, 37, 69, 12, 0, 0, 400, 'center', 15),
//       _field('barcode_text', 3, 50, 69, 2.2, 1.7, 2.1, 400, 'center', 16),
//       _field('sr_no', 3, 54, 18, 2.2, 1.7, 2.1, 400, 'left', 17),
//       _field('datetime', 42, 54, 30, 2.2, 1.7, 2.1, 400, 'right', 18),
//       _field('footer', 3, 71, 69, 2, 1.5, 1.9, 400, 'center', 19),
//     ];
//   }
//
//   List<Map<String, dynamic>> _compactFields() {
//     return [
//       _field('company_name', 2.5, 2.5, 45, 3.6, 2.8, 3.4, 700, 'left', 1),
//       _field('product_name', 2.5, 8, 45, 4, 3.0, 3.6, 700, 'left', 2),
//       _field('attr_MACHINE', 2.5, 13.5, 45, 2.6, 2.0, 2.5, 500, 'left', 3),
//       _field('net_weight', 2.5, 18, 22, 2.6, 2.0, 2.5, 700, 'left', 4),
//       _field('barcode', 2.5, 25, 45, 10, 0, 0, 400, 'center', 5),
//       _field('barcode_text', 2.5, 36.5, 45, 2, 1.6, 2.0, 400, 'center', 6),
//       _field('sr_no', 2.5, 40, 14, 2, 1.6, 2.0, 400, 'left', 7),
//       _field('datetime', 24, 40, 23.5, 2, 1.6, 2.0, 400, 'right', 8),
//       _field('footer', 2.5, 71, 45, 1.8, 1.4, 1.8, 400, 'center', 9),
//     ];
//   }
//
//   List<Map<String, dynamic>> _largeFields() {
//     return [
//       _field('company_name', 3, 3, 74, 4.2, 3.4, 4.0, 700, 'left', 1),
//       _field('company_website', 3, 8, 74, 2.4, 1.8, 2.2, 400, 'left', 2),
//       _field('product_name', 3, 14, 94, 5, 3.6, 4.2, 700, 'left', 3),
//       _field('attr_MACHINE', 3, 20, 44, 3, 2.2, 2.8, 500, 'left', 4),
//       _field('attr_GSM', 50, 20, 44, 3, 2.2, 2.8, 500, 'left', 5),
//       _field('gross_weight', 3, 25, 28, 3, 2.1, 2.7, 500, 'left', 6),
//       _field('tare_weight', 35, 25, 28, 3, 2.1, 2.7, 500, 'left', 7),
//       _field('net_weight', 67, 25, 27, 3, 2.1, 2.7, 700, 'left', 8),
//       _field('barcode', 3, 38, 94, 18, 0, 0, 400, 'center', 9),
//       _field('barcode_text', 3, 57, 94, 2.4, 1.8, 2.2, 400, 'center', 10),
//       _field('footer', 3, 96, 94, 2.2, 1.6, 2.0, 400, 'center', 11),
//     ];
//   }
//
//   List<Map<String, dynamic>> _wholesaleFields() {
//     return [
//       _field('company_name', 3, 3, 94, 4.8, 3.8, 4.4, 700, 'left', 1),
//       _field('company_address', 3, 9, 94, 4, 2.2, 2.8, 400, 'left', 2),
//       _field('product_name', 3, 18, 94, 6, 4.2, 5.0, 700, 'center', 3),
//       _field('attr_CUSTOMER', 3, 28, 94, 4, 2.8, 3.4, 500, 'left', 4),
//       _field('gross_weight', 3, 35, 42, 4, 2.8, 3.4, 700, 'left', 5),
//       _field('net_weight', 52, 35, 45, 4, 2.8, 3.4, 700, 'left', 6),
//       _field('barcode', 3, 48, 94, 24, 0, 0, 400, 'center', 7),
//       _field('barcode_text', 3, 73, 94, 2.8, 2.0, 2.5, 400, 'center', 8),
//       _field('datetime', 3, 78, 44, 2.6, 1.9, 2.4, 400, 'left', 9),
//       _field('footer', 3, 145, 94, 2.2, 1.6, 2.0, 400, 'center', 10),
//     ];
//   }
//
//   Map<String, dynamic> _field(
//     String fieldKey,
//     double x,
//     double y,
//     double w,
//     double h,
//     double fontSize,
//     double lineHeight,
//     int fontWeight,
//     String align,
//     int orderIndex, {
//     bool isVisible = true,
//   }) {
//     return {
//       'field_key': fieldKey,
//       'is_visible': isVisible,
//       'x': x,
//       'y': y,
//       'w': w,
//       'h': h,
//       'font_size': fontSize,
//       'line_height': lineHeight,
//       'font_weight': fontWeight,
//       'align': align,
//       'order_index': orderIndex,
//       'extra_json': {},
//     };
//   }
// }
