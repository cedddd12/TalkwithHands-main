import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_language_app/games/calculator_answer_pause_glow.dart';
import 'package:sign_language_app/games/calculator_game_stub.dart';
import 'package:sign_language_app/games/calculator_mode_choice.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('mode timers are set to 30 seconds and 60 seconds', () {
    expect(kManualTimerSeconds, 30);
    expect(kSignTimerSeconds, 60);
  });

  testWidgets('web keypad previews 18 ÷ 3 as 6', (tester) async {
    await _pumpCalculator(tester);
    await _chooseManual(tester);

    for (final key in ['AC', '1', '8', '÷', '3']) {
      await _tapKey(tester, key);
    }

    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('calculatorAnswerPreview')))
          .data,
      '6',
    );
    expect(find.text('18 ÷ 3'), findsOneWidget);

    await _tapKey(tester, '=');
    expect(find.text('18 ÷ 3 ='), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('calculatorAnswerPreview')))
          .data,
      '6',
    );
  });

  testWidgets('correct answer pauses with green glow before next question',
      (tester) async {
    await _pumpCalculator(tester);
    await _chooseManual(tester);
    final question = _questionText(tester);
    final answer = _questionAnswer(question);
    await _enterInteger(tester, answer);
    await tester.tap(find.text('Submit Answer'));
    await tester.pump();

    expect(_questionText(tester), question);
    expect(
      tester
          .widget<CalculatorAnswerPauseGlow>(
            find.byType(CalculatorAnswerPauseGlow),
          )
          .color,
      const Color(0xFF00F060),
    );
    await tester.pump(const Duration(milliseconds: 1499));
    expect(_questionText(tester), question);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('CHOOSE YOUR MODE'), findsOneWidget);
    expect(find.text(question), findsNothing);
    await _chooseManual(tester);
    expect(_questionText(tester), isNot(question));
    expect(_timerText(tester), '30');
  });

  testWidgets('wrong answer pauses with red glow before next question',
      (tester) async {
    await _pumpCalculator(tester);
    await _chooseManual(tester);
    final question = _questionText(tester);
    final correctAnswer = _questionAnswer(question);
    final wrongAnswer = correctAnswer == 20 ? 19 : correctAnswer + 1;
    await _enterInteger(tester, wrongAnswer);
    await tester.tap(find.text('Submit Answer'));
    await tester.pump();

    expect(_questionText(tester), question);
    expect(
      tester
          .widget<CalculatorAnswerPauseGlow>(
            find.byType(CalculatorAnswerPauseGlow),
          )
          .color,
      const Color(0xFFFF2020),
    );
    await tester.pump(const Duration(milliseconds: 1499));
    expect(_questionText(tester), question);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('CHOOSE YOUR MODE'), findsOneWidget);
    expect(find.text(question), findsNothing);
    await _chooseManual(tester);
    expect(_questionText(tester), isNot(question));
    expect(_timerText(tester), '30');
  });

  testWidgets('mode choice pauses the timer and manual mode gets 30 seconds',
      (tester) async {
    await _pumpCalculator(tester);
    expect(find.text('CHOOSE YOUR MODE'), findsOneWidget);
    expect(
      find.textContaining(RegExp(r'^\d+ [+\-x÷] \d+ =$')),
      findsNothing,
    );
    expect(find.text('Record Sign'), findsOneWidget);
    expect(
        find.text('Camera sign input runs in the Android app'), findsOneWidget);
    await tester.tap(find.text('Record Sign'));
    await tester.pump();
    expect(find.text('CHOOSE YOUR MODE'), findsOneWidget);
    expect(_timerText(tester), '--');

    await tester.pump(const Duration(seconds: 10));
    expect(find.text('CHOOSE YOUR MODE'), findsOneWidget);
    expect(_timerText(tester), '--');

    await _chooseManual(tester);
    expect(_timerText(tester), '30');
    await tester.pump(const Duration(seconds: 1));
    expect(_timerText(tester), '29');
  });

  testWidgets('manual timer expiration uses the red pause then mode choice',
      (tester) async {
    await _pumpCalculator(tester);
    await _chooseManual(tester);
    final question = _questionText(tester);

    await tester.pump(const Duration(seconds: 29));
    expect(_timerText(tester), '1');
    await tester.pump(const Duration(seconds: 1));
    expect(_questionText(tester), question);
    expect(
      tester
          .widget<CalculatorAnswerPauseGlow>(
            find.byType(CalculatorAnswerPauseGlow),
          )
          .color,
      const Color(0xFFFF2020),
    );
    await tester.pump(const Duration(milliseconds: 1199));
    expect(_questionText(tester), question);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('CHOOSE YOUR MODE'), findsOneWidget);
    expect(find.text(question), findsNothing);
    await _chooseManual(tester);
    expect(_questionText(tester), isNot(question));
    expect(_timerText(tester), '30');
  });
}

Future<void> _pumpCalculator(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1024, 768);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    DefaultAssetBundle(
      bundle: _CalculatorTestAssetBundle(),
      child: const MaterialApp(home: CalculatorGamePage()),
    ),
  );
  await tester.pump();
}

Future<void> _chooseManual(WidgetTester tester) async {
  await tester.tap(find.text('Manual Keyboard'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  expect(find.text('CHOOSE YOUR MODE'), findsNothing);
  expect(
    tester.widget<AnimatedPositioned>(find.byType(AnimatedPositioned)).bottom,
    0,
  );
  expect(find.byTooltip('Close keypad'), findsOneWidget);
}

Future<void> _tapKey(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).last);
  await tester.pump();
}

Future<void> _enterInteger(WidgetTester tester, int value) async {
  for (final digit in value.toString().split('')) {
    await _tapKey(tester, digit);
  }
}

String _questionText(WidgetTester tester) {
  return tester
      .widgetList<Text>(find.byType(Text))
      .map((text) => text.data)
      .whereType<String>()
      .firstWhere((value) => RegExp(r'^\d+ [+\-x÷] \d+ =$').hasMatch(value));
}

String _timerText(WidgetTester tester) {
  return tester
      .widgetList<Text>(
        find.descendant(
          of: find.byKey(const ValueKey('calculatorTimer')),
          matching: find.byType(Text),
        ),
      )
      .first
      .data!;
}

int _questionAnswer(String question) {
  final match = RegExp(r'^(\d+) ([+\-x÷]) (\d+) =$').firstMatch(question)!;
  final left = int.parse(match.group(1)!);
  final operator = match.group(2)!;
  final right = int.parse(match.group(3)!);
  return switch (operator) {
    '+' => left + right,
    '-' => left - right,
    'x' => left * right,
    '÷' => left ~/ right,
    _ => throw StateError('Unexpected operator: $operator'),
  };
}

class _CalculatorTestAssetBundle extends CachingAssetBundle {
  static final _fallbackPng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADUlEQVR4nGP4z8AAAAMBAQDJ/pLvAAAAAElFTkSuQmCC',
  );

  @override
  Future<ByteData> load(String key) async {
    if (key == 'assets/calcuavatars/sign.png') {
      return ByteData.sublistView(Uint8List.fromList(_fallbackPng));
    }
    return rootBundle.load(key);
  }
}
