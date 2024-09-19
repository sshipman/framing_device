import 'package:flutter/material.dart';

class SimplePromptDialog extends StatefulWidget {
  final String title;
  final String message;
  final String initialValue;
  final String label;

  const SimplePromptDialog(
      {super.key, this.title = "",
      this.message = "",
      this.initialValue = "",
      this.label = ""});

  @override
  State<StatefulWidget> createState() {
    return _SimplePromptDialogState(
        title: title,
        message: message,
        initialValue: initialValue,
        label: label);
  }
}

class _SimplePromptDialogState extends State<SimplePromptDialog> {
  String title;
  String message;
  String initialValue;
  String label;
  late TextEditingController controller;

  _SimplePromptDialogState(
      {this.title = "",
      this.message = "",
      this.initialValue = "",
      this.label = ""});

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: initialValue);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 5),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: label,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text("OK"),
            onPressed: () {
              Navigator.of(context).pop(controller.text);
            },
          )
        ]);
  }
}

Future<String?> showPromptDialog(BuildContext context,
    {String title = "",
    String message = "",
    String initialValue = "",
    String label = ""}) {
  return showDialog<String?>(
      context: context,
      builder: (BuildContext context) {
        return SimplePromptDialog(
            title: title,
            message: message,
            initialValue: initialValue,
            label: label);
      });
}
