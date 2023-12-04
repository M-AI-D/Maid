import 'dart:io';

import 'package:flutter/material.dart';
import 'package:maid/providers/model.dart';
import 'package:maid/widgets/settings_widgets/maid_slider.dart';
import 'package:maid/widgets/settings_widgets/maid_text_field.dart';
import 'package:maid/widgets/settings_widgets/model_dropdown.dart';
import 'package:provider/provider.dart';

class OllamaParameters extends StatelessWidget {
  const OllamaParameters({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<Model>(
      builder: (context, model, child) {
        return Column(
          children: [
            MaidTextField(
              headingText: 'API Token', 
              labelText: 'API Token',
              initialValue: model.parameters["api_key"] ?? "",
              onSubmitted: (value) {
                model.setParameter("api_key", value);
              } ,
            ),
            Divider(
              height: 20,
              indent: 10,
              endIndent: 10,
              color: Theme.of(context).colorScheme.primary,
            ),
            MaidTextField(
              headingText: 'Remote URL', 
              labelText: 'Remote URL',
              initialValue: model.parameters["remote_url"] ?? "http://0.0.0.0:11434",
              onSubmitted: (value) {
                model.setParameter("remote_url", value);
              } ,
            ),
            const SizedBox(height: 8.0),
            const ModelDropdown(),
            const SizedBox(height: 20.0),
            Divider(
              height: 20,
              indent: 10,
              endIndent: 10,
              color: Theme.of(context).colorScheme.primary,
            ),
            SwitchListTile(
              title: const Text('penalize_nl'),
              value: model.parameters["penalize_nl"] ?? true,
              onChanged: (value) {
                model.setParameter("penalize_nl", value);
              },
            ),
            SwitchListTile(
              title: const Text('random_seed'),
              value: model.parameters["random_seed"] ?? true,
              onChanged: (value) {
                model.setParameter("random_seed", value);
              },
            ),
            Divider(
              height: 20,
              indent: 10,
              endIndent: 10,
              color: Theme.of(context).colorScheme.primary,
            ),
            if (!(model.parameters["random_seed"] ?? true))
              ListTile(
                title: Row(
                  children: [
                    const Expanded(
                      child: Text('seed'),
                    ),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'seed',
                        ),
                        onSubmitted: (value) {
                          model.setParameter("seed", int.parse(value));
                        },
                      ),
                    ),
                  ],
                ),
              ),
            MaidSlider(
              labelText: 'n_threads',
              inputValue: model.parameters["n_threads"] ?? Platform.numberOfProcessors,
              sliderMin: 1.0,
              sliderMax: model.apiType == ApiType.local
                ? Platform.numberOfProcessors.toDouble()
                : 128.0,
              sliderDivisions: 127,
              onValueChanged: (value) {
                model.setParameter("n_threads", value.round());
                if (model.parameters["n_threads"] > Platform.numberOfProcessors) {
                  model.setParameter("n_threads", Platform.numberOfProcessors);
                }
              }
            ),
            MaidSlider(
              labelText: 'n_ctx',
              inputValue: model.parameters["n_ctx"] ?? 512,
              sliderMin: 1.0,
              sliderMax: 4096.0,
              sliderDivisions: 4095,
              onValueChanged: (value) {
                model.setParameter("n_ctx", value.round());
              }
            ),
            MaidSlider(
              labelText: 'n_batch',
              inputValue: model.parameters["n_batch"] ?? 8,
              sliderMin: 1.0,
              sliderMax: 4096.0,
              sliderDivisions: 4095,
              onValueChanged: (value) {
                model.setParameter("n_batch", value.round());
              }
            ),
            MaidSlider(
              labelText: 'n_predict',
              inputValue: model.parameters["n_predict"] ?? 512,
              sliderMin: 1.0,
              sliderMax: 1024.0,
              sliderDivisions: 1023,
              onValueChanged: (value) {
                model.setParameter("n_predict", value.round());
              }
            ),
            MaidSlider(
              labelText: 'n_keep',
              inputValue: model.parameters["n_keep"] ?? 48,
              sliderMin: 1.0,
              sliderMax: 1024.0,
              sliderDivisions: 1023,
              onValueChanged: (value) {
                model.setParameter("n_keep", value.round());
              }
            ),
            MaidSlider(
              labelText: 'top_k',
              inputValue: model.parameters["top_k"] ?? 40,
              sliderMin: 1.0,
              sliderMax: 128.0,
              sliderDivisions: 127,
              onValueChanged: (value) {
                model.setParameter("top_k", value.round());
              }
            ),
            MaidSlider(
              labelText: 'top_p',
              inputValue: model.parameters["top_p"] ?? 0.95,
              sliderMin: 0.0,
              sliderMax: 1.0,
              sliderDivisions: 100,
              onValueChanged: (value) {
                model.setParameter("top_p", value);
              }
            ),
            MaidSlider(
              labelText: 'tfs_z',
              inputValue: model.parameters["tfs_z"] ?? 1.0,
              sliderMin: 0.0,
              sliderMax: 1.0,
              sliderDivisions: 100,
              onValueChanged: (value) {
                model.setParameter("tfs_z", value);
              }
            ),
            MaidSlider(
              labelText: 'typical_p',
              inputValue: model.parameters["typical_p"] ?? 1.0,
              sliderMin: 0.0,
              sliderMax: 1.0,
              sliderDivisions: 100,
              onValueChanged: (value) {
                model.setParameter("typical_p", value);
              }
            ),
            MaidSlider(
              labelText: 'temperature',
              inputValue: model.parameters["temperature"] ?? 0.8,
              sliderMin: 0.0,
              sliderMax: 1.0,
              sliderDivisions: 100,
              onValueChanged: (value) {
                model.setParameter("temperature", value);
              }
            ),
            MaidSlider(
              labelText: 'penalty_last_n',
              inputValue: model.parameters["penalty_last_n"] ?? 64,
              sliderMin: 0.0,
              sliderMax: 128.0,
              sliderDivisions: 127,
              onValueChanged: (value) {
                model.setParameter("penalty_last_n", value.round());
              }
            ),
            MaidSlider(
              labelText: 'penalty_repeat',
              inputValue: model.parameters["penalty_repeat"] ?? 1.1,
              sliderMin: 0.0,
              sliderMax: 2.0,
              sliderDivisions: 200,
              onValueChanged: (value) {
                model.setParameter("penalty_repeat", value);
              }
            ),
            MaidSlider(
              labelText: 'penalty_freq',
              inputValue: model.parameters["penalty_freq"] ?? 0.0,
              sliderMin: 0.0,
              sliderMax: 1.0,
              sliderDivisions: 100,
              onValueChanged: (value) {
                model.setParameter("penalty_freq", value);
              }
            ),
            MaidSlider(
              labelText: 'penalty_present',
              inputValue: model.parameters["penalty_present"] ?? 0.0,
              sliderMin: 0.0,
              sliderMax: 1.0,
              sliderDivisions: 100,
              onValueChanged: (value) {
                model.setParameter("penalty_present", value);
              }
            ),
            MaidSlider(
              labelText: 'mirostat',
              inputValue: model.parameters["mirostat"] ?? 0.0,
              sliderMin: 0.0,
              sliderMax: 128.0,
              sliderDivisions: 127,
              onValueChanged: (value) {
                model.setParameter("mirostat", value.round());
              }
            ),
            MaidSlider(
              labelText: 'mirostat_tau',
              inputValue: model.parameters["mirostat_tau"] ?? 5.0,
              sliderMin: 0.0,
              sliderMax: 10.0,
              sliderDivisions: 100,
              onValueChanged: (value) {
                model.setParameter("mirostat_tau", value);
              }
            ),
            MaidSlider(
              labelText: 'mirostat_eta',
              inputValue: model.parameters["mirostat_eta"] ?? 0.1,
              sliderMin: 0.0,
              sliderMax: 1.0,
              sliderDivisions: 100,
              onValueChanged: (value) {
                model.setParameter("mirostat_eta", value);
              }
            ),
          ]
        );
    });
  }
}