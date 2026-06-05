import 'dart:convert';

import 'package:http/http.dart';

extension ResponseExtension on Response {
  Map<String, dynamic> get bodyJson {
    final str = utf8.decode(bodyBytes);
    return jsonDecode(str) as Map<String, dynamic>;
  }

  Map<String, dynamic>? bodyJsonIfOk() {
    if (statusCode < 200 || statusCode >= 300) {
      return null;
    }
    return bodyJson;
  }
}
