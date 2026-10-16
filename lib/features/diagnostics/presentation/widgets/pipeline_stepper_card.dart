import 'package:flutter/material.dart';
import '../bloc/diagnostic_runner_state.dart';

class PipelineStepperCard extends StatelessWidget {
  final DiagnosticPhase phase;
  final bool hasFailure;

  const PipelineStepperCard({
    super.key,
    required this.phase,
    required this.hasFailure,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141923),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'OSI / TCP-IP PROBE PIPELINE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStepItem(
                stepIndex: 1,
                label: 'DNS\nResolver',
                layer: 'L3 / L7',
                isActive: phase == DiagnosticPhase.resolvingDns,
                isCompleted: phase == DiagnosticPhase.probingSockets ||
                    phase == DiagnosticPhase.verifyingHttp ||
                    phase == DiagnosticPhase.completed ||
                    (hasFailure && phase != DiagnosticPhase.resolvingDns && phase != DiagnosticPhase.idle),
                isFailed: hasFailure && phase == DiagnosticPhase.resolvingDns,
              ),
              _buildConnector(
                isCompleted: phase == DiagnosticPhase.probingSockets ||
                    phase == DiagnosticPhase.verifyingHttp ||
                    phase == DiagnosticPhase.completed,
              ),
              _buildStepItem(
                stepIndex: 2,
                label: 'TCP / TLS\nSockets',
                layer: 'L4 / L6',
                isActive: phase == DiagnosticPhase.probingSockets,
                isCompleted: phase == DiagnosticPhase.verifyingHttp ||
                    phase == DiagnosticPhase.completed,
                isFailed: hasFailure && phase == DiagnosticPhase.probingSockets,
              ),
              _buildConnector(
                isCompleted: phase == DiagnosticPhase.verifyingHttp ||
                    phase == DiagnosticPhase.completed,
              ),
              _buildStepItem(
                stepIndex: 3,
                label: 'HTTP\nEgress',
                layer: 'L7 App',
                isActive: phase == DiagnosticPhase.verifyingHttp,
                isCompleted: phase == DiagnosticPhase.completed,
                isFailed: hasFailure && phase == DiagnosticPhase.verifyingHttp,
              ),
              _buildConnector(
                isCompleted: phase == DiagnosticPhase.completed,
              ),
              _buildStepItem(
                stepIndex: 4,
                label: 'Verdict\n& Report',
                layer: 'Audit',
                isActive: false,
                isCompleted: phase == DiagnosticPhase.completed,
                isFailed: hasFailure,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConnector({required bool isCompleted}) {
    return Expanded(
      child: Container(
        height: 2,
        color: isCompleted ? Colors.greenAccent : Colors.white12,
      ),
    );
  }

  Widget _buildStepItem({
    required int stepIndex,
    required String label,
    required String layer,
    required bool isActive,
    required bool isCompleted,
    required bool isFailed,
  }) {
    final Color badgeColor;
    final Widget icon;

    if (isFailed) {
      badgeColor = Colors.redAccent;
      icon = const Icon(Icons.close, size: 14, color: Colors.white);
    } else if (isCompleted) {
      badgeColor = Colors.greenAccent;
      icon = const Icon(Icons.check, size: 14, color: Colors.black);
    } else if (isActive) {
      badgeColor = Colors.cyanAccent;
      icon = const SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
        ),
      );
    } else {
      badgeColor = Colors.white24;
      icon = Text(
        '$stepIndex',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white70,
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: badgeColor,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.cyanAccent.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    )
                  ]
                : null,
          ),
          child: Center(child: icon),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive
                ? Colors.cyanAccent
                : (isCompleted ? Colors.white : Colors.white54),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          layer,
          style: const TextStyle(fontSize: 8, color: Colors.white38),
        ),
      ],
    );
  }
}
