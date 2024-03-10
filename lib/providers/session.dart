import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:maid/static/logger.dart';
import 'package:maid/classes/chat_node.dart';
import 'package:maid/static/generation_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Session extends ChangeNotifier {
  bool _busy = false;
  ChatNode _root = ChatNode(key: UniqueKey());
  ChatNode? tail;
  String _messageBuffer = "";

  bool get isBusy => _busy;

  String get rootMessage {
    final message = getFirstUserMessage();
    if (message != null) {
      _root.message = message;
    }
    return _root.message;
  }

  Key get key => _root.key;

  set busy(bool value) {
    _busy = value;
    notifyListeners();
  }

  void init() async {
    Logger.log("Session Initialised");

    final prefs = await SharedPreferences.getInstance();

    Map<String, dynamic> lastSession =
        json.decode(prefs.getString("last_session") ?? "{}") ?? {};

    if (lastSession.isNotEmpty) {
      fromMap(lastSession);
    } else {
      newSession();
    }
  }

  Session() {
    newSession();
  }

  Session.fromMap(Map<String, dynamic> inputJson) {
    fromMap(inputJson);
  }

  void _save() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString("last_session", json.encode(toMap()));
    });
  }

  void newSession() {
    final key = UniqueKey();
    _root = ChatNode(key: key);
    _root.message = "New Chat";
    tail = null;
    notifyListeners();
  }

  void fromMap(Map<String, dynamic> inputJson) {
    _root = ChatNode.fromMap(inputJson);
    tail = _root.findTail();
    notifyListeners();
  }

  Map<String, dynamic> toMap() {
    return _root.toMap();
  }

  String getMessage(Key key) {
    return _root.find(key)?.message ?? "";
  }

  String? getFirstUserMessage() {
    var current = _root;
    while (current.currentChild != null) {
      current = current.find(current.currentChild!)!;
      if (current.userGenerated) {
        return current.message;
      }
    }
    return null;
  }

  void setRootMessage(String message) {
    _root.message = message;
    notifyListeners();
  }

  Future<void> add(Key key,
      {String message = "",
      bool userGenerated = false,
      bool notify = true}) async {
    final node =
        ChatNode(key: key, message: message, userGenerated: userGenerated);

    var found = _root.find(key);
    if (found != null) {
      found.message = message;
    } else {
      tail ??= _root.findTail();

      tail!.children.add(node);
      tail!.currentChild = key;
      tail = tail!.findTail();
    }

    if (notify) {
      notifyListeners();
    }
  }

  void remove(Key key) {
    var parent = _root.getParent(key);
    if (parent != null) {
      parent.children.removeWhere((element) => element.key == key);
      tail = _root.findTail();
    }
    notifyListeners();
  }

  void stream(String? message) async {
    if (message == null) {
      finalise();
    } else {
      _messageBuffer += message;
      tail ??= _root.findTail();

      if (!(tail!.messageController.isClosed)) {
        tail!.messageController.add(_messageBuffer);
        _messageBuffer = "";
      }

      tail!.message += message;
    }
  }

  void regenerate(Key key, BuildContext context) {
    var parent = _root.getParent(key);
    if (parent == null) {
      return;
    } else {
      parent.currentChild = null;
      tail = _root.findTail();
      add(UniqueKey(), userGenerated: false);
      notifyListeners();
      GenerationManager.prompt(parent.message, context);
    }
  }

  void edit(Key key, BuildContext context, String message) {
    var parent = _root.getParent(key);
    if (parent != null) {
      parent.currentChild = null;
      tail = _root.findTail();
    }
    add(UniqueKey(), userGenerated: true, message: message);
    add(UniqueKey(), userGenerated: false);
    notifyListeners();
    GenerationManager.prompt(message, context);
  }

  void finalise() {
    _busy = false;

    tail ??= _root.findTail();

    if (!(tail!.finaliseController.isClosed)) {
      tail!.finaliseController.add(0);
    }

    _save();
    notifyListeners();
  }

  void next(Key key) {
    var parent = _root.getParent(key);
    if (parent != null) {
      if (parent.currentChild == null) {
        parent.currentChild = key;
      } else {
        var currentChildIndex = parent.children
            .indexWhere((element) => element.key == parent.currentChild);
        if (currentChildIndex < parent.children.length - 1) {
          parent.currentChild = parent.children[currentChildIndex + 1].key;
          tail = _root.findTail();
        }
      }
    }

    notifyListeners();
  }

  void last(Key key) {
    var parent = _root.getParent(key);
    if (parent != null) {
      if (parent.currentChild == null) {
        parent.currentChild = key;
      } else {
        var currentChildIndex = parent.children
            .indexWhere((element) => element.key == parent.currentChild);
        if (currentChildIndex > 0) {
          parent.currentChild = parent.children[currentChildIndex - 1].key;
          tail = _root.findTail();
        }
      }
    }

    notifyListeners();
  }

  int siblingCount(Key key) {
    var parent = _root.getParent(key);
    if (parent != null) {
      return parent.children.length;
    } else {
      return 0;
    }
  }

  int index(Key key) {
    var parent = _root.getParent(key);
    if (parent != null) {
      return parent.children.indexWhere((element) => element.key == key);
    } else {
      return 0;
    }
  }

  Map<Key, bool> history() {
    final Map<Key, bool> history = {};
    var current = _root;

    while (current.currentChild != null) {
      current = current.find(current.currentChild!)!;
      history[current.key] = current.userGenerated;
    }

    return history;
  }

  List<Map<String, dynamic>> getMessages() {
    final List<Map<String, dynamic>> messages = [];
    var current = _root;

    while (current.currentChild != null) {
      current = current.find(current.currentChild!)!;
      String role;
      if (current.userGenerated) {
        role = "user";
      } else {
        role = "assistant";
      }
      messages.add({"role": role, "content": current.message});
    }

    if (messages.isNotEmpty) {
      messages.remove(messages.last); //remove last message
    }

    return messages;
  }

  StreamController<String> getMessageStream(Key key) {
    return _root.find(key)?.messageController ??
        StreamController<String>.broadcast();
  }

  StreamController<int> getFinaliseStream(Key key) {
    return _root.find(key)?.finaliseController ??
        StreamController<int>.broadcast();
  }
}
