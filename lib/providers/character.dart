import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:maid/static/file_manager.dart';
import 'package:maid/static/logger.dart';
import 'package:image/image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Character extends ChangeNotifier {
  File _profile = File("/assets/default_profile.png");
  String _name = "Maid";
  String _prePrompt = "";
  String _userAlias = "";
  String _responseAlias = "";

  bool _useExamples = true;
  List<Map<String,dynamic>> _examples = [];

  void newCharacter() {
    final key = UniqueKey().toString();
    _name = "New Character $key";
    resetAll();
  }

  void notify() {
    notifyListeners();
  }

  void init() async {
    Logger.log("Character Initialised");

    final prefs = await SharedPreferences.getInstance();

    Map<String, dynamic> lastCharacter = json.decode(prefs.getString("last_character") ?? "{}");

    if (lastCharacter.isNotEmpty) {
      Logger.log(lastCharacter.toString());
      fromMap(lastCharacter);
    } else {
      resetAll();
    }
  }

  void fromMap(Map<String, dynamic> inputJson) async {
    if (inputJson["profile"] != null) {
      _profile = File(inputJson["profile"]);
    } else {
      Directory docDir = await getApplicationDocumentsDirectory();
      String filePath = '${docDir.path}/default_profile.png';

      File newProfileFile = File(filePath);
      if (!await newProfileFile.exists()) {
        ByteData data = await rootBundle.load('assets/default_profile.png');
        List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await newProfileFile.writeAsBytes(bytes);
      }

      _profile = newProfileFile;
    }
    
    _name = inputJson["name"] ?? "Unknown";

    if (inputJson.isEmpty) {
      resetAll();
    }

    _prePrompt = inputJson["pre_prompt"] ?? "";
    _userAlias = inputJson["user_alias"] ?? "";
    _responseAlias = inputJson["response_alias"] ?? "";

    _useExamples = inputJson["use_examples"] ?? true;
    if (inputJson["examples"] != null) {
      final length = inputJson["examples"].length ?? 0;
      _examples = List<Map<String,dynamic>>.generate(length, (i) => inputJson["examples"][i]);
    }

    Logger.log("Character created with name: ${inputJson["name"]}");
    notifyListeners();
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> jsonCharacter = {};

    jsonCharacter["profile"] = _profile.path;
    jsonCharacter["name"] = _name;
    
    jsonCharacter["pre_prompt"] = _prePrompt;
    jsonCharacter["user_alias"] = _userAlias;
    jsonCharacter["response_alias"] = _responseAlias;
    jsonCharacter["use_examples"] = _useExamples;
    jsonCharacter["examples"] = _examples;

    return jsonCharacter;
  }

  void setName(String newName) {
    _name = newName;
    notifyListeners();
  }

  void setUserAlias(String newAlias) {
    _userAlias = newAlias;
    notifyListeners();
  }

  void setResponseAlias(String newAlias) {
    _responseAlias = newAlias;
    notifyListeners();
  }

  void setPrePrompt(String newPrePrompt) {
    _prePrompt = newPrePrompt;
    notifyListeners();
  }

  void setUseExamples(bool useExamples) {
    _useExamples = useExamples;
    notifyListeners();
  }

  void newExample() {
    _examples.addAll(
      [
        {
          "role": "user",
          "content": "",
        }, 
        {
          "role": "assistant",
          "content": "",
        }
      ]
    );
    notifyListeners();
  }

  void updateExample(int index, String value) {
    _examples[index]["content"] = value;
    notifyListeners();
  }

  void removeExample(int index) {
    _examples.removeRange(index - 2, index);
    notifyListeners();
  }

  void removeLastExample() {
    _examples.removeRange(_examples.length - 2, _examples.length);
    notifyListeners();
  }

  File get profile => _profile;

  String get name => _name;

  String get userAlias => _userAlias;

  String get responseAlias => _responseAlias;

  String get prePrompt => _prePrompt;

  bool get useExamples => _useExamples;

  List<Map<String,dynamic>> get examples => _examples;

  void resetAll() {
    // Reset all the internal state to the defaults
    rootBundle.loadString('assets/default_character.json').then((jsonString) {
      Map<String, dynamic> jsonCharacter = json.decode(jsonString);

      fromMap(jsonCharacter);

      notifyListeners();
    });
  }

  Future<String> exportJSON(BuildContext context) async {
    try {
      // Convert the map to a JSON string
      String jsonString = json.encode(toMap());
    
      File? file = await FileManager.save(context, "$_name.json");

      if (file == null) return "Error saving file";

      await file.writeAsString(jsonString);

      return "Character Successfully Saved to ${file.path}";
    } catch (e) {
      Logger.log("Error: $e");
      return "Error: $e";
    }
  }

  Future<String> importJSON(BuildContext context) async {
    try {
      File? file = await FileManager.load(context, "Load Character JSON", [".json"]);

      if (file == null) return "Error loading file";

      String jsonString = await file.readAsString();
      if (jsonString.isEmpty) return "Failed to load character";
      
      Map<String, dynamic> jsonCharacter = json.decode(jsonString);

      if (jsonCharacter.isEmpty) {
        resetAll();
        return "Failed to decode character";
      }

      fromMap(jsonCharacter);

      notifyListeners();
      return "Character Successfully Loaded";
    } catch (e) {
      resetAll();
      Logger.log("Error: $e");
      return "Error: $e";
    }
  }

  Future<String> exportImage(BuildContext context) async {
    try {
      final image = decodeImage(_profile.readAsBytesSync());

      if (image == null) return "Error decoding image";

      image.textData = {
        "name": _name,
        "pre_prompt": _prePrompt,
        "user_alias": _userAlias,
        "response_alias": _responseAlias,
        "examples": json.encode(_examples),
      };

      File? file = await FileManager.save(context, "$_name.png");
      
      if (file == null) return "Error saving file";

      await file.writeAsBytes(encodePng(image));

      return "Character Successfully Saved";
    } catch (e) {
      Logger.log("Error: $e");
      return "Error: $e";
    }
  }

  Future<String> importImage(BuildContext context) async {
    try{
      File? file = await FileManager.loadImage(context, "Load Character Image");

      if (file == null) return "Error loading file";

      final image = decodePng(file.readAsBytesSync());

      if (image != null && image.textData != null) {
        _name = image.textData!["name"] ?? "";
        _prePrompt = image.textData!["pre_prompt"] ?? "";
        _userAlias = image.textData!["user_alias"] ?? "";
        _responseAlias = image.textData!["response_alias"] ?? "";
        _examples = List<Map<String,dynamic>>.from(json.decode(image.textData!["examples"] ?? "[]"));        
      }

      Directory docDir = await getApplicationDocumentsDirectory();
      String filePath = '${docDir.path}/$_name.png';

      File newProfileFile = File(filePath);
      if (!await newProfileFile.exists()) {
        ByteData data = await file.readAsBytes().then((bytes) => ByteData.view(bytes.buffer));
        List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await newProfileFile.writeAsBytes(bytes);
      }

      _profile = newProfileFile;

      notifyListeners();
      return "Character Successfully Loaded";
    } catch (e) {
      resetAll();
      Logger.log("Error: $e");
      return "Error: $e";
    }
  }
}