import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/background_music_service.dart';
import '../ui/background_music_region.dart';
import 'calculator_answer_pause_glow.dart';
import 'calculator_mode_choice.dart';
import 'calculator_question.dart';

class CalculatorGamePage extends StatefulWidget {
  const CalculatorGamePage({super.key});

  @override
  State<CalculatorGamePage> createState() => _CalculatorGamePageState();
}

class _CalculatorGamePageState extends State<CalculatorGamePage> {
  static const _assetRoot = 'assets/calcuavatars';

  String _display = '0';
  String _expression = '';
  String _manualPreview = '';
  String? _pendingOperator;
  double? _storedValue;
  bool _replaceDisplay = false;
  Timer? _roundTimer;
  Timer? _answerPauseTimer;
  int _secondsLeft = 0;
  CalculatorInputMode? _inputMode;
  int _lives = 3;
  String _roundEquation = '';
  int _roundAnswer = 0;
  CalculatorQuestion? _previousQuestion;
  bool _answerPause = false;
  Color? _answerPauseColor;
  bool _gameOver = false;
  bool _keypadOpen = false;
  int _score = 0;
  int _highScore = 0;
  List<int> _recentScores = [];
  bool _scoreSaved = false;
  bool _newHighScore = false;

  static const Duration _answerPauseDuration = Duration(milliseconds: 1500);

  @override
  void initState() {
    super.initState();
    _newRound();
    unawaited(_loadScoreData());
  }

  void _chooseMode(CalculatorInputMode mode) {
    if (_gameOver || _answerPause || _inputMode != null) return;
    setState(() {
      _inputMode = mode;
      _secondsLeft = mode == CalculatorInputMode.recordSign
          ? kSignTimerSeconds
          : kManualTimerSeconds;
      _keypadOpen = mode == CalculatorInputMode.manualKeyboard;
    });
    _startRoundTimer();
  }

  void _startRoundTimer() {
    _roundTimer?.cancel();
    _roundTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _gameOver || _answerPause) return;
      if (_secondsLeft <= 1) {
        _beginAnswerPause(correct: false, message: 'Time is up!');
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _roundTimer?.cancel();
    _answerPauseTimer?.cancel();
    super.dispose();
  }

  void _newRound() {
    final question = CalculatorQuestion.generate(
      random: math.Random(),
      previous: _previousQuestion,
    );
    _previousQuestion = question;
    _roundEquation = question.equation;
    _roundAnswer = question.answer;
    _inputMode = null;
    _secondsLeft = 0;
    _keypadOpen = false;
    _clearCalculator();
  }

