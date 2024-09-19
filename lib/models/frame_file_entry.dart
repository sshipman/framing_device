import 'frame_file_type.dart';

class FrameFileEntry {
  final String name;
  final int size;
  final FrameFileType type;

  FrameFileEntry(this.name, this.size, this.type);

  factory FrameFileEntry.fromJSON(Map<String, dynamic> json) {
    String name = json['name'];
    int size = json['size'];
    int fileType = json['type'];

    return FrameFileEntry(name, size, FrameFileType.fromInt(fileType));
  }
}