import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/services/report_exporter_service.dart';
import '../../domain/models/diagnostic_report.dart';

class HistoryState extends Equatable {
  final List<DiagnosticReport> reports;

  const HistoryState({this.reports = const []});

  @override
  List<Object?> get props => [reports];
}

class HistoryCubit extends Cubit<HistoryState> {
  final ReportExporterService _exporter;

  HistoryCubit({required ReportExporterService exporter})
      : _exporter = exporter,
        super(const HistoryState());

  void recordReport(DiagnosticReport report) {
    final updated = [report, ...state.reports].take(30).toList();
    emit(HistoryState(reports: updated));
  }

  void clearHistory() {
    emit(const HistoryState(reports: []));
  }

  Future<void> shareJsonReport(DiagnosticReport report) async {
    final jsonText = _exporter.toSanitizedJson(report);
    await Share.share(
      jsonText,
      subject: 'Network Diagnostic Report ${report.reportId} (JSON)',
    );
  }

  Future<void> shareMarkdownReport(DiagnosticReport report) async {
    final mdText = _exporter.toMarkdownSummary(report);
    await Share.share(
      mdText,
      subject: 'Network Diagnostic Summary ${report.reportId}',
    );
  }
}
