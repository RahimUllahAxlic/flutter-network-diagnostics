import 'package:equatable/equatable.dart';

class TargetEndpoint extends Equatable {
  final String name;
  final String host;
  final int port;
  final String httpsProbeUrl;
  final String category;
  final bool expectTimeoutOrFailure;

  const TargetEndpoint({
    required this.name,
    required this.host,
    this.port = 443,
    required this.httpsProbeUrl,
    required this.category,
    this.expectTimeoutOrFailure = false,
  });

  @override
  List<Object?> get props => [
        name,
        host,
        port,
        httpsProbeUrl,
        category,
        expectTimeoutOrFailure,
      ];
}