  Future<void> _loadScoreData() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _highScore = preferences.getInt('calculator_high_score') ?? 0;
      _recentScores = preferences
              .getStringList('calculator_recent_scores')
              ?.map(int.tryParse)
              .whereType<int>()
              .take(5)
              .toList() ??
          [];
    });
  }

  Future<void> _saveSessionScore() async {
    if (_scoreSaved) return;
    _scoreSaved = true;
    final preferences = await SharedPreferences.getInstance();
    final previousHighScore = preferences.getInt('calculator_high_score') ?? 0;
    final highScore = math.max(_highScore, _score);
    final recentScores = [_score, ..._recentScores].take(5).toList();
    await preferences.setInt('calculator_high_score', highScore);
    await preferences.setStringList(
      'calculator_recent_scores',
      recentScores.map((score) => score.toString()).toList(),
    );
    if (!mounted) return;
    setState(() {
      _highScore = highScore;
      _recentScores = recentScores;
      _newHighScore = _score > previousHighScore;
    });
  }

  void _showManualKeypad() {
    if (_answerPause || _inputMode != CalculatorInputMode.manualKeyboard) {
      return;
    }
    setState(() => _keypadOpen = true);
  }

  void _closeManualKeypad() {
    if (_answerPause || _inputMode != CalculatorInputMode.manualKeyboard) {
      return;
    }
    setState(() => _keypadOpen = false);
  }

  void _beginAnswerPause({required bool correct, required String message}) {
    if (_gameOver || _answerPause) return;
    _roundTimer?.cancel();
    _roundTimer = null;
    setState(() {
      _answerPause = true;
      _answerPauseColor =
          correct ? const Color(0xFF00F060) : const Color(0xFFFF2020);
      if (correct) {
        _score++;
      } else {
        _lives--;
      }
    });
    _showMessage(message);
    _answerPauseTimer = Timer(_answerPauseDuration, _finishAnswerPause);
  }

  void _finishAnswerPause() {
    if (!mounted || !_answerPause) return;
    setState(() {
      _answerPause = false;
      if (_lives == 0) {
        _gameOver = true;
        _keypadOpen = false;
        _clearCalculator();
        unawaited(_saveSessionScore());
      } else {
        _newRound();
      }
    });
  }

  void _submitManualAnswer() {
    if (_gameOver ||
        _answerPause ||
        _inputMode != CalculatorInputMode.manualKeyboard) {
      return;
    }
    if (_pendingOperator != null && !_replaceDisplay) {
      setState(_resolveOperation);
    }
    final value = double.tryParse(_display);
    if (value == null) {
      _showMessage('Type your answer first.');
      return;
    }
    _beginAnswerPause(
      correct: value == _roundAnswer.toDouble(),
      message:
          value == _roundAnswer.toDouble() ? 'Correct!' : 'Try the next one!',
    );
  }

  void _restartGame() {
    _answerPauseTimer?.cancel();
    setState(() {
      _lives = 3;
      _gameOver = false;
      _answerPause = false;
      _answerPauseColor = null;
      _score = 0;
      _scoreSaved = false;
      _newHighScore = false;
      _previousQuestion = null;
      _newRound();
    });
  }

  void _onCalculatorTap(String value) {
    if (_gameOver ||
        _answerPause ||
        _inputMode != CalculatorInputMode.manualKeyboard) {
      return;
    }
    setState(() {
      if (RegExp(r'^\d$').hasMatch(value)) {
        _inputDigit(value);
      } else if (value == '.') {
        _inputDecimal();
      } else if (value == 'AC') {
        _clearCalculator();
      } else if (value == 'DEL') {
        _deleteLast();
      } else if (value == '=') {
        _resolveOperation();
      } else {
        _chooseOperator(value);
      }
      if (value != 'AC') _updateManualPreview();
    });
  }

  // Keeps the equation preview ("12 + 5") in sync with whatever the person
  // is currently typing for the right-hand operand.
  void _syncExpressionWithDisplay() {
    if (_pendingOperator != null && _storedValue != null) {
      _expression =
          '${_formatNumber(_storedValue!)} $_pendingOperator $_display';
    }
  }

  void _inputDigit(String digit) {
    if (_replaceDisplay || _display == '0') {
      _display = digit;
      _replaceDisplay = false;
    } else if (_display.length < 10) {
      _display += digit;
    }
    _syncExpressionWithDisplay();
  }

  void _inputDecimal() {
    if (_replaceDisplay) {
      _display = '0.';
      _replaceDisplay = false;
    } else if (!_display.contains('.')) {
      _display += '.';
    }
    _syncExpressionWithDisplay();
  }

  void _clearCalculator() {
    _display = '0';
    _expression = '';
    _manualPreview = '';
    _storedValue = null;
    _pendingOperator = null;
    _replaceDisplay = false;
  }

  void _deleteLast() {
    if (_replaceDisplay || _display.length <= 1) {
      _display = '0';
      _replaceDisplay = false;
    } else {
      _display = _display.substring(0, _display.length - 1);
    }
    _syncExpressionWithDisplay();
  }

  void _chooseOperator(String operator) {
    if (_pendingOperator != null && !_replaceDisplay) {
      _resolveOperation();
    }
    _storedValue = _currentValue();
    _pendingOperator = operator;
    _replaceDisplay = true;
    _expression = '${_formatNumber(_storedValue!)} $operator';
  }

  void _resolveOperation() {
    final operator = _pendingOperator;
    final left = _storedValue;
    if (operator == null || left == null) return;

    final right = _currentValue();
    final result = _calculateOperation(operator, left, right);

    _expression = '${_formatNumber(left)} $operator ${_formatNumber(right)} =';
    _display = result.isNaN ? 'Error' : _formatNumber(result);
    _storedValue = null;
    _pendingOperator = null;
    _replaceDisplay = true;
  }

  double _calculateOperation(String operator, double left, double right) {
    return switch (operator) {
      '+' => left + right,
      '-' => left - right,
      'x' => left * right,
      '÷' => right == 0 ? double.nan : left / right,
      _ => right,
    };
  }

  void _updateManualPreview() {
    if (_pendingOperator == null) {
      final value = double.tryParse(_display);
      if (value != null && value.isFinite) {
        _manualPreview = _formatNumber(value);
      }
      return;
    }

    if (_replaceDisplay) return;
    final left = _storedValue;
    final right = double.tryParse(_display);
    if (left == null || right == null || !left.isFinite || !right.isFinite) {
      return;
    }

    final result = _calculateOperation(_pendingOperator!, left, right);
    if (result.isFinite) _manualPreview = _formatNumber(result);
  }

  double _currentValue() => double.tryParse(_display) ?? 0;

  String _formatNumber(double value) {
    if (value.isInfinite || value.isNaN) return 'Error';
    if (value % 1 == 0) return value.toInt().toString();
    return value
        .toStringAsFixed(6)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BackgroundMusicRegion(
        track: BackgroundMusicTrack.calculator,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final canvasWidth =
                constraints.maxWidth.clamp(0.0, 430.0).toDouble();
            final canvasHeight = constraints.maxHeight;
            return Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: SizedBox(
                    width: canvasWidth,
                    height: canvasHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            '$_assetRoot/cal-bg.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.topCenter,
                              child: SizedBox(
                                width: canvasWidth - 20,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildTopBar(context),
                                    const SizedBox(height: 8),
                                    if (_inputMode == null)
                                      CalculatorModeChoice(
                                        onSelected: _chooseMode,
                                        recordSignAvailable: false,
                                      )
                                    else ...[
                                      _buildEquationCard(),
                                      const SizedBox(height: 10),
                                      _buildWebStage(),
                                      const SizedBox(height: 12),
                                      _buildActionButtons(),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                          left: 0,
                          right: 0,
                          bottom: _keypadOpen ? 0 : -(canvasHeight * 0.72),
                          height: canvasHeight * 0.72,
                          child: IgnorePointer(
                            ignoring: !_keypadOpen,
                            child: Material(
                              color: const Color(0xEE071B38),
                              child: SafeArea(
                                child: Column(
                                  children: [
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: IconButton(
                                        tooltip: 'Close keypad',
                                        icon: const Icon(Icons.close_rounded),
                                        color: Colors.white,
                                        onPressed: _closeManualKeypad,
                                      ),
                                    ),
                                    Expanded(child: _buildCalculator()),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          24, 4, 24, 8),
                                      child: _GameActionButton(
                                        icon: Icons.check_circle_rounded,
                                        label: 'Submit Answer',
                                        color: const Color(0xFF1FA64A),
                                        onTap: _submitManualAnswer,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (_gameOver)
                          Positioned.fill(
                            child: Container(
                              color: const Color(0xCC000000),
                              alignment: Alignment.center,
                              child: _buildGameOverCard(),
                            ),
                          ),
                        const _DecorativeAsset(
                          asset: 'peace.png',
                          left: 26,
                          top: 174,
                          width: 48,
                          rotation: -0.18,
                        ),
                        const _DecorativeAsset(
                          asset: 'wssun.png',
                          right: 20,
                          top: 78,
                          width: 76,
                        ),
                        const _DecorativeAsset(
                          asset: 'cloud.png',
                          left: 77,
                          top: 78,
                          width: 48,
                        ),
                        const _DecorativeAsset(
                          asset: 'clouds.png',
                          right: 39,
                          top: 146,
                          width: 48,
                        ),
                        const _DecorativeAsset(
                          asset: 'sign.png',
                          right: 19,
                          top: 274,
                          width: 78,
                          rotation: 0.13,
                        ),
                        const _DecorativeAsset(
                          asset: 'bulb.png',
                          right: 4,
                          top: 386,
                          width: 38,
                          rotation: 0.16,
                        ),
                        const _DecorativeAsset(
                          asset: 'avatar.png',
                          right: 6,
                          bottom: 31,
                          width: 103,
                        ),
                        const _DecorativeAsset(
                          asset: 'flowers.png',
                          left: 4,
                          bottom: 0,
                          width: 72,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _answerPause ? 1 : 0,
                      duration: _answerPause
                          ? const Duration(milliseconds: 150)
                          : const Duration(milliseconds: 250),
                      child: CalculatorAnswerPauseGlow(
                        color: _answerPauseColor,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          _CircleIconButton(
            color: const Color(0xFFF3382E),
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 10),
          _StatusPill(
            key: const ValueKey('calculatorTimer'),
            icon: Icons.timer_rounded,
            label: _inputMode == null ? '--' : '$_secondsLeft',
            color: _inputMode != null && _secondsLeft <= 5
                ? const Color(0xFFF3382E)
                : const Color(0xFF1268EA),
          ),
        ]),
        Row(
            children: List.generate(
                3,
                (index) => Icon(
                      Icons.favorite_rounded,
                      size: 30,
                      color: index < _lives
                          ? const Color(0xFFF3382E)
                          : Colors.white.withValues(alpha: 0.25),
                    ))),
      ],
    );
  }

  Widget _buildGameOverCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFA000),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFD54F), width: 3),
        boxShadow: const [
          BoxShadow(color: Color(0x9900528C), offset: Offset(0, 6))
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('GAME OVER!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            )),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1268EA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Column(children: [
            const Text('YOUR SCORE',
                style: TextStyle(
                  color: Color(0xFFFFD43B),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                )),
            Text('$_score',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                )),
          ]),
        ),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('HIGH SCORE  ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              )),
          Text('$_highScore',
              style: const TextStyle(
                color: Color(0xFF1268EA),
                fontSize: 22,
                fontWeight: FontWeight.w900,
              )),
        ]),
        if (_newHighScore) ...[
          const SizedBox(height: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF35C84A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Text('NEW HIGH SCORE!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                )),
          ),
        ],
        const SizedBox(height: 12),
        const Align(
            alignment: Alignment.centerLeft,
            child: Text('RECENT SCORES',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ))),
        const SizedBox(height: 6),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var index = 0; index < _recentScores.length; index++)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: index == 0 ? const Color(0xFF1268EA) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: index == 0 ? Colors.white : const Color(0xFF1268EA),
                    width: 2,
                  ),
                ),
                child: Text('${_recentScores[index]}',
                    style: TextStyle(
                      color:
                          index == 0 ? Colors.white : const Color(0xFF1268EA),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    )),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _GameActionButton(
          icon: Icons.refresh_rounded,
          label: 'Play Again',
          color: const Color(0xFF1268EA),
          onTap: _restartGame,
        ),
      ]),
    );
  }

  Widget _buildEquationCard() {
    final answer =
        _inputMode == CalculatorInputMode.manualKeyboard ? _manualPreview : '';
    return Container(
      width: 320,
      height: 116,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF1268EA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF72D9FF), width: 3),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('SOLVE THIS!',
            style: TextStyle(
              color: Color(0xFFFFD43B),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            )),
        const SizedBox(height: 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(_roundEquation,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                )),
            const SizedBox(width: 8),
            Container(
              width: 58,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: answer.isEmpty ? const Color(0xFFFFB20D) : Colors.white,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: const Color(0xFFFFD43B), width: 2),
              ),
              child: Text(
                answer,
                key: const ValueKey('calculatorAnswerPreview'),
                style: const TextStyle(
                  color: Color(0xFF1268EA),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _GameActionButton(
        icon: Icons.calculate_rounded,
        label: 'Manual Keypad',
        color: const Color(0xFFFF7900),
        onTap: _showManualKeypad,
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildWebStage() {
    return Container(
      width: 320,
      height: 320,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFA000),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: const Color(0xFFFFD54F), width: 3),
      ),
      child: const Center(
        child: Text(
          'CAMERA\nSign input is available\nin the Android app.',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _buildCalculator() {
    const rows = [
      ['AC', 'DEL', '÷', 'x'],
      ['7', '8', '9', ''],
      ['4', '5', '6', '-'],
      ['3', '2', '1', '+'],
      ['0', '.', '=', ''],
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final calculatorWidth =
            math.min(constraints.maxWidth - 16, 330.0).clamp(0.0, 330.0);
        final buttonGap = calculatorWidth < 285 ? 8.0 : 10.0;
        final horizontalPadding = calculatorWidth < 285 ? 10.0 : 14.0;
        // Estimate a nominal button size only for the height calculation.
        // Actual widths are handed off to Expanded below so the row can
        // never overflow, even by a fraction of a pixel.
        final nominalButtonWidth =
            (calculatorWidth - horizontalPadding * 2 - buttonGap * 3) / 4;
        final buttonHeight =
            (nominalButtonWidth * 0.78 - 2.0).clamp(42.0, 54.0).toDouble();

        return Center(
          child: Container(
            width: calculatorWidth,
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              0,
              horizontalPadding,
              12,
            ),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1E1E1E), width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 8,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 4, top: 6, bottom: 4),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFF242424), width: 1),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (_expression.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            _expression,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.55),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      SizedBox(
                        height: 44,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            _display,
                            maxLines: 1,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              height: 1,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                for (final row in rows) ...[
                  Row(
                    children: [
                      for (final value in row) ...[
                        Expanded(
                          child: value.isEmpty
                              ? const SizedBox.shrink()
                              : _CalcButton(
                                  label: value,
                                  height: buttonHeight,
                                  onTap: () => _onCalculatorTap(value),
                                ),
                        ),
                        if (value != row.last) SizedBox(width: buttonGap),
                      ],
                    ],
                  ),
                  if (row != rows.last) SizedBox(height: buttonGap),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DecorativeAsset extends StatelessWidget {
  final String asset;
  final double? left;
  final double? right;
  final double? top;
  final double? bottom;
  final double width;
  final double rotation;

  const _DecorativeAsset({
    required this.asset,
    this.left,
    this.right,
    this.top,
    this.bottom,
    required this.width,
    this.rotation = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: IgnorePointer(
        child: Transform.rotate(
          angle: rotation,
          child: Image.asset(
            'assets/calcuavatars/$asset',
            width: width,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Icon(icon, color: Colors.white, size: 31),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusPill({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            )),
      ]),
    );
  }
}

class _GameActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _GameActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 58,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 6),
            Flexible(
                child: Text(label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ))),
          ]),
        ),
      ),
    );
  }
}

class _CalcButton extends StatelessWidget {
  final String label;
  final double height;
  final VoidCallback onTap;

  const _CalcButton({
    required this.label,
    required this.height,
    required this.onTap,
  });

  bool get _filled =>
      const {'AC', 'DEL', '÷', 'x', '-', '+', '='}.contains(label);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _filled ? const Color(0xFFFFB20D) : Colors.black,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: const Color(0xFFFFB20D), width: 2),
          ),
          child: FittedBox(
            child: Text(
              label,
              style: TextStyle(
                color: _filled ? Colors.black : Colors.white,
                fontSize: label.length > 1 ? 18 : 28,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
