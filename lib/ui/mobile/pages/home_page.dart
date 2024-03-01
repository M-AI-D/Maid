import 'dart:math';

import 'package:flutter/material.dart';
import 'package:maid/providers/user.dart';
import 'package:maid/static/generation_manager.dart';
import 'package:maid/ui/mobile/pages/about_page.dart';
import 'package:maid/ui/mobile/pages/character_page.dart';
import 'package:maid/ui/mobile/pages/platform_page.dart';
import 'package:maid/ui/mobile/pages/sessions_page.dart';
import 'package:maid/ui/mobile/pages/settings_page.dart';
import 'package:maid/providers/character.dart';
import 'package:maid/ui/mobile/pages/user_page.dart';
import 'package:system_info2/system_info2.dart';
import 'package:maid/providers/session.dart';
import 'package:maid/ui/mobile/widgets/chat_widgets/chat_message.dart';
import 'package:maid/ui/mobile/widgets/chat_widgets/chat_field.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  final String title;

  const HomePage({super.key, required this.title});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final ScrollController _consoleScrollController = ScrollController();
  List<ChatMessage> chatWidgets = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          elevation: 0.0,
        ),
        drawer: _buildDrawer(),
        body: _buildBody());
  }

  Drawer _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.account_circle,
                color: Theme.of(context).colorScheme.onPrimary),
            title: Text('User', style: Theme.of(context).textTheme.labelLarge),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const UserPage()));
            },
          ),
          ListTile(
            leading: Icon(Icons.person,
                color: Theme.of(context).colorScheme.onPrimary),
            title: Text('Character',
                style: Theme.of(context).textTheme.labelLarge),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CharacterPage()));
            },
          ),
          ListTile(
            leading: Icon(Icons.account_tree_rounded,
                color: Theme.of(context).colorScheme.onPrimary),
            title: Text(
              'Model',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PlatformPage()));
            },
          ),
          ListTile(
            leading: Icon(Icons.chat_rounded,
                color: Theme.of(context).colorScheme.onPrimary),
            title: Text(
              'Sessions',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SessionsPage()));
            },
          ),
          ListTile(
            leading: Icon(Icons.settings,
                color: Theme.of(context).colorScheme.onPrimary),
            title:
                Text('Settings', style: Theme.of(context).textTheme.labelLarge),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SettingsPage()));
            },
          ),
          ListTile(
            leading: Icon(Icons.info,
                color: Theme.of(context).colorScheme.onPrimary),
            title: Text('About', style: Theme.of(context).textTheme.labelLarge),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const AboutPage()));
            },
          ),
        ]
      )
    );
  }

  Widget _buildBody() {
    return Consumer3<Session, User, Character>(
      builder: (context, session, user, character, child) {
        Map<Key, bool> history = session.history();
        if (history.isEmpty && character.useGreeting) {
          final newKey = UniqueKey();
          final index = Random().nextInt(character.greetings.length);
          session.add(newKey,
              message: GenerationManager.formatPlaceholders(
                  character.greetings[index], user.name, character.name),
              userGenerated: false,
              notify: false);
          history = {newKey: false};
        }

        chatWidgets.clear();
        for (var key in history.keys) {
          chatWidgets.add(ChatMessage(
            key: key,
            userGenerated: history[key] ?? false,
          ));
        }

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          _consoleScrollController.animateTo(
            _consoleScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 50),
            curve: Curves.easeOut,
          );
        });

        return Builder(
          builder: (BuildContext context) => GestureDetector(
            onHorizontalDragEnd: (details) {
              // Check if the drag is towards right with a certain velocity
              if (details.primaryVelocity! > 100) {
                // Open the drawer
                Scaffold.of(context).openDrawer();
              }
            },
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.background,
                  ),
                ),
                Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _consoleScrollController,
                        itemCount: chatWidgets.length,
                        itemBuilder: (BuildContext context, int index) {
                          return chatWidgets[index];
                        },
                      ),
                    ),
                    const ChatField(),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
