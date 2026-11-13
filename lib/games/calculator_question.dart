import 'dart:math' as math;

class CalculatorQuestion {
  final int left;
  final String operator;
  final int right;
  final int answer;

  const CalculatorQuestion({
    required this.left,
    required this.operator,
    required this.right,
    required this.answer,
  });

  String get equation => '$left $operator $right =';

  static CalculatorQuestion generate({
    required math.Random random,
    CalculatorQuestion? previous,
  }) {
    const operators = ['+', '-', 'x', '÷'];
    final availableOperators =
        operators.where((operator) => operator != previous?.operator).toList();
    final operator =
        availableOperators[random.nextInt(availableOperators.length)];

    switch (operator) {
      case '+':
        final left = random.nextInt(19) + 1;
        final right = random.nextInt(20 - left) + 1;
        return CalculatorQuestion(
          left: left,
          operator: operator,
          right: right,
          answer: left + right,
        );
      case '-':
        final left = random.nextInt(19) + 2;
        final right = random.nextInt(left - 1) + 1;
        return CalculatorQuestion(
          left: left,
          operator: operator,
          right: right,
          answer: left - right,
        );
      case 'x':
        final left = random.nextInt(9) + 2;
        final maxRight = 20 ~/ left;
        final right = random.nextInt(maxRight - 1) + 2;
        return CalculatorQuestion(
          left: left,
          operator: operator,
          right: right,
          answer: left * right,
        );
      default:
        final right = random.nextInt(9) + 2;
        final answer = random.nextInt(20 ~/ right) + 1;
        return CalculatorQuestion(
          left: right * answer,
          operator: operator,
          right: right,
          answer: answer,
        );
    }
  }
}
