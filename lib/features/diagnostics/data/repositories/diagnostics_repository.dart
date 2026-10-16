import '../../../../core/services/network_probe_engine.dart';
import '../../domain/models/dns_record_result.dart';
import '../../domain/models/latency_sample.dart';

abstract class IDiagnosticsRepository {
  Future<DnsRecordResult> resolveDns(String host);
  Future<LatencySample> probeTcpAndTls({
    required int sequenceNumber,
    required String targetIpOrHost,
    required String sniHost,
    required int port,
  });
  LatencyStatistics computeStatistics(List<LatencySample> samples);
  Future<({int statusCode, int elapsedMs})> performHttpProbe(String url);
}

class DiagnosticsRepository implements IDiagnosticsRepository {
  final NetworkProbeEngine _probeEngine;

  DiagnosticsRepository({required NetworkProbeEngine probeEngine})
      : _probeEngine = probeEngine;

  @override
  Future<DnsRecordResult> resolveDns(String host) {
    return _probeEngine.performDnsLookup(host);
  }

  @override
  Future<LatencySample> probeTcpAndTls({
    required int sequenceNumber,
    required String targetIpOrHost,
    required String sniHost,
    required int port,
  }) {
    return _probeEngine.probeTcpAndTls(
      sequenceNumber: sequenceNumber,
      targetIpOrHost: targetIpOrHost,
      sniHost: sniHost,
      port: port,
    );
  }

  @override
  LatencyStatistics computeStatistics(List<LatencySample> samples) {
    return _probeEngine.computeStatistics(samples);
  }

  @override
  Future<({int statusCode, int elapsedMs})> performHttpProbe(String url) {
    return _probeEngine.performHttpProbe(url);
  }
}
