import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/network_probe_engine.dart';

enum ReachabilityStatus { onlineVerified, captivePortalOrFiltered, offline }

class ReachabilityState extends Equatable {
  final String transportLabel;
  final ReachabilityStatus status;
  final int? lastProbeLatencyMs;
  final DateTime lastChecked;

  const ReachabilityState({
    required this.transportLabel,
    required this.status,
    this.lastProbeLatencyMs,
    required this.lastChecked,
  });

  @override
  List<Object?> get props => [
        transportLabel,
        status,
        lastProbeLatencyMs,
        lastChecked,
      ];
}

class ReachabilityCubit extends Cubit<ReachabilityState> {
  final Connectivity _connectivity;
  final NetworkProbeEngine _probeEngine;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ReachabilityCubit({
    required Connectivity connectivity,
    required NetworkProbeEngine probeEngine,
  })  : _connectivity = connectivity,
        _probeEngine = probeEngine,
        super(
          ReachabilityState(
            transportLabel: 'Initializing...',
            status: ReachabilityStatus.offline,
            lastChecked: DateTime.now().toUtc(),
          ),
        ) {
    _initConnectivityListener();
  }

  Future<void> _initConnectivityListener() async {
    final initial = await _connectivity.checkConnectivity();
    await _evaluateLink(initial);
    _subscription = _connectivity.onConnectivityChanged.listen(_evaluateLink);
  }

  Future<void> refreshReachability() async {
    final current = await _connectivity.checkConnectivity();
    await _evaluateLink(current);
  }

  Future<void> _evaluateLink(List<ConnectivityResult> results) async {
    if (isClosed) return;
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      emit(
        ReachabilityState(
          transportLabel: 'No Active Interface',
          status: ReachabilityStatus.offline,
          lastChecked: DateTime.now().toUtc(),
        ),
      );
      return;
    }

    final transport = _mapTransportLabel(results);

    // Active egress verification against Cloudflare 204 endpoint
    try {
      final probe = await _probeEngine.performHttpProbe(
        'https://cp.cloudflare.com/generate_204',
        timeout: const Duration(seconds: 2),
      );

      if (isClosed) return;
      final isVerified = probe.statusCode == 204;
      emit(
        ReachabilityState(
          transportLabel: transport,
          status: isVerified
              ? ReachabilityStatus.onlineVerified
              : ReachabilityStatus.captivePortalOrFiltered,
          lastProbeLatencyMs: probe.elapsedMs,
          lastChecked: DateTime.now().toUtc(),
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        ReachabilityState(
          transportLabel: transport,
          status: ReachabilityStatus.captivePortalOrFiltered,
          lastChecked: DateTime.now().toUtc(),
        ),
      );
    }
  }

  String _mapTransportLabel(List<ConnectivityResult> results) {
    final labels = <String>[];
    if (results.contains(ConnectivityResult.vpn)) labels.add('VPN Tunnel');
    if (results.contains(ConnectivityResult.wifi)) labels.add('Wi-Fi');
    if (results.contains(ConnectivityResult.mobile)) labels.add('Cellular');
    if (results.contains(ConnectivityResult.ethernet)) labels.add('Ethernet');
    return labels.isEmpty ? 'Unknown Interface' : labels.join(' + ');
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
