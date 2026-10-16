import 'package:flutter/material.dart';
import '../../domain/models/latency_sample.dart';

class LatencyTelemetryCard extends StatelessWidget {
  final List<LatencySample> samples;
  final LatencyStatistics? stats;
  final int? httpStatusCode;
  final int? httpTransferMs;

  const LatencyTelemetryCard({
    super.key,
    required this.samples,
    required this.stats,
    this.httpStatusCode,
    this.httpTransferMs,
  });

  @override
  Widget build(BuildContext context) {
    if (samples.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141923),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TCP / TLS SOCKET & HTTP TELEMETRY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: Colors.amberAccent,
            ),
          ),
          const SizedBox(height: 12),
          if (stats != null)
            Row(
              children: [
                _StatCell(label: 'AVG TCP', value: '${stats!.avgTcpMs} ms'),
                _StatCell(label: 'P95 TCP', value: '${stats!.p95TcpMs} ms'),
                _StatCell(label: 'JITTER', value: '${stats!.jitterMs} ms'),
                _StatCell(
                  label: 'LOSS',
                  value: '${stats!.packetLossPercent}%',
                  isAlert: stats!.packetLossPercent > 0,
                ),
              ],
            ),
          const Divider(color: Colors.white12, height: 20),
          ...samples.map((s) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Probe #${s.sequenceNumber}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      fontFamily: 'monospace',
                    ),
                  ),
                  if (s.isSuccess)
                    Text(
                      'TCP: ${s.tcpConnectMs}ms   |   TLS: ${s.tlsHandshakeMs ?? "-"}ms',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: Colors.greenAccent,
                      ),
                    )
                  else
                    Flexible(
                      child: Text(
                        s.errorSummary ?? 'Socket Timeout',
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: Colors.redAccent,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            );
          }),
          if (httpStatusCode != null) ...[
            const Divider(color: Colors.white12, height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'HTTPS Application Probe',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
                Text(
                  'HTTP $httpStatusCode (${httpTransferMs}ms)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyanAccent,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final bool isAlert;

  const _StatCell({
    required this.label,
    required this.value,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.white54),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isAlert ? Colors.redAccent : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
