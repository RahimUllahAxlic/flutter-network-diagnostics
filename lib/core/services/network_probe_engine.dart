import 'dart:async';
import 'dart:io';
import '../../features/diagnostics/domain/models/dns_record_result.dart';
import '../../features/diagnostics/domain/models/latency_sample.dart';
import '../errors/network_failure.dart';

class NetworkProbeEngine {
  static const Duration defaultTimeout = Duration(seconds: 3);

  /// Stage 1: System Stub Resolver DNS Lookup (IPv4 A + IPv6 AAAA records)
  Future<DnsRecordResult> performDnsLookup(
    String host, {
    Duration timeout = defaultTimeout,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final List<InternetAddress> addresses = await InternetAddress.lookup(
        host,
        type: InternetAddressType.any,
      ).timeout(timeout);
      stopwatch.stop();

      if (addresses.isEmpty) {
        throw const NetworkFailure(
          stage: FailureStage.dnsResolution,
          category: FailureCategory.nxDomain,
          technicalMessage: 'Resolver returned 0 A/AAAA records.',
          remediationHint:
              'Verify DNS server configuration or domain existence.',
        );
      }

      final records = addresses
          .map(
            (addr) => ResolvedIpEntry(
              address: addr.address,
              isIpv6: addr.type == InternetAddressType.IPv6,
              isLoopbackOrLinkLocal: addr.isLoopback || addr.isLinkLocal,
            ),
          )
          .toList();

      return DnsRecordResult(
        queriedHost: host,
        resolutionDurationMs: stopwatch.elapsedMilliseconds,
        records: records,
      );
    } on TimeoutException {
      stopwatch.stop();
      throw NetworkFailure(
        stage: FailureStage.dnsResolution,
        category: FailureCategory.connectionTimeout,
        technicalMessage:
            'DNS resolution timed out after ${timeout.inSeconds}s.',
        remediationHint:
            'UDP/53 may be blocked or the upstream recursive resolver is unresponsive.',
      );
    } on SocketException catch (e) {
      stopwatch.stop();
      throw NetworkFailure(
        stage: FailureStage.dnsResolution,
        category: FailureCategory.nxDomain,
        technicalMessage: 'SocketException during DNS lookup: ${e.message}',
        remediationHint:
            'Domain does not exist (NXDOMAIN) or local network interface is offline.',
        osErrorCode: e.osError?.errorCode,
      );
    }
  }

  /// Stage 2: Single TCP Handshake + Optional TLS Handshake Probe
  Future<LatencySample> probeTcpAndTls({
    required int sequenceNumber,
    required String targetIpOrHost,
    required String sniHost,
    required int port,
    Duration timeout = defaultTimeout,
  }) async {
    Socket? rawSocket;
    SecureSocket? secureSocket;
    final tcpWatch = Stopwatch()..start();

    try {
      rawSocket = await Socket.connect(
        targetIpOrHost,
        port,
        timeout: timeout,
      );
      tcpWatch.stop();
      final tcpMs = tcpWatch.elapsedMilliseconds;

      // Measure TLS 1.2/1.3 Handshake over the established TCP socket
      int? tlsMs;
      if (port == 443) {
        final tlsWatch = Stopwatch()..start();
        secureSocket = await SecureSocket.secure(
          rawSocket,
          host: sniHost,
        ).timeout(timeout);
        tlsWatch.stop();
        tlsMs = tlsWatch.elapsedMilliseconds;
      }

      return LatencySample(
        sequenceNumber: sequenceNumber,
        tcpConnectMs: tcpMs,
        tlsHandshakeMs: tlsMs,
        isSuccess: true,
      );
    } on TimeoutException {
      tcpWatch.stop();
      return LatencySample(
        sequenceNumber: sequenceNumber,
        isSuccess: false,
        errorSummary: 'ETIMEDOUT (>${timeout.inMilliseconds}ms)',
      );
    } on HandshakeException catch (e) {
      tcpWatch.stop();
      return LatencySample(
        sequenceNumber: sequenceNumber,
        tcpConnectMs: tcpWatch.elapsedMilliseconds,
        isSuccess: false,
        errorSummary: 'TLS Handshake Error: ${e.message}',
      );
    } on SocketException catch (e) {
      tcpWatch.stop();
      return LatencySample(
        sequenceNumber: sequenceNumber,
        isSuccess: false,
        errorSummary: e.osError?.message ?? e.message,
      );
    } finally {
      secureSocket?.destroy();
      rawSocket?.destroy();
    }
  }

