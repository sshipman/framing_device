import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frame_sdk/display.dart';
import 'package:frame_sdk/frame_sdk.dart';
import 'package:framing_device/models/repl_message.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/frame_file_entry.dart';

class FrameNotifier extends ChangeNotifier {
  Frame frame = Frame();
  int batteryLevel = 100;
  Timer? _batteryPollTimer;
  String _browsingPath ="";
  List<FrameFileEntry> _currentFiles = [];
  List<ReplMessage> replMessages = [];

  String get browsingPath => _browsingPath;
  void set browsingPath(String path) {
    _browsingPath = path;
    listDir(dir: path).then((List<FrameFileEntry> files){
      _currentFiles = files;
      notifyListeners();
    });
  }

  List<FrameFileEntry> get currentFiles => _currentFiles;

  void _startBatteryPoll(){
    _batteryPollTimer = Timer.periodic(const Duration(seconds: 30),
      _updateBatteryLevel
    );
  }

  void _updateBatteryLevel(Timer t) async{
    try {
      var bat = await frame.getBatteryLevel();
      batteryLevel = bat;
      notifyListeners();
    } catch(e){
      print("error getting battery, canceling polling: $e");
      t.cancel();
    }
  }

  Future<void> _ensureUtilsFiles() async {
    try{
      await frame.display.showText("uploading utility scripts", align: Alignment2D.middleCenter);
      // there doesn't seem to be a way to check the directory directly, so eat the error
      try {
        await frame.runLua("frame.file.mkdir('/wtf_flax')", timeout: Duration(seconds: 2));
      } catch(e) {
        print("could not create wtf_flax directory, probably existed already");
      }
      await frame.bluetooth.uploadScript(
          "/wtf_flax/json.lua", "assets/lua_scripts/json.lua");
    }catch(e){
      print("could not upload scripts! $e");
    }
  }

  void connect() async{
    var didConnect = await frame.connect();
    if (didConnect) {
      await frame.bluetooth.sendBreakSignal();
      //_startBatteryPoll();
      await _ensureUtilsFiles();
      await frame.display.showText("Ready", align: Alignment2D.middleCenter);
    }
    notifyListeners();
  }

  void disconnect() async{
    await frame.sleep(true);
    await frame.disconnect();
    _batteryPollTimer?.cancel();
    replMessages.clear();
    notifyListeners();
  }

  Future<List<FrameFileEntry>> listDir({String dir = '/'}) async{
    frame.display.showText("Listing files in $dir", align: Alignment2D.middleCenter);
    try {
      await frame.runLua('json=require("/wtf_flax/json")');
      String response = await frame.runLua(
          "print(json.encode(frame.file.listdir('$dir')))", awaitPrint: true, checked: true, timeout: const Duration(seconds: 5)) ?? '__NO_RESPONSE__';
      print('listdir response: $response');
      List<dynamic> jsonList = jsonDecode(response);
      return jsonList.map((dynamic jsonEntry){
        return FrameFileEntry.fromJSON(jsonEntry as Map<String, dynamic>);
      }).toList();
    } catch(e) {
      print('error from listdir: $e');
      return [];
    }finally{
      frame.display.clear();
    }
  }

  Future<void> reloadDir() async {
    _currentFiles = await listDir(dir: browsingPath);
    notifyListeners();
  }

  Future<void> createDir(String dirPath) async {
    await frame.runLua('frame.file.mkdir("$dirPath")');
    await reloadDir();
  }

  Future<void> renameFile({required String original, required String updated}) async {
    await frame.runLua('frame.file.rename("$original", "$updated")');
    await reloadDir();
  }

  Future<String> getFirmwareVersion() async {
    frame.display.showText("Retrieving firmware version", align: Alignment2D.middleCenter);
    try {
      String response = await frame.runLua(
        "print(frame.FIRMWARE_VERSION)", awaitPrint: true, checked: true
      ) ?? "__NO_RESPONSE__";
      print("firmware version $response");
      return response;
    } catch(e) {
      print('error from getFirmwareVersion: $e');
      return '__NO_RESPONSE__';
    }
  }

  Future<void> deleteFile(String path) async {
    await frame.files.deleteFile(path);
    _currentFiles = await listDir(dir: browsingPath);
    notifyListeners();
  }

  Future<void> sendRepl(String input) async {
    String response = "";
    bool isError = false;
    try {
      response = await frame.evaluate(input);
    } catch (e) {
      response = e.toString();
      isError = true;
    } finally{
      ReplMessage message = ReplMessage(input: input, response: response, isError: isError);
      replMessages.add(message);
      notifyListeners();
    }
  }

}

final frameProvider = ChangeNotifierProvider<FrameNotifier>((ref){
  return FrameNotifier();
});