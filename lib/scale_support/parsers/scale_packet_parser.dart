import '../models/scale_models.dart';

abstract class ScalePacketParser {
  const ScalePacketParser();

  String get id;

  double? parse(ScalePacket packet);
}
