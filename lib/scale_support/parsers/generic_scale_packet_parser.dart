import '../models/scale_models.dart';
import 'scale_packet_parser.dart';

class GenericScalePacketParser extends ScalePacketParser {
  const GenericScalePacketParser();

  @override
  String get id => 'generic';

  @override
  double? parse(ScalePacket packet) {
    final raw = packet.asString.trim();
    if (raw.isEmpty) return null;

    final cleaned = raw
        .replaceAll(',', '.')
        .replaceAll('\u0000', ' ')
        .replaceAll(RegExp(r'[\x00-\x1F]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.isEmpty) return null;

    final chunks = cleaned
        .split(RegExp(r'[\r\n]+'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList()
        .reversed;

    for (final chunk in chunks) {
      final parsed = _extractWeight(chunk);
      if (parsed != null) return parsed;
    }

    return _extractWeight(cleaned);
  }

  double? _extractWeight(String chunk) {
    final matches = RegExp(r'[-+]?\d*\.?\d+').allMatches(chunk).toList();
    if (matches.isEmpty) return null;

    final lowerChunk = chunk.toLowerCase();
    final hasDecimalCandidate = matches.any(
      (match) => (match.group(0) ?? '').contains('.'),
    );

    double? bestValue;
    int? bestScore;
    int bestStart = -1;

    for (final match in matches) {
      final token = match.group(0);
      if (token == null || token.trim().isEmpty) continue;

      final value = double.tryParse(token);
      if (value == null) continue;

      var score = 0;
      if (token.contains('.')) score += 40;
      if (value.abs() < 1000) score += 5;
      if ((token == '0' || token == '00' || token == '000') &&
          hasDecimalCandidate) {
        score -= 40;
      }
      if (!token.contains('.') && token.length <= 1 && hasDecimalCandidate) {
        score -= 20;
      }

      final contextStart = (match.start - 6).clamp(0, lowerChunk.length);
      final contextEnd = (match.end + 6).clamp(0, lowerChunk.length);
      final context = lowerChunk.substring(contextStart, contextEnd);
      if (RegExp(r'(kg|kgs|gm|gms|gram|grams|wt|weight)').hasMatch(context)) {
        score += 80;
      }

      if (bestScore == null ||
          score > bestScore ||
          (score == bestScore && match.start > bestStart)) {
        bestScore = score;
        bestValue = value;
        bestStart = match.start;
      }
    }

    return bestValue;
  }
}
