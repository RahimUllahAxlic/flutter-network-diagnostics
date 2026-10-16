import 'package:equatable/equatable.dart';

class LatencySample extends Equatable {
  final int sequenceNumber;
  final int? tcpConnectMs;
  final int? tlsHandshakeMs;
  final bool isSuccess;
  final String? errorSummary;

  const LatencySample({
    required this.sequenceNumber,
    this.tcpConnectMs,
    this.tlsHandshakeMs,
    required this.isSuccess,
    this.errorSummary,
  });

  @override
  List<Object?> get props => [
        sequenceNumber,
        tcpConnectMs,
        tlsHandshakeMs,
        isSuccess,
        errorSummary,
      ];
}

class LatencyStatistics extends Equatable {
  final List<LatencySample> samples;
  final double minTcpMs;
  final double avgTcpMs;
  final double p95TcpMs;
  final double jitterMs;
  final double packetLossPercent;
  final int? avgTlsHandshakeMs;
  final String? negotiatedTlsProtocol;

  const LatencyStatistics({
    required this.samples,
    required this.minTcpMs,
    required this.avgTcpMs,
    required this.p95TcpMs,
    required this.jitterMs,
    required this.packetLossPercent,
    this.avgTlsHandshakeMs,
    this.negotiatedTlsProtocol,
  });

  @override
  List<Object?> get props => [
        samples,
        minTcpMs,
        avgTcpMs,
        p95TcpMs,
        jitterMs,
        packetLossPercent,
        avgTlsHandshakeMs,
        negotiatedTlsProtocol,
      ];
}
