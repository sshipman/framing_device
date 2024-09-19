enum FrameFileType {
  invalid(value: 0),
  regular(value: 1),
  directory(value: 2);

  final int value;

  const FrameFileType({required this.value});

  factory FrameFileType.fromInt(int val){
    switch(val) {
      case 1 :
        return FrameFileType.regular;
      case 2 :
        return FrameFileType.directory;
      default:
        return FrameFileType.invalid;
    }
  }
}
