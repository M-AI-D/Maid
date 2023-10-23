import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class UserMessage extends StatelessWidget {
  final String message;

  const UserMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: SelectableText(message),
      ),
    );
  }
}

class ResponseMessage extends StatefulWidget {
  final StreamController<String> messageController =
      StreamController<String>.broadcast();
  final StreamController<int> trimController =
      StreamController<int>.broadcast();
  final StreamController<int> finaliseController =
      StreamController<int>.broadcast();

  ResponseMessage({super.key});

  void addMessage(String message) {
    print("{$message}");
    messageController.add(message);
  }

  void trim() {
    trimController.add(0);
  }

  void finalise() {
    finaliseController.add(0);
  }

  @override
  _ResponseMessageState createState() => _ResponseMessageState();
}

class _ResponseMessageState extends State<ResponseMessage> with SingleTickerProviderStateMixin {
  String _message = "";
  String _codeMessage = "";
  bool _finalised = false; // Declare finalised here
  bool _inCodeBox = false;

  @override
  void initState() {
    super.initState();
    widget.messageController.stream.listen((textChunk) {
      setState(() {
        if (textChunk.contains('```')) {
          _inCodeBox = !_inCodeBox;
        } else {
          if (_inCodeBox) {
            _codeMessage += textChunk;
          } else {
            _message += textChunk;
          }
        }
      });
    });

    widget.trimController.stream.listen((_) {
      setState(() {
        _message = _message.trimRight();
        _codeMessage = _codeMessage.trim();
      });
    });

    widget.finaliseController.stream.listen((_) {
      setState(() {
        _finalised = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: !_finalised && _message.isEmpty && _codeMessage.isEmpty
            ? const TypingIndicator()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_message.isNotEmpty) SelectableText(_message),
                  if (_codeMessage.isNotEmpty) CodeBox(code: _codeMessage),
                ],
              ),
      ),
    );
  }

  @override
  void dispose() {
    widget.messageController.close();
    widget.trimController.close();
    super.dispose();
  }
}

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  _TypingIndicatorState createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _repeatingController;
  final List<Interval> _dotIntervals = const [
    Interval(0.25, 0.8),
    Interval(0.35, 0.9),
    Interval(0.45, 1.0),
  ];

  @override
  void initState() {
    super.initState();
    _repeatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          _dotIntervals.length,
          (index) => AnimatedBuilder(
            animation: _repeatingController,
            builder: (context, child) {
              final circleFlashPercent =
                  _dotIntervals[index].transform(_repeatingController.value);
              final circleColorPercent = sin(pi * circleFlashPercent);
              return Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.lerp(
                    Theme.of(context).colorScheme.background,
                    Theme.of(context).colorScheme.secondary,
                    circleColorPercent,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _repeatingController.dispose();
    super.dispose();
  }
}

class CodeBox extends StatelessWidget {
  final String code;

  const CodeBox({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(5),
      ),
      child: SelectableText(
        code,
        style: const TextStyle(fontFamily: 'monospace'),
      ),
    );
  }
}