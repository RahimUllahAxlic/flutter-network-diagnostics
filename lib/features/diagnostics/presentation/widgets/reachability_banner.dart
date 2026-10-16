import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/reachability_cubit.dart';

class ReachabilityBanner extends StatelessWidget {
  const ReachabilityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReachabilityCubit, ReachabilityState>(
      builder: (context, state) {
        final (color, icon, statusText) = switch (state.status) {
          ReachabilityStatus.onlineVerified => (
              Colors.greenAccent,
              Icons.verified_user_outlined,
              'EGRESS VERIFIED (HTTP 204)'
            ),
          ReachabilityStatus.captivePortalOrFiltered => (
              Colors.orangeAccent,
              Icons.warning_amber_rounded,
              'CAPTIVE PORTAL / RESTRICTED EGRESS'
            ),
          ReachabilityStatus.offline => (
              Colors.redAccent,
              Icons.wifi_off_rounded,
              'INTERFACE OFFLINE'
            ),
        };

        return Container(
          margin: const EdgeInsets.fromLTRB(14, 8, 14, 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF141923),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Active Link: ${state.transportLabel}'
                      '${state.lastProbeLatencyMs != null ? " · Check RTT: ${state.lastProbeLatencyMs}ms" : ""}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Re-verify Link Reachability',
                icon: const Icon(Icons.refresh, size: 18),
                onPressed: () =>
                    context.read<ReachabilityCubit>().refreshReachability(),
              ),
            ],
          ),
        );
      },
    );
  }
}
