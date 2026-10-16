import '../../features/diagnostics/domain/models/target_endpoint.dart';

class TargetPresets {
  const TargetPresets._();

  /// Controlled, industry-standard diagnostic endpoints.
  /// Includes RFC 5737 TEST-NET-1 (192.0.2.1) to deterministically demonstrate
  /// socket timeout handling without relying on flaky third-party servers.
  static const List<TargetEndpoint> controlledEndpoints = [
    TargetEndpoint(
      name: 'Cloudflare Anycast DNS',
      host: 'one.one.one.one',
      port: 443,
      httpsProbeUrl: 'https://1.1.1.1/cdn-cgi/trace',
      category: 'Anycast Edge',
    ),
    TargetEndpoint(
      name: 'Google Public DNS',
      host: 'dns.google',
      port: 443,
      httpsProbeUrl: 'https://dns.google/resolve?name=example.com&type=A',
      category: 'DoH / Public DNS',
    ),
    TargetEndpoint(
      name: 'Cloudflare Connectivity Check',
      host: 'cp.cloudflare.com',
      port: 443,
      httpsProbeUrl: 'https://cp.cloudflare.com/generate_204',
      category: 'Captive Portal Probe',
    ),
    TargetEndpoint(
      name: 'RFC 5737 Blackhole (Timeout Simulation)',
      host: '192.0.2.1',
      port: 443,
      httpsProbeUrl: 'https://192.0.2.1',
      category: 'Fault Injection',
      expectTimeoutOrFailure: true,
    ),
    TargetEndpoint(
      name: 'NXDOMAIN Fault Simulation',
      host: 'nonexistent.invalid.domain.test',
      port: 443,
      httpsProbeUrl: 'https://nonexistent.invalid.domain.test',
      category: 'Fault Injection',
      expectTimeoutOrFailure: true,
    ),
  ];
}