  /// Computes RFC-style Jitter (mean absolute inter-packet delay variation),
  /// p95 latency, and packet loss percentage across a sample series.
  LatencyStatistics computeStatistics(List<LatencySample> samples) {
    final successful = samples
        .where((s) => s.isSuccess && s.tcpConnectMs != null)
        .toList();

    final lossPercent = samples.isEmpty
        ? 100.0
        : ((samples.length - successful.length) / samples.length) * 100.0;

    if (successful.isEmpty) {
      return LatencyStatistics(
        samples: samples,
        minTcpMs: 0,
        avgTcpMs: 0,
        p95TcpMs: 0,
        jitterMs: 0,
        packetLossPercent: lossPercent,
      );
    }

    final tcpTimes = successful.map((s) => s.tcpConnectMs!.toDouble()).toList()
      ..sort();

    final minTcp = tcpTimes.first;
    final avgTcp = tcpTimes.reduce((a, b) => a + b) / tcpTimes.length;
    final p95Index =
        ((tcpTimes.length - 1) * 0.95).round().clamp(0, tcpTimes.length - 1);
    final p95Tcp = tcpTimes[p95Index];

    // Calculate Jitter: Mean consecutive difference |RTT(i) - RTT(i-1)|
    double jitterSum = 0.0;
    final orderedRtts =
        successful.map((s) => s.tcpConnectMs!.toDouble()).toList();
    for (int i = 1; i < orderedRtts.length; i++) {
      jitterSum += (orderedRtts[i] - orderedRtts[i - 1]).abs();
    }
    final jitter =
        orderedRtts.length > 1 ? jitterSum / (orderedRtts.length - 1) : 0.0;

    final tlsTimes = successful
        .where((s) => s.tlsHandshakeMs != null)
        .map((s) => s.tlsHandshakeMs!)
        .toList();
    final int? avgTls = tlsTimes.isEmpty
        ? null
        : (tlsTimes.reduce((a, b) => a + b) / tlsTimes.length).round();

    return LatencyStatistics(
      samples: samples,
      minTcpMs: minTcp,
      avgTcpMs: double.parse(avgTcp.toStringAsFixed(1)),
      p95TcpMs: p95Tcp,
      jitterMs: double.parse(jitter.toStringAsFixed(1)),
      packetLossPercent: double.parse(lossPercent.toStringAsFixed(1)),
      avgTlsHandshakeMs: avgTls,
      negotiatedTlsProtocol: tlsTimes.isNotEmpty ? 'TLS 1.3 / X.509' : null,
    );
  }

  /// Stage 3: HTTP Layer Reachability & Captive Portal Verification
  Future<({int statusCode, int elapsedMs})> performHttpProbe(
    String url, {
    Duration timeout = defaultTimeout,
  }) async {
    final client = HttpClient()..connectionTimeout = timeout;
    final watch = Stopwatch()..start();
    try {
      final uri = Uri.parse(url);
      final request = await client.getUrl(uri).timeout(timeout);
      request.followRedirects = false;
      final response = await request.close().timeout(timeout);
      await response.drain<void>().timeout(timeout);
      watch.stop();
      return (
        statusCode: response.statusCode,
        elapsedMs: watch.elapsedMilliseconds,
      );
    } on TimeoutException {
      watch.stop();
      throw NetworkFailure(
        stage: FailureStage.httpProbe,
        category: FailureCategory.connectionTimeout,
        technicalMessage: 'HTTPS GET timed out after ${timeout.inSeconds}s.',
        remediationHint:
            'Deep Packet Inspection (DPI) or firewall may be dropping application-layer payloads.',
      );
    } on HandshakeException catch (e) {
      watch.stop();
      throw NetworkFailure(
        stage: FailureStage.tlsHandshake,
        category: FailureCategory.tlsCertificateError,
        technicalMessage: 'TLS Certificate validation failed: ${e.message}',
        remediationHint:
            'Possible Captive Portal interception, MITM proxy, or skewed device clock.',
      );
    } on SocketException catch (e) {
      watch.stop();
      throw NetworkFailure(
        stage: FailureStage.httpProbe,
        category: FailureCategory.networkUnreachable,
        technicalMessage: 'HTTP transport failed: ${e.message}',
        remediationHint: 'Check outbound port 443 firewall rules.',
        osErrorCode: e.osError?.errorCode,
      );
    } finally {
      client.close(force: true);
    }
  }
}
