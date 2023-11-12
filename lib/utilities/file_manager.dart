import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:flutter/material.dart';
import 'package:maid/utilities/logger.dart';
import 'package:permission_handler/permission_handler.dart';

class FileManager {
  static Future<File?> load(BuildContext context, String dialogTitle, List<String> allowedExtensions) async {
    if ((Platform.isAndroid || Platform.isIOS)) {
      if (!(await Permission.storage.request().isGranted) || 
          !(await Permission.manageExternalStorage.request().isGranted)
      ) {
        Logger.log("Storage - Permission denied");
        return null;
      } else {
        Logger.log("Storage - Permission granted");
      }
    }

    String? result;
    
    Directory initialDirectory;
    if (Platform.isAndroid) {
      initialDirectory = Directory("storage/emulated/0");

      if (!context.mounted) return null;
  
      result = await FilesystemPicker.open(
        allowedExtensions: allowedExtensions,
        context: context,
        rootDirectory: initialDirectory,
        fileTileSelectMode: FileTileSelectMode.wholeTile,
        fsType: FilesystemType.file
      );
    } else {
      FilePickerResult? pick = await FilePicker.platform.pickFiles(
        dialogTitle: dialogTitle,
        type: FileType.any,
        allowMultiple: false,
      );

      if (pick != null) {
        result = pick.files.single.path;
      }
    }

    if (result == null) {
      return null;
    }

    return File(result);
  }

  static Future<File?> saveJSON(BuildContext context, String fileName) async {
    if ((Platform.isAndroid || Platform.isIOS)) {
      if (!(await Permission.storage.request().isGranted) || 
          !(await Permission.manageExternalStorage.request().isGranted)
      ) {
        return null;
      }
    }

    String? result;
    
    Directory initialDirectory;
    if (Platform.isAndroid) {
      initialDirectory = Directory("storage/emulated/0");

      if (!context.mounted) return null;
  
      result = await FilesystemPicker.open(
        title: 'Save to folder',
        context: context,
        rootDirectory: initialDirectory,
        fsType: FilesystemType.folder,
        pickText: 'Save file to this folder',
      );

      if (result != null) {
        result = "$result/$fileName.json";
      }
    } else {
      result = await FilePicker.platform.saveFile(
        dialogTitle: "Save Model File",
        type: FileType.any,
      );

      result.toString();
    }

    if (result == null) {
      return null;
    }

    return File(result);
  }
}