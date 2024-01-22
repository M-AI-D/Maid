import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import 'package:maid/models/generation_options.dart';
import 'package:maid/static/logger.dart';

class LocalGeneration {
  static LlamaProcessor? llamaProcessor;

  static void prompt(
    String input,
    GenerationOptions options,
    void Function(String?) callback
  ) async {
    if (llamaProcessor == null) {
      ModelParams modelParams = ModelParams();
      ContextParams contextParams = ContextParams();
      contextParams.batch = 512;
      contextParams.context = 512;
      
      llamaProcessor = LlamaProcessor(
        options.path!, 
        modelParams, 
        contextParams
      );
    }

    llamaProcessor!.stream.listen((data) {
      callback.call(data);
    });

    llamaProcessor?.prompt(input);
  }

  static void stop() {
    llamaProcessor?.stop();
  }

  static void dispose() {
    llamaProcessor?.unloadModel();
    llamaProcessor = null;
  }
}
