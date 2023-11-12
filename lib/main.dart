import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maid/utilities/memory_manager.dart';
import 'package:maid/utilities/theme.dart';
import 'package:maid/pages/home_page.dart';

final maidAppKey = GlobalKey<MaidAppState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MemoryManager.init();
  runApp(MaidApp(key: maidAppKey));
  // Override status bar colors
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light),
  );
}

class MaidApp extends StatefulWidget {
  const MaidApp({super.key});

  @override
  MaidAppState createState() => MaidAppState();
}

class MaidAppState extends State<MaidApp> {
  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  _loadTheme() async {
    await MaidTheme.loadThemePreference();
    setState(() {});
  }

  void refreshApp() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Maid',
      theme: MaidTheme.theme,
      home: const MaidHomePage(title: 'Maid'),
    );
  }
}
