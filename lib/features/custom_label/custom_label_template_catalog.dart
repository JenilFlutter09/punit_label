// import 'package:punit_label/constants/enums.dart';
//
// class ExistingLabelTemplateDefinition {
//   final String id;
//   final String name;
//   final int maxAllowed;
//   final LabelFormat labelFormat;
//   final String labelSize;
//
//   const ExistingLabelTemplateDefinition({
//     required this.id,
//     required this.name,
//     required this.maxAllowed,
//     required this.labelFormat,
//     required this.labelSize,
//   });
// }
//
// abstract class CustomLabelTemplateCatalog {
//   static const double printerDotsPerMm = 8.0;
//   static const List<ExistingLabelTemplateDefinition> existingTemplates = [
//     ExistingLabelTemplateDefinition(
//       id: '0',
//       name: 'Majedar tea Label Format',
//       maxAllowed: 1,
//       labelFormat: LabelFormat.MajedarTea,
//       labelSize: '50x75',
//     ),
//     ExistingLabelTemplateDefinition(
//       id: '1',
//       name: 'Small Label Select Max (3)',
//       maxAllowed: 3,
//       labelFormat: LabelFormat.Small,
//       labelSize: '50x75',
//     ),
//     ExistingLabelTemplateDefinition(
//       id: '2',
//       name: 'Medium Label Select Max (4)',
//       maxAllowed: 4,
//       labelFormat: LabelFormat.Medium,
//       labelSize: '75x75',
//     ),
//     ExistingLabelTemplateDefinition(
//       id: '3',
//       name: 'Large Label Select Max (5)',
//       maxAllowed: 5,
//       labelFormat: LabelFormat.Large,
//       labelSize: '75x100',
//     ),
//     ExistingLabelTemplateDefinition(
//       id: '4',
//       name: 'Extra Large Label Select Max (7)',
//       maxAllowed: 7,
//       labelFormat: LabelFormat.ExtraLarge,
//       labelSize: '100x100',
//     ),
//     ExistingLabelTemplateDefinition(
//       id: '5',
//       name: 'Wholesale Pack',
//       maxAllowed: 10,
//       labelFormat: LabelFormat.WholesalePack,
//       labelSize: '100x150',
//     ),
//     ExistingLabelTemplateDefinition(
//       id: '6',
//       name: 'Small Seven (5)',
//       maxAllowed: 5,
//       labelFormat: LabelFormat.SmallSeven,
//       labelSize: '50x75',
//     ),
//   ];
//
//   static ExistingLabelTemplateDefinition? byId(String? id) {
//     if (id == null || id.isEmpty) return null;
//     for (final template in existingTemplates) {
//       if (template.id == id) {
//         return template;
//       }
//     }
//     return null;
//   }
//
//   static ExistingLabelTemplateDefinition? byLabelSize(String? labelSize) {
//     if (labelSize == null || labelSize.isEmpty) return null;
//     for (final template in existingTemplates) {
//       if (template.labelSize == labelSize) {
//         return template;
//       }
//     }
//     return null;
//   }
//
//   static String labelSizeForSelection({
//     String? labelId,
//     String? labelTemplateKey,
//   }) {
//     final existing = byId(labelId);
//     if (existing != null) {
//       return existing.labelSize;
//     }
//
//     final normalized = (labelTemplateKey ?? '').trim();
//     if (normalized.startsWith('custom_')) {
//       return '75x100';
//     }
//
//     return '75x100';
//   }
//
//   static LabelFormat labelFormatForId(String? id) {
//     return byId(id)?.labelFormat ?? LabelFormat.Large;
//   }
//
//   static int maxAllowedForId(String? id) {
//     return byId(id)?.maxAllowed ?? 5;
//   }
//
//   static String defaultExistingIdForSize(String? labelSize) {
//     return byLabelSize(labelSize)?.id ?? '3';
//   }
//
//   static ({double widthMm, double heightMm}) labelDimensionsForSize(
//     String? labelSize,
//   ) {
//     final normalized = (labelSize ?? '').trim();
//     final parts = normalized.split('x');
//     if (parts.length == 2) {
//       final widthMm = double.tryParse(parts[0]) ?? 75;
//       final heightMm = double.tryParse(parts[1]) ?? 100;
//       return (widthMm: widthMm, heightMm: heightMm);
//     }
//
//     return (widthMm: 75, heightMm: 100);
//   }
//
//   static ({int width, int height}) canvasSizeForLabel(String? labelSize) {
//     final dimensions = labelDimensionsForSize(labelSize);
//     return (
//       width: (dimensions.widthMm * printerDotsPerMm).round(),
//       height: (dimensions.heightMm * printerDotsPerMm).round(),
//     );
//   }
//
//   static int mmToPrinterUnitsX(double mm, String? labelSize) {
//     final dimensions = labelDimensionsForSize(labelSize);
//     final canvas = canvasSizeForLabel(labelSize);
//     final dotsPerMmX = canvas.width / dimensions.widthMm;
//     return (mm * dotsPerMmX).round();
//   }
//
//   static int mmToPrinterUnitsY(double mm, String? labelSize) {
//     final dimensions = labelDimensionsForSize(labelSize);
//     final canvas = canvasSizeForLabel(labelSize);
//     final dotsPerMmY = canvas.height / dimensions.heightMm;
//     return (mm * dotsPerMmY).round();
//   }
//
//   static int mmToPrinterFontUnits(double mm, String? labelSize) {
//     final dimensions = labelDimensionsForSize(labelSize);
//     final canvas = canvasSizeForLabel(labelSize);
//     final dotsPerMmX = canvas.width / dimensions.widthMm;
//     final dotsPerMmY = canvas.height / dimensions.heightMm;
//     final averageDotsPerMm = (dotsPerMmX + dotsPerMmY) / 2;
//     return (mm * averageDotsPerMm).round();
//   }
// }
