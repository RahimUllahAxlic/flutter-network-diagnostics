import 'package:equatable/equatable.dart';
import '../../../../core/errors/network_failure.dart';
import '../../domain/models/diagnostic_report.dart';
import '../../domain/models/dns_record_result.dart';
import '../../domain/models/latency_sample.dart';
import '../../domain/models/target_endpoint.dart';

enum DiagnosticPhase {
  idle,
  resolvingDns,
  probingSockets,
  verifyingHttp,
  completed,
  failed,
}

class DiagnosticRunnerState extends Equatable {
  final TargetEndpoint selectedTarget;
  final DiagnosticPhase phase;
  final DnsRecordResult? dnsResult;
  final List<LatencySample> liveSamples;
  final LatencyStatistics? latencyStats;
  final int? httpStatusCode;
  final int? httpTransferMs;
  final NetworkFailure? failure;
  final DiagnosticReport? latestReport;

  const DiagnosticRunnerState({
    this.selectedTarget = const TargetEndpoint(
      name: 'Cloudflare Anycast DNS',
      host: 'one.one.one.one',
      port: 443,
      httpsProbeUrl: 'https://1.1.1.1/cdn-cgi/trace',
      category: 'Anycast Edge',
    ),
    this.phase = DiagnosticPhase.idle,
    this.dnsResult,
    this.liveSamples = const [],
    this.latencyStats,
    this.httpStatusCode,
    this.httpTransferMs,
    this.failure,
    this.latestReport,
  });

  bool get isRunning =>
      phase == DiagnosticPhase.resolvingDns ||
      phase == DiagnosticPhase.probingSockets ||
      phase == DiagnosticPhase.verifyingHttp;

  DiagnosticRunnerState copyWith({
    TargetEndpoint? selectedTarget,
    DiagnosticPhase? phase,
    DnsRecordResult? dnsResult,
    List<LatencySample>? liveSamples,
    LatencyStatistics? latencyStats,
    int? httpStatusCode,
    int? httpTransferMs,
    NetworkFailure? failure,
    DiagnosticReport? latestReport,
    bool clearResults = false,
  }) {
    if (clearResults) {
      return DiagnosticRunnerState(
        selectedTarget: selectedTarget ?? this.selectedTarget,
        phase: phase ?? DiagnosticPhase.idle,
      );
    }
    return DiagnosticRunnerState(
      selectedTarget: selectedTarget ?? this.selectedTarget,
      phase: phase ?? this.phase,
      dnsResult: dnsResult ?? this.dnsResult,
      liveSamples: liveSamples ?? this.liveSamples,
      latencyStats: latencyStats ?? this.latencyStats,
      httpStatusCode: httpStatusCode ?? this.httpStatusCode,
      httpTransferMs: httpTransferMs ?? this.httpTransferMs,
      failure: failure ?? this.failure,
      latestReport: latestReport ?? this.latestReport,
    );
  }

  @override
  List<Object?> get props => [
        selectedTarget,
        phase,
        dnsResult,
        liveSamples,
        latencyStats,
        httpStatusCode,
        httpTransferMs,
        failure,
        latestReport,
      ];
}
