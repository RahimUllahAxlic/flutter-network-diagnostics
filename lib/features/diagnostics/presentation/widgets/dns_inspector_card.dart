import 'package:flutter/material.dart';
import '../../domain/models/dns_record_result.dart';

class DnsInspectorCard extends StatelessWidget {
  final DnsRecordResult? dnsResult;

  const DnsInspectorCard({super.key, required this.dnsResult});

  @override
  Widget build(BuildContext context) {
    if (dnsResult == null) return const SizedBox.shrink();

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'DNS RESOLUTION INSPECTOR',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: Colors.cyanAccent,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${dnsResult!.resolutionDurationMs} ms',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyanAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Queried Host: ${dnsResult!.queriedHost} '
            '(${dnsResult!.ipv4Count} A / ${dnsResult!.ipv6Count} AAAA)',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: dnsResult!.records.map((record) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2636),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: record.isIpv6
                        ? Colors.purpleAccent.withValues(alpha: 0.4)
                        : Colors.blueAccent.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  '${record.isIpv6 ? "AAAA" : "A"} · ${record.address}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: Colors.white,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
