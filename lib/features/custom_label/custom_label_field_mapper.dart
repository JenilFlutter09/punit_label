// import 'package:punit_label/features/custom_label/custom_label_template_catalog.dart';
// import 'package:punit_label/features/custom_label/models/custom_label_print_payload.dart';
// import 'package:punit_label/features/custom_label/models/custom_label_runtime_template.dart';
// import 'package:punit_label/features/dashboard/companyModel.dart';
// import 'package:punit_label/features/inward/batchWise/models/batchDetails.dart';
//
// abstract class CustomLabelFieldMapper {
//   static CustomLabelPrintPayload buildPrintPayload({
//     required CustomLabelRuntimeData runtime,
//     required CompanyData? fallbackCompany,
//     required List<Combinations> combinations,
//     required String productName,
//     required String barcode,
//     required String barcodeText,
//     required String grossWeight,
//     required String tareWeight,
//     required String netWeight,
//     required String serialNumber,
//     required String datetime,
//   }) {
//     final template = runtime.template!;
//     final companyProfile = runtime.companyProfile;
//     final companyName =
//         companyProfile?.companyName ?? fallbackCompany?.name ?? '';
//     final labelSize = template.labelSize ?? '75x100';
//     final canvas = CustomLabelTemplateCatalog.canvasSizeForLabel(labelSize);
//
//     final sortedFields = List<CustomLabelField>.from(template.fields)
//       ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
//
//     final attributeValues = <String, String>{};
//     for (final combination in combinations) {
//       final key = _normalizeKey(combination.attrName ?? '');
//       if (key.isNotEmpty) {
//         attributeValues[key] = combination.attrValue ?? '';
//       }
//     }
//
//     final fields = <CustomLabelPrintField>[];
//     for (final field in sortedFields) {
//       if (!field.isVisible) continue;
//       if (template.whiteLabel && _isCompanyField(field.fieldKey)) continue;
//       if (!template.showSrNo && field.fieldKey == 'sr_no') continue;
//       if (!template.showDatetime && field.fieldKey == 'datetime') continue;
//
//       final value = _resolveValue(
//         fieldKey: field.fieldKey,
//         companyProfile: companyProfile,
//         fallbackCompany: fallbackCompany,
//         attributeValues: attributeValues,
//         productName: productName,
//         grossWeight: grossWeight,
//         tareWeight: tareWeight,
//         netWeight: netWeight,
//         barcode: barcode,
//         barcodeText: barcodeText,
//         serialNumber: serialNumber,
//         datetime: datetime,
//         footerText: runtime.footerText ?? '',
//       );
//
//       fields.add(
//         CustomLabelPrintField(
//           fieldKey: field.fieldKey,
//           value: value,
//           x: CustomLabelTemplateCatalog.mmToPrinterUnitsX(field.x, labelSize),
//           y: CustomLabelTemplateCatalog.mmToPrinterUnitsY(field.y, labelSize),
//           w: CustomLabelTemplateCatalog.mmToPrinterUnitsX(field.w, labelSize),
//           h: CustomLabelTemplateCatalog.mmToPrinterUnitsY(field.h, labelSize),
//           fontSize: CustomLabelTemplateCatalog.mmToPrinterFontUnits(
//             field.fontSize,
//             labelSize,
//           ),
//           lineHeight: CustomLabelTemplateCatalog.mmToPrinterFontUnits(
//             field.lineHeight,
//             labelSize,
//           ),
//           fontWeight: field.fontWeight,
//           align: field.align,
//           orderIndex: field.orderIndex,
//           extraJson: field.extraJson,
//         ),
//       );
//     }
//
//     return CustomLabelPrintPayload(
//       width: canvas.width,
//       height: canvas.height,
//       labelSize: labelSize,
//       whiteLabel: template.whiteLabel,
//       showSrNo: template.showSrNo,
//       showDatetime: template.showDatetime,
//       footerText: runtime.footerText ?? '',
//       barcodeData: barcode,
//       companyName: companyName,
//       fields: fields,
//     );
//   }
//
//   static String _resolveValue({
//     required String fieldKey,
//     required CompanyProfileRuntimeData? companyProfile,
//     required CompanyData? fallbackCompany,
//     required Map<String, String> attributeValues,
//     required String productName,
//     required String grossWeight,
//     required String tareWeight,
//     required String netWeight,
//     required String barcode,
//     required String barcodeText,
//     required String serialNumber,
//     required String datetime,
//     required String footerText,
//   }) {
//     switch (fieldKey) {
//       case 'company_name':
//         return companyProfile?.companyName ?? fallbackCompany?.name ?? '';
//       case 'company_email':
//         return companyProfile?.companyEmail ?? fallbackCompany?.email ?? '';
//       case 'company_contact_no':
//         return companyProfile?.companyContactNo ??
//             fallbackCompany?.contactNo ??
//             '';
//       case 'company_gst_no':
//         return companyProfile?.companyGstNo ?? fallbackCompany?.gstNo ?? '';
//       case 'company_website':
//         return companyProfile?.companyWebsite ?? fallbackCompany?.website ?? '';
//       case 'company_address':
//         return companyProfile?.companyAddress ?? fallbackCompany?.address ?? '';
//       case 'product_name':
//         return productName;
//       case 'gross_weight':
//         return grossWeight;
//       case 'tare_weight':
//         return tareWeight;
//       case 'net_weight':
//         return netWeight;
//       case 'barcode':
//         return barcode;
//       case 'barcode_text':
//         return barcodeText;
//       case 'sr_no':
//         return serialNumber;
//       case 'datetime':
//         return datetime;
//       case 'footer':
//         return footerText;
//       default:
//         if (fieldKey.startsWith('attr_')) {
//           return attributeValues[_normalizeKey(fieldKey.substring(5))] ?? '';
//         }
//         return '';
//     }
//   }
//
//   static String _normalizeKey(String value) {
//     return value.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]+'), '_');
//   }
//
//   static bool _isCompanyField(String fieldKey) {
//     return fieldKey.startsWith('company_') || fieldKey == 'footer';
//   }
// }
