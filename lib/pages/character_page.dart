import 'package:flutter/material.dart';
import 'package:maid/widgets/dialogs.dart';
import 'package:maid/utilities/memory_manager.dart';
import 'package:maid/utilities/character.dart';
import 'package:maid/widgets/settings_widgets/double_button_row.dart';
import 'package:maid/widgets/settings_widgets/maid_text_field.dart';

class CharacterPage extends StatefulWidget {
  const CharacterPage({super.key});

  @override
  State<CharacterPage> createState() => _CharacterPageState();
}

class _CharacterPageState extends State<CharacterPage> { 
  @override
  initState() {
    super.initState();
  }

  @override
  void dispose() {
    MemoryManager.save();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
          ),
        ),
        title: const Text('Character'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10.0),
                Text(
                  character.name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20.0),
                FilledButton(
                  onPressed: () {
                    switcherDialog(
                      context, 
                      MemoryManager.getCharacters, 
                      MemoryManager.setCharacter,
                      MemoryManager.removeCharacter,
                      () => setState(() {}),
                      () async {
                        MemoryManager.save();
                        character = Character();
                        character.name = "New Character";
                        setState(() {});
                      }
                    );
                  },
                  child: Text(
                    "Switch Character",
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                const SizedBox(height: 15.0),
                ListTile(
                  title: Row(
                    children: [
                      const Expanded(
                        child: Text("Character Name"),
                      ),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          cursorColor: Theme.of(context).colorScheme.secondary,
                          decoration: const InputDecoration(
                            labelText: "Name",
                          ),
                          controller: TextEditingController(text: character.name),
                          onSubmitted: (value) {
                            if (MemoryManager.getCharacters().contains(value)) {
                              MemoryManager.setCharacter(value);
                            } else if (value.isNotEmpty) {
                              MemoryManager.updateCharacter(value);
                            }
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20.0),
                Divider(
                  indent: 10,
                  endIndent: 10,
                  color: Theme.of(context).colorScheme.primary,
                ),
                DoubleButtonRow(
                  leftText: "Load Character",
                  leftOnPressed: () async {
                    await storageOperationDialog(context, character.loadCharacterFromJson);
                    setState(() {});
                  },
                  rightText: "Save Character",
                  rightOnPressed: () async {
                    await storageOperationDialog(context, character.saveCharacterToJson);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 10.0),
                FilledButton(
                  onPressed: () {
                    character.resetAll();
                    setState(() {});
                  },
                  child: Text(
                    "Reset All",
                    style: Theme.of(context).textTheme.labelLarge
                  ),
                ),
                Divider(
                  indent: 10,
                  endIndent: 10,
                  color: Theme.of(context).colorScheme.primary,
                ),
                MaidTextField(
                  headingText: 'User alias', 
                  labelText: 'Alias',
                  initialValue: character.userAlias,
                  onSubmitted: (value) {
                    setState(() {
                      character.userAlias = value;
                    });
                  },
                ),
                MaidTextField(
                  headingText: 'Response alias',
                  labelText: 'Alias',
                  initialValue: character.responseAlias,
                  onSubmitted: (value) {
                    setState(() {
                      character.responseAlias = value;
                    });
                  },
                ),
                MaidTextField(
                  headingText: 'PrePrompt',
                  labelText: 'PrePrompt',
                  initialValue: character.prePrompt,
                  onSubmitted: (value) {
                    setState(() {
                      character.prePrompt = value;
                    });
                  },
                ),
                Divider(
                  indent: 10,
                  endIndent: 10,
                  color: Theme.of(context).colorScheme.primary,
                ),
                DoubleButtonRow(
                  leftText: "Add Example",
                  leftOnPressed: () {
                    setState(() {
                      character.examples.add({"prompt": "", "response": ""});
                    });
                  },
                  rightText: "Remove Example",
                  rightOnPressed: () {
                    setState(() {
                      character.examples.removeLast();
                    });
                  },
                ),
                const SizedBox(height: 10.0),
                ...List.generate(
                  character.examples.length,
                  (index) => Column(
                    children: [
                      MaidTextField(
                        headingText: 'Example prompt',
                        labelText: 'Prompt',
                        initialValue: character.examples[index]["prompt"],
                        onSubmitted: (value) {
                          setState(() {
                            character.examples[index]["prompt"] = value;
                          });
                        },
                      ),
                      MaidTextField(
                        headingText: 'Example response',
                        labelText: 'Response',
                        initialValue: character.examples[index]["response"],
                        onSubmitted: (value) {
                          setState(() {
                            character.examples[index]["response"] = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (character.busy)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.4),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      )
    );
  }
}
