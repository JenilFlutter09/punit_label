import '../models/scale_models.dart';

abstract class ScaleTransportAdapter {
  ScaleTransportType get transportType;

  Stream<List<DiscoveredScaleDevice>> get scanResults;

  Stream<ScaleConnectionSnapshot> get connectionState;

  Stream<ScalePacket> get packets;

  Future<void> initialize();

  Future<void> startScan();

  Future<void> stopScan();

  Future<void> connect(DiscoveredScaleDevice device);

  Future<void> disconnect();

  Future<void> dispose();
}
