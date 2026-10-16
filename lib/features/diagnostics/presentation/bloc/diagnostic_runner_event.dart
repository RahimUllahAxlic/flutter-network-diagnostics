import 'package:equatable/equatable.dart';
import '../../domain/models/target_endpoint.dart';

sealed class DiagnosticRunnerEvent extends Equatable {
  const DiagnosticRunnerEvent();

  @override
  List<Object?> get props => [];
}

final class DiagnosticTargetSelected extends DiagnosticRunnerEvent {
  final TargetEndpoint target;
  const DiagnosticTargetSelected(this.target);

  @override
  List<Object?> get props => [target];
}

final class DiagnosticSuiteStarted extends DiagnosticRunnerEvent {
  final String activeTransportLabel;
  final int sampleCount;

  const DiagnosticSuiteStarted({
    required this.activeTransportLabel,
    this.sampleCount = 5,
  });

  @override
  List<Object?> get props => [activeTransportLabel, sampleCount];
}
