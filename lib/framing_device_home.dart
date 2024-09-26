import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:framing_device/repl_page.dart';
import 'package:framing_device/simple_prompt_dialog.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frame_sdk/frame_sdk.dart';
import 'package:framing_device/providers/frame_provider.dart';
import 'package:path/path.dart' as p;

import 'editor.dart';
import 'frames_page.dart';

class NavDestination {
  const NavDestination(this.label, this.icon, this.selectedIcon,
      {this.mustBeConnected = false});

  final String label;
  final Widget icon;
  final Widget selectedIcon;
  final bool mustBeConnected;
}

List<NavDestination> destinations = <NavDestination>[
  const NavDestination(
      'Frames', Icon(Bootstrap.eyeglasses), Icon(Bootstrap.eyeglasses),
      mustBeConnected: true),
  const NavDestination(
      'Terminal', Icon(Icons.terminal_outlined), Icon(Icons.terminal),
      mustBeConnected: true),
];

class FramingDeviceHome extends ConsumerStatefulWidget {
  const FramingDeviceHome({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _FramingDeviceHomeState();
  }
}

class _FramingDeviceHomeState extends ConsumerState<FramingDeviceHome> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  int screenIndex = 0;
  late bool showNavigationDrawer;

  void handleScreenChanged(int selectedScreen) {
    setState(() {
      screenIndex = selectedScreen;
    });
  }

  void openDrawer() {
    scaffoldKey.currentState!.openEndDrawer();
  }

  AppBar _buildAppBar() {
    FrameNotifier frameNotifier = ref.watch(frameProvider);
    Frame frame = frameNotifier.frame;
    bool connected = frame.isConnected;
    Widget reloadDir = (connected && screenIndex == 0)
        ? IconButton(
            onPressed: () {
              frameNotifier.reloadDir();
            },
            icon: const Icon(Icons.refresh))
        : const Spacer();
    Widget importFile = (connected && screenIndex == 0)
        ? IconButton(
            onPressed: () async {
              // open a file chooser for phone file system, looking for lua files
              // when selected, get all text, open Editor.
              FilePickerResult? result = await FilePicker.platform.pickFiles();
              if (result != null) {
                String filePath = result.files.single.path!;
                File file = File(filePath);
                var data = await file.readAsString();
                if (mounted){
                  Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) => Editor(text:data, fileName:p.basename(filePath))));
                }

              }
            },
            icon: const Icon(Icons.file_open))
        : const Spacer();
    //Widget batteryStatus = connected ? Text("${frameNotifier.batteryLevel}%") : Spacer();
    IconButton connectionButton = connected
        ? IconButton(
            onPressed: () {
              frameNotifier.disconnect();
            },
            icon: const Icon(Icons.link))
        : IconButton(
            onPressed: () {
              frameNotifier.connect();
            },
            icon: const Icon(Icons.link_off));
    return AppBar(
      title: Text(destinations[screenIndex].label),
      actions: [importFile, reloadDir, connectionButton],
    );
  }

  Widget buildBottomBarScaffold() {
    FrameNotifier frameNotifier = ref.watch(frameProvider);
    Frame frame = frameNotifier.frame;
    bool connected = frame.isConnected;
    return Scaffold(
      appBar: _buildAppBar(),
      body: <Widget>[const FramesPage(), const ReplPage()][screenIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: screenIndex,
        onDestinationSelected: (int index) {
          setState(() {
            screenIndex = index;
          });
        },
        destinations: destinations.map(
          (NavDestination destination) {
            return NavigationDestination(
              enabled: !destination.mustBeConnected || connected,
              label: destination.label,
              icon: destination.icon,
              selectedIcon: destination.selectedIcon,
              tooltip: destination.label,
            );
          },
        ).toList(),
      ),
      floatingActionButton: (connected && screenIndex == 0)
          ? GestureDetector(
              onLongPress: () async {
                String? dirName = await showPromptDialog(context,
                    title: "Create Directory",
                    message: "Enter new directory name",
                    initialValue: "");
                if ((dirName == null) || dirName.isEmpty) {
                  return;
                }
                //Don't break it, please.
                //Note that this does not prevent renaming to collide with another file
                //or silly characters.
                if ((dirName == ".") || (dirName == "..")) {
                  return;
                }
                String browsingPath = frameNotifier.browsingPath;
                if (browsingPath == "/") {
                  //we'll add one anyway.
                  browsingPath = "";
                }
                String dirPath = "$browsingPath/$dirName";
                await frameNotifier.createDir(dirPath);
              },
              child: FloatingActionButton(
                  onPressed: () {
                    if (context.mounted) {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (BuildContext context) => Editor(text: "")));
                    }
                  },
                  child: const Icon(Icons.add)),
            )
          : null,
    );
  }

  Widget buildDrawerScaffold(BuildContext context) {
    FrameNotifier frameNotifier = ref.watch(frameProvider);
    Frame frame = frameNotifier.frame;
    bool connected = frame.isConnected;
    return Scaffold(
      key: scaffoldKey,
      appBar: _buildAppBar(),
      body: SafeArea(
        bottom: false,
        top: false,
        child: Row(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: NavigationRail(
                minWidth: 50,
                destinations: destinations.map(
                  (NavDestination destination) {
                    return NavigationRailDestination(
                      disabled: destination.mustBeConnected && !connected,
                      label: Text(destination.label),
                      icon: destination.icon,
                      selectedIcon: destination.selectedIcon,
                    );
                  },
                ).toList(),
                selectedIndex: screenIndex,
                useIndicator: true,
                onDestinationSelected: (int index) {
                  setState(() {
                    screenIndex = index;
                  });
                },
              ),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Text('Page Index = $screenIndex'),
                  ElevatedButton(
                    onPressed: openDrawer,
                    child: const Text('Open Drawer'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      endDrawer: NavigationDrawer(
        onDestinationSelected: handleScreenChanged,
        selectedIndex: screenIndex,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
            child: Text(
              'Header',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          ...destinations.map(
            (NavDestination destination) {
              return NavigationDrawerDestination(
                enabled: !destination.mustBeConnected || connected,
                label: Text(destination.label),
                icon: destination.icon,
                selectedIcon: destination.selectedIcon,
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(28, 16, 28, 10),
            child: Divider(),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    showNavigationDrawer = MediaQuery.of(context).size.width >= 450;
  }

  @override
  Widget build(BuildContext context) {
    return showNavigationDrawer
        ? buildDrawerScaffold(context)
        : buildBottomBarScaffold();
  }
}
