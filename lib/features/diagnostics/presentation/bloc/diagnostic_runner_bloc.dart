import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/network_failure.dart';
import '../../../../core/services/network_probe_engine.dart';
import '../../domain/models/diagnostic_report.dart';
import '../../domain/models/latency_sample.dart';
import '../cubit/history_cubit.dart';
import 'diagnostic_runner_event.dart';
import 'diagnostic_runner_state.dart';

class DiagnosticRunnerBloc
    extends Bloc<DiagnosticRunnerEvent, DiagnosticRunnerState> {
  final NetworkProbeEngine _probeEngine;
  final HistoryCubit _historyCubit;

  DiagnosticRunnerBloc({
    required NetworkProbeEngine probeEngine,
    required HistoryCubit historyCubit,
  })  : _probeEngine = probeEngine,
        _historyCubit = historyCubit,
        super(const DiagnosticRunnerState()) {
    on<DiagnosticTargetSelected>(_onTargetSelected);
    on<DiagnosticSuiteStarted>(_onSuiteStarted);
  }

  void _onTargetSelected(
    DiagnosticTargetSelected event,
    Emitter<DiagnosticRunnerState> emit,
  ) {
    if (state.isRunning) return;
    emit(state.copyWith(selectedTarget: event.target, clearResults: true));
  }

  Future<void> _onSuiteStarted(
    DiagnosticSuiteStarted event,
    Emitter<DiagnosticRunnerState> emit,
  ) async {
    if (state.isRunning) return;

    final target = state.selectedTarget;
    final reportId =
        'DIAG-${DateTime.now().millisecondsSinceEpoch.toRadixString(16).toUpperCase()}';

    // Reset state and begin Stage 1: DNS Resolution
    emit(
      state.copyWith(
        clearResults: true,
        phase: DiagnosticPhase.resolvingDns,
      ),
    );

    try {
      final dnsResult = await _probeEngine.performDnsLookup(target.host);
      emit(
        state.copyWith(
          dnsResult: dnsResult,
          phase: DiagnosticPhase.probingSockets,
        ),
      );

      // Stage 2: Sequential TCP + TLS Handshake Latency Probes
      final primaryIp = dnsResult.records.first.address;
      final samples = <LatencySample>[];

      for (int seq = 1; seq <= event.sampleCount; seq++) {
        final sample = await _probeEngine.probeTcpAndTls(
          sequenceNumber: seq,
          targetIpOrHost: primaryIp,
          sniHost: target.host,
          port: target.port,
        );
        samples.add(sample);
        emit(
          state.copyWith(
            liveSamples: List<LatencySample>.from(samples),
            latencyStats: _probeEngine.computeStatistics(samples),
          ),
        );

        if (seq < event.sampleCount) {
          await Future.delayed(const Duration(milliseconds: 180));
        }
      }

      final finalStats = _probeEngine.computeStatistics(samples);

      // If 100% of TCP sockets timed out, fail early with clear timeout telemetry
      if (finalStats.packetLossPercent >= 100.0) {
        const timeoutFailure = NetworkFailure(
          stage: FailureStage.tcpHandshake,
          category: FailureCategory.connectionTimeout,
          technicalMessage:
              '100% TCP SYN packet loss across all 5 socket connection attempts.',
          remediationHint:
              'Target IP is blackholed (e.g., RFC 5737 test net) or outbound TCP port 443 is filtered by a firewall.',
        );
        _finalizeReport(
          emit: emit,
          reportId: reportId,
          transport: event.activeTransportLabel,
          phase: DiagnosticPhase.failed,
          failure: timeoutFailure,
        );
        return;
      }

      // Stage 3: HTTPS Application-Layer Verification
      emit(state.copyWith(phase: DiagnosticPhase.verifyingHttp));
      final httpResult = await _probeEngine.performHttpProbe(
        target.httpsProbeUrl,
      );

      emit(
        state.copyWith(
          httpStatusCode: httpResult.statusCode,
          httpTransferMs: httpResult.elapsedMs,
        ),
      );

      _finalizeReport(
        emit: emit,
        reportId: reportId,
        transport: event.activeTransportLabel,
        phase: DiagnosticPhase.completed,
      );
    } on NetworkFailure catch (failure) {
      _finalizeReport(
        emit: emit,
        reportId: reportId,
        transport: event.activeTransportLabel,
        phase: DiagnosticPhase.failed,
        failure: failure,
      );
    }
  }

  void _finalizeReport({
    required Emitter<DiagnosticRunnerState> emit,
    required String reportId,
    required String transport,
    required DiagnosticPhase phase,
    NetworkFailure? failure,
  }) {
    final report = DiagnosticReport(
      reportId: reportId,
      timestampUtc: DateTime.now().toUtc(),
      target: state.selectedTarget,
      activeTransportType: transport,
      dnsResult: state.dnsResult,
      latencyStats: state.latencyStats,
      httpStatusCode: state.httpStatusCode,
      httpTransferMs: state.httpTransferMs,
      failure: failure,
    );

    _historyCubit.recordReport(report);

    emit(
      state.copyWith(
        phase: phase,
        failure: failure,
        latestReport: report,
      ),
    );
  }
}
