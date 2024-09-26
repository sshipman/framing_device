import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/a11y-dark.dart';
import 'package:flutter_highlight/themes/a11y-light.dart';
import 'package:framing_device/providers/frame_provider.dart';
import 'package:highlight/languages/lua.dart';
import 'package:file_saver/file_saver.dart';

class Editor extends ConsumerStatefulWidget {
  final String text;
  final String? fileName;

  const Editor({super.key, required this.text, this.fileName});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _EditorState();
  }
}

class _EditorState extends ConsumerState<Editor> {
  late final CodeController controller;
  late final TextEditingController fileNameController;

  @override
  void initState() {
    super.initState();
    fileNameController =
        TextEditingController(text: widget.fileName ?? "Unnamed");
    controller = CodeController(
      text: widget.text,
      language: lua,
    );
  }

  @override
  Widget build(BuildContext context) {
    FrameNotifier frameNotifier = ref.read(frameProvider);
    ThemeData theme = Theme.of(context);
    var codeThemeStyles =
        (theme.brightness == Brightness.dark) ? a11yDarkTheme : a11yLightTheme;
    return Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: fileNameController,
          ),
          actions: [
            IconButton(
              onPressed: () async {
                //separate name and extension
                String fullName = fileNameController.text;
                int lastDot = fullName.lastIndexOf(".");
                String name = fullName;
                String ext = "";
                if (lastDot > 0) {
                  name = fullName.substring(0, lastDot);
                  ext = fullName.substring(lastDot+1);
                }
                Uint8List bytes = Uint8List.fromList(controller.fullText.codeUnits);
                //open dialog to save locally
                await FileSaver.instance.saveAs(
                  name: name,
                  ext: ext,
                  mimeType: MimeType.other,
                  bytes: bytes
                );
              },
              icon: Icon(Icons.save_alt)
            ),
            IconButton(
              onPressed: () async {
                String path =
                    "${frameNotifier.browsingPath}/${fileNameController.text}";
                String fileContents = controller.fullText;
                await frameNotifier.frame.files
                    .writeFile(path, fileContents, checked: true);

                if (context.mounted) {
                  await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                            title: const Text("File Uploaded"),
                            content: Text(
                                "${fileNameController.text} successfully uploaded to Frames"),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('OK'),
                              ),
                            ],
                          ));
                }
              },
              icon: const Icon(Icons.file_upload),
            )
          ],
        ),
        body: CodeTheme(
            data: CodeThemeData(
              styles: codeThemeStyles,
            ),
            child: SingleChildScrollView(
                child: CodeField(
              controller: controller,
              gutterStyle: const GutterStyle(textStyle: TextStyle(height: 1.5)),
              maxLines: null,
            ))));
  }
}
