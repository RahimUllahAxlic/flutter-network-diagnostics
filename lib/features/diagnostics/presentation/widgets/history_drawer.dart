import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/history_cubit.dart';

class HistoryDrawer extends StatelessWidget {
  const HistoryDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF0B0E14),
      child: SafeArea(
        child: BlocBuilder<HistoryCubit, HistoryState>(
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Diagnostic History',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (state.reports.isNotEmpty)
                        TextButton(
                          onPressed: () =>
                              context.read<HistoryCubit>().clearHistory(),
                          child: const Text('Clear All'),
                        ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white12, height: 1),
                if (state.reports.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text(
                        'No diagnostic runs recorded.',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
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
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Export JSON',
                                icon: const Icon(Icons.data_object, size: 18),
                                onPressed: () => context
                                    .read<HistoryCubit>()
                                    .shareJsonReport(r),
                              ),
                              IconButton(
                                tooltip: 'Export Markdown',
                                icon: const Icon(Icons.description_outlined,
                                    size: 18),
                                onPressed: () => context
                                    .read<HistoryCubit>()
                                    .shareMarkdownReport(r),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
