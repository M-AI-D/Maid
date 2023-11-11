import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:maid/utilities/file_manager.dart';
import 'package:maid/utilities/logger.dart';
import 'package:maid/utilities/message_manager.dart';
import 'package:maid/utilities/memory_manager.dart';

Character character = Character();

class Character {  
  String name = "Maid";
  String prePrompt = "";
  String userAlias = "";
  String responseAlias = "";

  List<Map<String,dynamic>> examples = [];

  bool busy = false;

  Character() {
    resetAll();
  }

  Character.fromMap(Map<String, dynamic> inputJson) {
    name = inputJson["name"] ?? "Unknown";

    if (inputJson.isEmpty) {
      resetAll();
    }

    prePrompt = inputJson["pre_prompt"] ?? "";
    userAlias = inputJson["user_alias"] ?? "";
    responseAlias = inputJson["response_alias"] ?? "";

    final length = inputJson["examples"].length ?? 0;
    examples = List<Map<String,dynamic>>.generate(length, (i) => inputJson["examples"][i]);

    Logger.log("Character created with name: ${inputJson["name"]}");
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> jsonCharacter = {};

    jsonCharacter["name"] = name;
    
    jsonCharacter["pre_prompt"] = prePrompt;
    jsonCharacter["user_alias"] = userAlias;
    jsonCharacter["response_alias"] = responseAlias;
    jsonCharacter["examples"] = examples;

    Logger.log("Character JSON created with name: $name");
    return jsonCharacter;
  }

  void resetAll() async {
    // Reset all the internal state to the defaults
    String jsonString = await rootBundle.loadString('assets/default_character.json');

    Map<String, dynamic> jsonCharacter = json.decode(jsonString);

    prePrompt = jsonCharacter["pre_prompt"] ?? "";
    userAlias = jsonCharacter["user_alias"] ?? "";
    responseAlias = jsonCharacter["response_alias"] ?? "";

    final length = jsonCharacter["examples"].length ?? 0;
    examples = List<Map<String,dynamic>>.generate(length, (i) => jsonCharacter["examples"][i]);

    MemoryManager.save();
  }

  Future<String> saveCharacterToJson(BuildContext context) async {
    try {
      Map<String, dynamic> jsonCharacter = {};

      jsonCharacter["name"] = name;

      jsonCharacter["pre_prompt"] = prePrompt;
      jsonCharacter["user_alias"] = userAlias;
      jsonCharacter["response_alias"] = responseAlias;
      jsonCharacter["examples"] = examples;

      // Convert the map to a JSON string
      String jsonString = json.encode(jsonCharacter);

    
      File? file = await FileManager.save(context, name);

      if (file == null) return "Error saving file";

      await file.writeAsString(jsonString);

      return "Character Successfully Saved to ${file.path}";
    } catch (e) {
      return "Error: $e";
    }
  }

  Future<String> loadCharacterFromJson(BuildContext context) async {
    try{
      File? file = await FileManager.load(context, [".json"]);

      if (file == null) return "Error loading file";

      String jsonString = await file.readAsString();
      if (jsonString.isEmpty) return "Failed to load character";
      
      Map<String, dynamic> jsonCharacter = {};

      jsonCharacter = json.decode(jsonString);
      if (jsonCharacter.isEmpty) {
        resetAll();
        return "Failed to decode character";
      }

      name = jsonCharacter["name"] ?? "";

      prePrompt = jsonCharacter["pre_prompt"] ?? "";
      userAlias = jsonCharacter["user_alias"] ?? "";
      responseAlias = jsonCharacter["response_alias"] ?? "";

      final length = jsonCharacter["examples"].length ?? 0;
      examples = List<Map<String,dynamic>>.generate(length, (i) => jsonCharacter["examples"][i]);
    } catch (e) {
      resetAll();
      return "Error: $e";
    }

    return "Character Successfully Loaded";
  }
  
  String getPrePrompt() {
    String result = prePrompt.isNotEmpty ? prePrompt.trim() : "";

    List<Map<String, dynamic>> history = examples;
    history += MessageManager.getMessages();
    if (history.isNotEmpty) {
      for (var i = 0; i < history.length; i++) {
        var prompt = '${userAlias.trim()} ${history[i]["prompt"].trim()}';
        var response = '${responseAlias.trim()} ${history[i]["response"].trim()}';
        if (prompt.isNotEmpty && response.isNotEmpty) {
          result += "\n$prompt\n$response";
        }
      }
    }

    return result;
  }
}