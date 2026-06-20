import 'dart:math' as math;

class FormulaEvaluationException implements Exception {
  final String message;

  const FormulaEvaluationException(this.message);

  @override
  String toString() => message;
}

class FormulaEngine {
  static const _functions = {'log10', 'sqrt', 'sin', 'cos', 'tan', 'abs'};

  double evaluate(String expression, Map<String, double> variables) {
    final tokens = _tokenize(expression);
    final rpn = _toReversePolish(tokens);
    return _evalReversePolish(rpn, variables);
  }

  List<_Token> _tokenize(String expression) {
    final tokens = <_Token>[];
    var index = 0;
    _Token? previous;

    while (index < expression.length) {
      final char = expression[index];
      if (char.trim().isEmpty) {
        index++;
        continue;
      }

      if (_isDigit(char) || char == '.') {
        final start = index;
        index++;
        while (index < expression.length &&
            (_isDigit(expression[index]) ||
                expression[index] == '.' ||
                expression[index].toLowerCase() == 'e' ||
                (expression[index] == '-' &&
                    expression[index - 1].toLowerCase() == 'e') ||
                (expression[index] == '+' &&
                    expression[index - 1].toLowerCase() == 'e'))) {
          index++;
        }
        final value = double.tryParse(expression.substring(start, index));
        if (value == null || !value.isFinite) {
          throw const FormulaEvaluationException('公式包含无效数字');
        }
        tokens.add(_Token.number(value));
        previous = tokens.last;
        continue;
      }

      if (_isLetter(char) || char == '_') {
        final start = index;
        index++;
        while (index < expression.length &&
            (_isLetter(expression[index]) ||
                _isDigit(expression[index]) ||
                expression[index] == '_')) {
          index++;
        }
        final name = expression.substring(start, index);
        final token = _functions.contains(name)
            ? _Token.function(name)
            : _Token.variable(name);
        tokens.add(token);
        previous = token;
        continue;
      }

      if ('+-*/^(),'.contains(char)) {
        final isUnaryMinus =
            char == '-' &&
            (previous == null ||
                previous.type == _TokenType.operator ||
                previous.type == _TokenType.leftParen ||
                previous.type == _TokenType.comma);
        final token = isUnaryMinus
            ? _Token.operator('neg')
            : char == ','
            ? _Token.comma()
            : char == '('
            ? _Token.leftParen()
            : char == ')'
            ? _Token.rightParen()
            : _Token.operator(char);
        tokens.add(token);
        previous = token;
        index++;
        continue;
      }

      throw FormulaEvaluationException('公式包含不支持字符: $char');
    }

    return tokens;
  }

  List<_Token> _toReversePolish(List<_Token> tokens) {
    final output = <_Token>[];
    final operators = <_Token>[];

    for (final token in tokens) {
      switch (token.type) {
        case _TokenType.number:
        case _TokenType.variable:
          output.add(token);
        case _TokenType.function:
          operators.add(token);
        case _TokenType.comma:
          while (operators.isNotEmpty &&
              operators.last.type != _TokenType.leftParen) {
            output.add(operators.removeLast());
          }
          if (operators.isEmpty) {
            throw const FormulaEvaluationException('公式参数分隔符位置错误');
          }
        case _TokenType.operator:
          while (operators.isNotEmpty &&
              operators.last.type == _TokenType.operator &&
              (_precedence(operators.last.value) > _precedence(token.value) ||
                  (_precedence(operators.last.value) ==
                          _precedence(token.value) &&
                      !_isRightAssociative(token.value)))) {
            output.add(operators.removeLast());
          }
          operators.add(token);
        case _TokenType.leftParen:
          operators.add(token);
        case _TokenType.rightParen:
          while (operators.isNotEmpty &&
              operators.last.type != _TokenType.leftParen) {
            output.add(operators.removeLast());
          }
          if (operators.isEmpty) {
            throw const FormulaEvaluationException('公式括号不匹配');
          }
          operators.removeLast();
          if (operators.isNotEmpty &&
              operators.last.type == _TokenType.function) {
            output.add(operators.removeLast());
          }
      }
    }

    while (operators.isNotEmpty) {
      final operator = operators.removeLast();
      if (operator.type == _TokenType.leftParen ||
          operator.type == _TokenType.rightParen) {
        throw const FormulaEvaluationException('公式括号不匹配');
      }
      output.add(operator);
    }

    return output;
  }

