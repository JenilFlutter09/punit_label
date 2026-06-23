import '../models/scale_models.dart';
import 'generic_scale_packet_parser.dart';
import 'scale_packet_parser.dart';

class KeywordAwareScalePacketParser extends ScalePacketParser {
  final List<String> keywords;
  final GenericScalePacketParser _fallback = const GenericScalePacketParser();

  KeywordAwareScalePacketParser({
    required this.keywords,
  });

  @override
  String get id => 'keyword_aware_${keywords.join('_')}';

  @override
  double? parse(ScalePacket packet) {
    final raw = packet.asString;
    final lines = raw
        .split(RegExp(r'[\r\n]+'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty);

    for (final line in lines) {
      final lowerLine = line.toLowerCase();
      if (!keywords.any((keyword) => lowerLine.contains(keyword))) continue;
      final parsed = _fallback.parse(
        ScalePacket(
          deviceId: packet.deviceId,
          transportType: packet.transportType,
          bytes: line.codeUnits,
          receivedAt: packet.receivedAt,
        ),
      );
      if (parsed != null) return parsed;
    }

    return _fallback.parse(packet);
  }
}
