import 'package:flutter/material.dart';
import 'package:maid/classes/chat_node.dart';
import 'package:maid/providers/character.dart';
import 'package:maid/providers/session.dart';
import 'package:maid/providers/user.dart';

import 'package:maid_ui/maid_ui.dart';
import 'package:provider/provider.dart';

class ChatMessage extends StatefulWidget {
  final ChatRole role;

  const ChatMessage({
    required super.key,
    this.role = ChatRole.assistant,
  });

  @override
  ChatMessageState createState() => ChatMessageState();
}

class ChatMessageState extends State<ChatMessage>
    with SingleTickerProviderStateMixin {
  final List<Widget> _messageWidgets = [];
  late Session session;
  final TextEditingController _messageController = TextEditingController();
  String _message = "";
  bool _finalised = false;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    session = context.read<Session>();

    if (session.chat.messageOf(widget.key!).isNotEmpty) {
      _message = session.chat.messageOf(widget.key!);
      _parseMessage(_message);
      _finalised = true;
    } else {
      session.chat.getMessageStream(widget.key!).stream.listen((textChunk) {
        setState(() {
          _message += textChunk;
          _messageWidgets.clear();
          _parseMessage(_message);
        });
      }).onDone(() { 
        _message = _message.trim();

        _parseMessage(_message);

        session.chat.add(
          widget.key!,
          message: _message, 
          role: widget.role
        );

        session.notify();

        _finalised = true;
      });
    }
  }

  void _parseMessage(String message) {
    _messageWidgets.clear();
    List<String> parts = message.split('```');
    for (int i = 0; i < parts.length; i++) {
      String part = parts[i].trim();
      if (part.isEmpty) continue;

      if (i % 2 == 0) {
        _messageWidgets.add(
          SelectableText(
            part,
            style: const TextStyle(
              fontWeight: FontWeight.normal,
              color: Colors.white,
              fontSize: 16,
            ),
          )
        );
      } else {
        _messageWidgets.addAll([
          const SizedBox(height: 10),
          CodeBox(code: part),
          const SizedBox(height: 10)
        ]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<Session, User, Character>(
      builder: (context, session, user, character, child) {
        int currentIndex = session.chat.indexOf(widget.key!);
        int siblingCount = session.chat.siblingCountOf(widget.key!);
        bool busy = session.isBusy;

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(width: 10.0),
              FutureAvatar(
                image: widget.role == ChatRole.user ? user.profile : character.profile,
                radius: 16,
              ),
              const SizedBox(width: 10.0),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    Color.fromARGB(255, 0, 200, 255),
                    Color.fromARGB(255, 255, 80, 200)
                  ],
                  stops: [0.5, 0.85],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                blendMode: BlendMode
                    .srcIn, // This blend mode applies the shader to the text color.
                child: Text(
                  widget.role == ChatRole.user ? user.name : character.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.normal,
                    color: Colors
                        .white, // This color is needed, but it will be overridden by the shader.
                    fontSize: 20,
                  ),
                ),
              ),
              const Expanded(child: SizedBox()), // Spacer
              if (_finalised) ..._messageOptions(),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  IconButton(
                      padding: const EdgeInsets.all(0),
                      onPressed: () {
                        if (busy) return;
                        session.chat.last(widget.key!);
                        session.notify();
                      },
                      icon: Icon(Icons.arrow_left,
                          color: Theme.of(context).colorScheme.onPrimary)),
                  Text('${currentIndex + 1}/$siblingCount',
                      style: Theme.of(context).textTheme.labelLarge),
                  IconButton(
                    padding: const EdgeInsets.all(0),
                    onPressed: () {
                      if (busy) return;
                      session.chat.next(widget.key!);
                      session.notify();
                    },
                    icon: Icon(Icons.arrow_right,
                        color: Theme.of(context).colorScheme.onPrimary),
                  ),
                ],
              )
            ],
          ),
          Padding(
              // left padding 30 right 10
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _editing ? _editingColumn() : _standardColumn(),
              ))
        ]);
      },
    );
  }

  List<Widget> _messageOptions() {
    return widget.role == ChatRole.user ? _userOptions() : _assistantOptions();
  }

  List<Widget> _userOptions() {
    return [
      IconButton(
        onPressed: () {
          if (session.isBusy) return;
          setState(() {
            _messageController.text = _message;
            _editing = true;
            _finalised = false;
          });
        },
        icon: const Icon(Icons.edit),
      ),
    ];
  }

  List<Widget> _assistantOptions() {
    return [
      IconButton(
        onPressed: () {
          if (session.isBusy) return;
          session.regenerate(widget.key!, context);
          setState(() {});
        },
        icon: const Icon(Icons.refresh),
      ),
    ];
  }

  List<Widget> _editingColumn() {
    final busy = context.watch<Session>().isBusy;

    return [
      TextField(
        controller: _messageController,
        autofocus: true,
        cursorColor: Theme.of(context).colorScheme.secondary,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: "Edit Message",
          fillColor: Theme.of(context).colorScheme.background,
          contentPadding: EdgeInsets.zero,
        ),
        maxLines: null,
        keyboardType: TextInputType.multiline,
      ),
      Row(children: [
        IconButton(
            padding: const EdgeInsets.all(0),
            onPressed: () {
              if (busy) return;
              final inputMessage = _messageController.text;
              setState(() {
                _messageController.text = _message;
                _editing = false;
                _finalised = true;
              });
              session.edit(widget.key!, inputMessage, context);
            },
            icon: const Icon(Icons.done)),
        IconButton(
            padding: const EdgeInsets.all(0),
            onPressed: () {
              setState(() {
                _messageController.text = _message;
                _editing = false;
                _finalised = true;
              });
            },
            icon: const Icon(Icons.close))
      ])
    ];
  }

  List<Widget> _standardColumn() {
    return [
      if (!_finalised && _messageWidgets.isEmpty)
        const TypingIndicator()
      else
        ..._messageWidgets
    ];
  }
}
