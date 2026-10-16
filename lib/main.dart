import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/services/network_probe_engine.dart';
import 'core/services/report_exporter_service.dart';
import 'core/theme/app_theme.dart';
import 'features/diagnostics/presentation/bloc/diagnostic_runner_bloc.dart';
import 'features/diagnostics/presentation/cubit/history_cubit.dart';
import 'features/diagnostics/presentation/cubit/reachability_cubit.dart';
import 'features/diagnostics/presentation/pages/diagnostics_dashboard_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FlutterNetworkDiagnosticsApp());
}

class FlutterNetworkDiagnosticsApp extends StatelessWidget {
  const FlutterNetworkDiagnosticsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final probeEngine = NetworkProbeEngine();
    const reportExporter = ReportExporterService();

    return MultiBlocProvider(
      providers: [
        BlocProvider<ReachabilityCubit>(
          create: (_) => ReachabilityCubit(
            connectivity: Connectivity(),
            probeEngine: probeEngine,
          ),
        ),
        BlocProvider<HistoryCubit>(
          create: (_) => HistoryCubit(exporter: reportExporter),
        ),
        BlocProvider<DiagnosticRunnerBloc>(
          create: (context) => DiagnosticRunnerBloc(
            probeEngine: probeEngine,
            historyCubit: context.read<HistoryCubit>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Flutter Network Diagnostics',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const DiagnosticsDashboardPage(),
      ),
    );
  }
}
