import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/target_presets.dart';
import '../../domain/models/target_endpoint.dart';
import '../bloc/diagnostic_runner_bloc.dart';
import '../bloc/diagnostic_runner_event.dart';

class TargetSelectorBar extends StatelessWidget {
  final TargetEndpoint selectedTarget;
  final bool isRunning;

  const TargetSelectorBar({
    super.key,
    required this.selectedTarget,
    required this.isRunning,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'CONTROLLED DIAGNOSTIC ENDPOINT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: Colors.white54,
                ),
              ),
              if (selectedTarget.expectTimeoutOrFailure)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.deepOrangeAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Colors.deepOrangeAccent.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Text(
                    'FAULT INJECTION',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.deepOrangeAccent,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          InputDecorator(
            decoration: const InputDecoration(
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Colors.white12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Colors.white12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Colors.blueAccent),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<TargetEndpoint>(
                value: selectedTarget,
                isExpanded: true,
                dropdownColor: const Color(0xFF1E2636),
                items: TargetPresets.controlledEndpoints.map((preset) {
                  return DropdownMenuItem<TargetEndpoint>(
                    value: preset,
                    child: Text(
                      '${preset.name} (${preset.host})',
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: isRunning
                    ? null
                    : (target) {
                        if (target != null) {
                          context
                              .read<DiagnosticRunnerBloc>()
                              .add(DiagnosticTargetSelected(target));
                        }
                      },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Category: ${selectedTarget.category}',
                style: const TextStyle(fontSize: 11, color: Colors.white54),
              ),
              Text(
                'Port: ${selectedTarget.port} / TCP',
                style: const TextStyle(fontSize: 11, color: Colors.white54),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
