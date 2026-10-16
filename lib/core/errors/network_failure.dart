import 'package:equatable/equatable.dart';

enum FailureStage { dnsResolution, tcpHandshake, tlsHandshake, httpProbe }

enum FailureCategory {
  nxDomain,
  connectionTimeout,
  connectionRefused,
  tlsCertificateError,
  networkUnreachable,
  unknown,
}

class NetworkFailure extends Equatable {
  final FailureStage stage;
  final FailureCategory category;
  final String technicalMessage;
  final String remediationHint;
  final int? osErrorCode;

  const NetworkFailure({
    required this.stage,
    required this.category,
    required this.technicalMessage,
    required this.remediationHint,
    this.osErrorCode,
  });

  @override
  List<Object?> get props => [
        stage,
        category,
        technicalMessage,
        remediationHint,
        osErrorCode,
      ];
}