  double _evalReversePolish(
    List<_Token> tokens,
    Map<String, double> variables,
  ) {
    final stack = <double>[];
    for (final token in tokens) {
      switch (token.type) {
        case _TokenType.number:
          stack.add(token.numberValue!);
        case _TokenType.variable:
          final value = variables[token.value];
          if (value == null) {
            throw FormulaEvaluationException('公式变量未定义: ${token.value}');
          }
          stack.add(value);
        case _TokenType.operator:
          if (token.value == 'neg') {
            if (stack.isEmpty) {
              throw const FormulaEvaluationException('公式缺少操作数');
            }
            stack.add(-stack.removeLast());
          } else {
            if (stack.length < 2) {
              throw const FormulaEvaluationException('公式缺少操作数');
            }
            final b = stack.removeLast();
            final a = stack.removeLast();
            stack.add(_applyOperator(token.value, a, b));
          }
        case _TokenType.function:
          if (stack.isEmpty) {
            throw const FormulaEvaluationException('函数缺少参数');
          }
          stack.add(_applyFunction(token.value, stack.removeLast()));
        case _TokenType.leftParen:
        case _TokenType.rightParen:
        case _TokenType.comma:
          throw const FormulaEvaluationException('公式结构无效');
      }
    }

    if (stack.length != 1 || !stack.single.isFinite) {
      throw const FormulaEvaluationException('公式计算结果无效');
    }
    return stack.single;
  }

  double _applyOperator(String operator, double a, double b) {
    return switch (operator) {
      '+' => a + b,
      '-' => a - b,
      '*' => a * b,
      '/' => b == 0 ? throw const FormulaEvaluationException('公式发生除零') : a / b,
      '^' => math.pow(a, b).toDouble(),
      _ => throw FormulaEvaluationException('不支持的操作符: $operator'),
    };
  }

  double _applyFunction(String function, double value) {
    return switch (function) {
      'log10' =>
        value <= 0
            ? throw const FormulaEvaluationException('log10 参数必须大于 0')
            : math.log(value) / math.ln10,
      'sqrt' =>
        value < 0
            ? throw const FormulaEvaluationException('sqrt 参数不能小于 0')
            : math.sqrt(value),
      'sin' => math.sin(value),
      'cos' => math.cos(value),
      'tan' => math.tan(value),
      'abs' => value.abs(),
      _ => throw FormulaEvaluationException('不支持的函数: $function'),
    };
  }

  int _precedence(String operator) {
    return switch (operator) {
      'neg' => 4,
      '^' => 3,
      '*' || '/' => 2,
      '+' || '-' => 1,
      _ => 0,
    };
  }

  bool _isRightAssociative(String operator) =>
      operator == '^' || operator == 'neg';

  bool _isDigit(String value) => RegExp(r'[0-9]').hasMatch(value);
  bool _isLetter(String value) => RegExp(r'[A-Za-z]').hasMatch(value);
}

enum _TokenType {
  number,
  variable,
  function,
  operator,
  leftParen,
  rightParen,
  comma,
}

class _Token {
  final _TokenType type;
  final String value;
  final double? numberValue;

  const _Token._(this.type, this.value, [this.numberValue]);

  factory _Token.number(double value) =>
      _Token._(_TokenType.number, value.toString(), value);
  factory _Token.variable(String value) => _Token._(_TokenType.variable, value);
  factory _Token.function(String value) => _Token._(_TokenType.function, value);
  factory _Token.operator(String value) => _Token._(_TokenType.operator, value);
  factory _Token.leftParen() => const _Token._(_TokenType.leftParen, '(');
  factory _Token.rightParen() => const _Token._(_TokenType.rightParen, ')');
  factory _Token.comma() => const _Token._(_TokenType.comma, ',');
}
