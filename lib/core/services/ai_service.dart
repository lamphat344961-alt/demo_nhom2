abstract class AIService {
  Future<String> sendMessage(String message, List<Map<String, String>> history);
  String get name;
}
