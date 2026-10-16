import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/diagnostic_runner_bloc.dart';
import '../bloc/diagnostic_runner_event.dart';
import '../bloc/diagnostic_runner_state.dart';
import '../cubit/history_cubit.dart';
import '../cubit/reachability_cubit.dart';
import '../widgets/dns_inspector_card.dart';
import '../widgets/history_drawer.dart';
import '../widgets/latency_telemetry_card.dart';
import '../widgets/pipeline_stepper_card.dart';
import '../widgets/reachability_banner.dart';
import '../widgets/target_selector_bar.dart';

class DiagnosticsDashboardPage extends StatelessWidget {
  const DiagnosticsDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Network & DNS Observability Suite',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          BlocBuilder<HistoryCubit, HistoryState>(
            builder: (context, historyState) {
              return IconButton(
                tooltip: 'Diagnostic History & Export',
                icon: Badge(
                  isLabelVisible: historyState.reports.isNotEmpty,
                  label: Text('${historyState.reports.length}'),
                  child: const Icon(Icons.history_edu_outlined),
                ),
                onPressed: () => _showHistorySheet(context),
              );
            },
          ),
        ],
      ),
      endDrawer: const HistoryDrawer(),
      body: BlocBuilder<DiagnosticRunnerBloc, DiagnosticRunnerState>(
        builder: (context, runnerState) {
          return ListView(
            padding: const EdgeInsets.only(bottom: 100),
            children: [
              const ReachabilityBanner(),

              // OSI / TCP-IP Pipeline Stepper Card
              PipelineStepperCard(
                phase: runnerState.phase,
                hasFailure: runnerState.failure != null,
              ),

              // Controlled Target Selector Bar
              TargetSelectorBar(
                selectedTarget: runnerState.selectedTarget,
                isRunning: runnerState.isRunning,
              ),

              // Failure / Timeout Alert Box
              if (runnerState.failure != null)
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.redAccent,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'FAULT DETECTED AT ${runnerState.failure!.stage.name.toUpperCase()}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        runnerState.failure!.technicalMessage,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Remediation: ${runnerState.failure!.remediationHint}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

              // DNS Results Card
              DnsInspectorCard(dnsResult: runnerState.dnsResult),

              // Socket & HTTP Telemetry Card
              LatencyTelemetryCard(
                samples: runnerState.liveSamples,
                stats: runnerState.latencyStats,
                httpStatusCode: runnerState.httpStatusCode,
                httpTransferMs: runnerState.httpTransferMs,
              ),

              // Export Bar for Latest Report
              if (runnerState.latestReport != null)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.data_object, size: 18),
                          label: const Text('Export JSON'),
                          onPressed: () => context
                              .read<HistoryCubit>()
                              .shareJsonReport(runnerState.latestReport!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.description_outlined, size: 18),
                          label: const Text('Export Markdown'),
                          onPressed: () => context
                              .read<HistoryCubit>()
                              .shareMarkdownReport(runnerState.latestReport!),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton:
          BlocBuilder<DiagnosticRunnerBloc, DiagnosticRunnerState>(
        builder: (context, state) {
          final transportLabel =
              context.watch<ReachabilityCubit>().state.transportLabel;
          return FloatingActionButton.extended(
            onPressed: state.isRunning
                ? null
                : () {
                    context.read<DiagnosticRunnerBloc>().add(
                          DiagnosticSuiteStarted(
                            activeTransportLabel: transportLabel,
                          ),
                        );
                  },
            backgroundColor: state.isRunning
                ? Colors.grey.shade800
                : Colors.blueAccent.shade700,
            icon: Icon(
              state.isRunning ? Icons.radar : Icons.play_arrow_rounded,
              color: Colors.white,
            ),
            label: Text(
              state.isRunning
                  ? 'Phase: ${state.phase.name}...'
                  : 'Run Diagnostic Suite',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showHistorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141923),
      builder: (_) {
        return BlocProvider.value(
          value: context.read<HistoryCubit>(),
          child: BlocBuilder<HistoryCubit, HistoryState>(
            builder: (context, state) {
              if (state.reports.isEmpty) {
                return const SizedBox(
                  height: 220,
                  child: Center(
                    child: Text('No diagnostic runs recorded in this session.'),
                  ),
                );
              }
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Structured Diagnostic Audit Log',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              context.read<HistoryCubit>().clearHistory(),
                          child: const Text('Clear All'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      itemCount: state.reports.length,
                      separatorBuilder: (_, __) =>
                          const Divider(color: Colors.white12, height: 1),
                      itemBuilder: (context, index) {
                        final r = state.reports[index];
                        return ListTile(
                          leading: Icon(
                            r.isHealthy
                                ? Icons.check_circle_outline
                                : Icons.error_outline,
                            color: r.isHealthy
                                ? Colors.greenAccent
                                : Colors.redAccent,
                          ),
                          title: Text(
                            '${r.target.name} (${r.reportId})',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'DNS: ${r.dnsResult?.resolutionDurationMs ?? "-"}ms · '
                            'Avg TCP: ${r.latencyStats?.avgTcpMs ?? "-"}ms · '
                            'Loss: ${r.latencyStats?.packetLossPercent ?? 100}%',
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.ios_share, size: 18),
                            onPressed: () => context
                                .read<HistoryCubit>()
                                .shareJsonReport(r),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
