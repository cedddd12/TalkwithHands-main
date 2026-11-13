import 'package:flutter/material.dart';

enum CalculatorInputMode { manualKeyboard, recordSign }

const int kSignTimerSeconds = 60;
const int kManualTimerSeconds = 30;

class CalculatorModeChoice extends StatelessWidget {
  final ValueChanged<CalculatorInputMode> onSelected;
  final bool recordSignAvailable;

  const CalculatorModeChoice({
    super.key,
    required this.onSelected,
    this.recordSignAvailable = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1268EA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF72D9FF), width: 3),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'CHOOSE YOUR MODE',
            style: TextStyle(
              color: Color(0xFFFFD43B),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ModeButton(
                  label: 'Manual Keyboard',
                  color: const Color(0xFFFF7900),
                  onPressed: () =>
                      onSelected(CalculatorInputMode.manualKeyboard),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ModeButton(
                  label: 'Record Sign',
                  color: const Color(0xFF1268EA),
                  onPressed: recordSignAvailable
                      ? () => onSelected(CalculatorInputMode.recordSign)
                      : null,
                ),
              ),
            ],
          ),
          if (!recordSignAvailable) ...[
            const SizedBox(height: 8),
            const Text(
              'Camera sign input runs in the Android app',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _ModeButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Material(
        color: onPressed == null ? color.withValues(alpha: 0.4) : color,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
