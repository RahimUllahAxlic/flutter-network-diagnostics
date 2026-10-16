import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_network_diagnostics/core/constants/target_presets.dart';
import 'package:flutter_network_diagnostics/core/services/network_probe_engine.dart';
import 'package:flutter_network_diagnostics/core/services/report_exporter_service.dart';
import 'package:flutter_network_diagnostics/features/diagnostics/presentation/bloc/diagnostic_runner_bloc.dart';
import 'package:flutter_network_diagnostics/features/diagnostics/presentation/bloc/diagnostic_runner_event.dart';
import 'package:flutter_network_diagnostics/features/diagnostics/presentation/bloc/diagnostic_runner_state.dart';
import 'package:flutter_network_diagnostics/features/diagnostics/presentation/cubit/history_cubit.dart';

void main() {
  group('DiagnosticRunnerBloc', () {
    late HistoryCubit historyCubit;
    late DiagnosticRunnerBloc bloc;

    setUp(() {
      historyCubit = HistoryCubit(exporter: const ReportExporterService());
      bloc = DiagnosticRunnerBloc(
        probeEngine: NetworkProbeEngine(),
        historyCubit: historyCubit,
      );
    });

    tearDown(() {
      bloc.close();
      historyCubit.close();
    });

    blocTest<DiagnosticRunnerBloc, DiagnosticRunnerState>(
      'emits updated selectedTarget and clears previous telemetry when DiagnosticTargetSelected is added',
      build: () => bloc,
      act: (b) => b.add(
        DiagnosticTargetSelected(TargetPresets.controlledEndpoints[1]),
      ),
      expect: () => [
        isA<DiagnosticRunnerState>().having(
          (s) => s.selectedTarget.host,
          'selectedTarget.host',
          'dns.google',
        ),
      ],
    );
  });
}
