import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:framing_device/models/frame_file_entry.dart';
import 'package:framing_device/models/frame_file_type.dart';
import 'package:framing_device/providers/frame_provider.dart';
import 'package:framing_device/simple_prompt_dialog.dart';

import 'editor.dart';

class FramesPage extends ConsumerWidget{
  const FramesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    FrameNotifier frameNotifier = ref.watch(frameProvider);
    String browsingPath = frameNotifier.browsingPath;
    List<FrameFileEntry> currentFiles = frameNotifier.currentFiles;
    if (!frameNotifier.frame.isConnected) {
      return const Center(
        child: Text("Connect to frame to see files")
      );
    }
    if (currentFiles.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_){
        if (frameNotifier.browsingPath != "/") {
          frameNotifier.browsingPath = "/";
        }
      });
      return Center(child: ElevatedButton(onPressed: () async {
      }, child: const Text("Loading Files")));
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                  child: Container(
                    color: Colors.cyan,
                    child: Text(browsingPath, style: const TextStyle(
                      fontSize: 20,
                      overflow: TextOverflow.ellipsis
                    )),
                  )),
            ],
          ),
          Expanded(
            child: ListView.builder(
                itemCount: currentFiles.length,
                itemBuilder: (BuildContext context, int index) {
                  FrameFileEntry entry = currentFiles[index];
                  return ListTile(
                      title: Text(entry.name),
                      subtitle: entry.type == FrameFileType.regular ? Text(entry.size.toString()) : null,
                      leading: (entry.type == FrameFileType.directory) ? const Icon(
                          Icons.folder) : null,
                      trailing: (entry.name == "." || entry.name == "..") ? null : IconButton(onPressed: () async {
                        bool? confirmation = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext context) => AlertDialog(
                            title: Text("Delete ${entry.name}?"),
                            content: const Text("Deletion cannot be undone."),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          )
                        );
                        if (confirmation ?? false) {
                          try {
                            await frameNotifier.deleteFile('$browsingPath/${entry.name}');
                            await frameNotifier.reloadDir();
                          } catch (e) {
                            print("error deleting file: $e");
                          }

                        }
                      }, icon: const Icon(Icons.delete)),
                      onTap: () async {
                        if (entry.type == FrameFileType.directory) {
                          if (entry.name == ".") {
                            // don't bother reloading current directory
                            return;
                          }
                          if (entry.name == "..") {
                            //go up
                            browsingPath = browsingPath.substring(0, browsingPath.lastIndexOf("/"));
                            if (browsingPath.isEmpty){
                              browsingPath = "/";
                            }
                          } else {
                            //build new browsingPath then get files
                            if (!browsingPath.endsWith("/")){
                              browsingPath = "$browsingPath/";
                            }
                            browsingPath = browsingPath + entry.name;
                          }
                          frameNotifier.browsingPath = browsingPath;
                        } else {
                          Uint8List bytes = await frameNotifier.frame.files.readFile("$browsingPath/${entry.name}");
                          String data = String.fromCharCodes(bytes);
                          if (context.mounted){
                            Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) => Editor(text:data, fileName:entry.name)));
                          }
                        }
                      },
                    onLongPress: () async {
                        String? fileName =await showPromptDialog(context, title: "Rename ${entry.name}",
                        message: "Enter new file name",
                        initialValue: entry.name);
                        if (fileName == null){
                          return;
                        }
                        //Don't break it, please.
                        //Note that this does not prevent renaming to collide with another file
                        //or silly characters.
                        if ((fileName == ".") || (fileName == "..")){
                          return;
                        }
                        String browsingPath = frameNotifier.browsingPath;
                        String original = "$browsingPath/${entry.name}";
                        String updated = "$browsingPath/$fileName";
                        frameNotifier.renameFile(original:original, updated: updated);
                    },
                  );
                }
            ),
          ),
        ],
      );
    }
  }
}