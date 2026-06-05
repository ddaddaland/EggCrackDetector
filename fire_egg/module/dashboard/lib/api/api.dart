import 'package:http/http.dart' as http;
import 'response.dart';

class ServerAPI {
  final String baseUrl;

  ServerAPI({
    required this.baseUrl,
  });

  //

  Future<http.Response> get(String path) async {
    final url = Uri.parse('$baseUrl/fe$path');
    return await http.get(url);
  }

  //

  Future<String?> ping() async {
    final response = await get('/ping');
    return response.bodyIfOK();
  }
}
