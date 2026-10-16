import 'package:equatable/equatable.dart';

class ResolvedIpEntry extends Equatable {
  final String address;
  final bool isIpv6;
  final bool isLoopbackOrLinkLocal;

  const ResolvedIpEntry({
    required this.address,
    required this.isIpv6,
    required this.isLoopbackOrLinkLocal,
  });

  @override
  List<Object?> get props => [address, isIpv6, isLoopbackOrLinkLocal];
}

class DnsRecordResult extends Equatable {
  final String queriedHost;
  final int resolutionDurationMs;
  final List<ResolvedIpEntry> records;

  const DnsRecordResult({
    required this.queriedHost,
    required this.resolutionDurationMs,
    required this.records,
  });

  int get ipv4Count => records.where((r) => !r.isIpv6).length;
  int get ipv6Count => records.where((r) => r.isIpv6).length;

  @override
  List<Object?> get props => [queriedHost, resolutionDurationMs, records];
}
