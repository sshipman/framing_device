class ReplMessage {
  String input;
  String response;
  bool isError;

  ReplMessage({required this.input, required this.response, this.isError = false});
}