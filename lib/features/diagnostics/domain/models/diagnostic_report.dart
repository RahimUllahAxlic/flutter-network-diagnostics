import 'package:equatable/equatable.dart';
import '../../../../core/errors/network_failure.dart';
import 'dns_record_result.dart';
import 'latency_sample.dart';
import 'target_endpoint.dart';

class DiagnosticReport extends Equatable {
  final String reportId;
  final DateTime timestampUtc;
  final TargetEndpoint target;
  final String activeTransportType;
  final DnsRecordResult? dnsResult;
  final LatencyStatistics? latencyStats;
  final int? httpStatusCode;
  final int? httpTransferMs;
  final NetworkFailure? failure;

  const DiagnosticReport({
    required this.reportId,
    required this.timestampUtc,
    required this.target,
    required this.activeTransportType,
    this.dnsResult,
    this.latencyStats,
    this.httpStatusCode,
    this.httpTransferMs,
    this.failure,
  });

  bool get isHealthy =>
      failure == null &&
      (latencyStats?.packetLossPercent ?? 100.0) < 50.0 &&
      (httpStatusCode != null && httpStatusCode! >= 200 && httpStatusCode! < 400);

  @override
  List<Object?> get props => [
        reportId,
        timestampUtc,
        target,
        activeTransportType,
        dnsResult,
        latencyStats,
        httpStatusCode,
        httpTransferMs,
        failure,
      ];
}
