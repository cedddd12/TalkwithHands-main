import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'package:sign_language_app/games/calculator_question.dart';

void main() {
  test('generates valid and varied questions without immediate repeats', () {
    final random = math.Random(20261108);
    final operationCounts = <String, int>{
      '+': 0,
      '-': 0,
      'x': 0,
      '÷': 0,
    };
    CalculatorQuestion? previous;

    for (var index = 0; index < 1000; index++) {
      final question = CalculatorQuestion.generate(
        random: random,
        previous: previous,
      );
      final expectedAnswer = switch (question.operator) {
        '+' => question.left + question.right,
        '-' => question.left - question.right,
        'x' => question.left * question.right,
        '÷' => question.left ~/ question.right,
        _ => fail('Unexpected operator: ${question.operator}'),
      };

      expect(question.left, inInclusiveRange(0, 20));
      expect(question.right, inInclusiveRange(0, 20));
      expect(question.answer, inInclusiveRange(0, 20));
      expect(question.answer, expectedAnswer);
      expect(question.operator, isNot(previous?.operator));
      if (question.operator == '÷') {
        expect(question.right, greaterThan(0));
        expect(question.left % question.right, 0);
      }
      if (question.operator == '-') {
        expect(question.answer, greaterThanOrEqualTo(0));
      }

      operationCounts.update(question.operator, (count) => count + 1);
      previous = question;
    }

    for (final count in operationCounts.values) {
      expect(count, greaterThan(200));
    }
  });
}
