import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:framing_device/providers/frame_provider.dart';

import 'models/repl_message.dart';

class ReplPage extends ConsumerStatefulWidget {
  const ReplPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _ReplState();
  }
}

class _ReplState extends ConsumerState<ReplPage> {
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _textController.text = "";
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    FrameNotifier frameNotifier = ref.watch(frameProvider);
    List<ReplMessage> messages = frameNotifier.replMessages;

    return Column(children: [
      Expanded(
          child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (BuildContext context, int index) {
                ReplMessage message = messages[index];
                String input = message.input;
                var responseColor = message.isError
                    ? Colors.yellowAccent
                    : Theme.of(context).colorScheme.secondary;
                return GestureDetector(
                  onTap: () {
                    _textController.text = message.input;
                  },
                  child: Text.rich(TextSpan(text: "$input\n", children: [
                    TextSpan(
                        text: message.response,
                        style: TextStyle(color: responseColor))
                  ])),
                );
              })),
      Row(children: [
        Expanded(
            child: TextField(
          decoration: const InputDecoration(border: OutlineInputBorder()),
          controller: _textController,
          onSubmitted: (String value) {
            if (value.isNotEmpty) {
              frameNotifier.sendRepl(value);
              _textController.clear();
            }
          },
        )),
        IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              if (_textController.value.text.isNotEmpty) {
                frameNotifier.sendRepl(_textController.value.text);
                _textController.clear();
              }
            })
      ])
    ]);
  }
}
