import 'dart:convert';
import '../../features/diagnostics/domain/models/diagnostic_report.dart';

class ReportExporterService {
  const ReportExporterService();

  String toSanitizedJson(DiagnosticReport report) {
    final payload = {
      'schema_version': '1.0.0',
      'privacy_notice':
          'Zero-PII Telemetry: Local interface IPs, Wi-Fi BSSID/SSID, and MAC identifiers are intentionally omitted.',
      'report_id': report.reportId,
      'timestamp_utc': report.timestampUtc.toIso8601String(),
      'transport_layer': report.activeTransportType,
      'target': {
        'name': report.target.name,
        'host': report.target.host,
        'port': report.target.port,
        'category': report.target.category,
      },
      'health_verdict': report.isHealthy ? 'HEALTHY' : 'DEGRADED_OR_FAILED',
      'dns_telemetry': report.dnsResult == null
          ? null
          : {
              'resolution_ms': report.dnsResult!.resolutionDurationMs,
              'ipv4_count': report.dnsResult!.ipv4Count,
              'ipv6_count': report.dnsResult!.ipv6Count,
              'resolved_records': report.dnsResult!.records
                  .map((r) => {'ip': r.address, 'ipv6': r.isIpv6})
                  .toList(),
            },
      'socket_telemetry': report.latencyStats == null
          ? null
          : {
              'min_tcp_rtt_ms': report.latencyStats!.minTcpMs,
              'avg_tcp_rtt_ms': report.latencyStats!.avgTcpMs,
              'p95_tcp_rtt_ms': report.latencyStats!.p95TcpMs,
              'jitter_ms': report.latencyStats!.jitterMs,
              'packet_loss_pct': report.latencyStats!.packetLossPercent,
              'avg_tls_handshake_ms': report.latencyStats!.avgTlsHandshakeMs,
            },
      'http_probe': {
        'status_code': report.httpStatusCode,
        'transfer_ms': report.httpTransferMs,
      },
      'failure_diagnostics': report.failure == null
          ? null
          : {
              'stage': report.failure!.stage.name,
              'category': report.failure!.category.name,
              'technical_message': report.failure!.technicalMessage,
              'remediation_hint': report.failure!.remediationHint,
            },
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  String toMarkdownSummary(DiagnosticReport report) {
    final buffer = StringBuffer()
      ..writeln('# Network Diagnostic Report (${report.reportId})')
      ..writeln('- **Timestamp (UTC):** `${report.timestampUtc.toIso8601String()}`')
      ..writeln('- **Target Endpoint:** `${report.target.host}:${report.target.port}` (${report.target.name})')
      ..writeln('- **Active Transport:** `${report.activeTransportType}`')
      ..writeln('- **Overall Verdict:** **${report.isHealthy ? "PASS" : "FAIL"}**\n');

    if (report.dnsResult != null) {
      buffer
        ..writeln('## 1. DNS Resolution')
        ..writeln('- **Lookup Time:** `${report.dnsResult!.resolutionDurationMs} ms`')
        ..writeln('- **Records:** ${report.dnsResult!.ipv4Count} IPv4 (A), ${report.dnsResult!.ipv6Count} IPv6 (AAAA)')
        ..writeln('- **Resolved IPs:** `${report.dnsResult!.records.map((e) => e.address).join(", ")}`\n');
    }

    if (report.latencyStats != null) {
      final s = report.latencyStats!;
      buffer
        ..writeln('## 2. TCP / TLS Socket Telemetry')
        ..writeln('- **TCP RTT (Min / Avg / p95):** `${s.minTcpMs} ms` / `${s.avgTcpMs} ms` / `${s.p95TcpMs} ms`')
        ..writeln('- **Jitter:** `${s.jitterMs} ms`')
        ..writeln('- **Packet Loss:** `${s.packetLossPercent}%`')
        ..writeln('- **Avg TLS Handshake:** `${s.avgTlsHandshakeMs ?? "N/A"} ms`\n');
    }

    if (report.failure != null) {
      buffer
        ..writeln('## 3. Root-Cause Failure Analysis')
        ..writeln('- **Failed Stage:** `${report.failure!.stage.name}`')
        ..writeln('- **Error Category:** `${report.failure!.category.name}`')
        ..writeln('- **Detail:** ${report.failure!.technicalMessage}')
        ..writeln('- **Remediation:** ${report.failure!.remediationHint}');
    }

    return buffer.toString();
  }
}
