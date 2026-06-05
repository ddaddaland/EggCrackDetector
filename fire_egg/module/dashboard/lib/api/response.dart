import 'dart:convert';

import 'package:http/http.dart';

extension ResponseExtension on Response {
  String? bodyIfOK() {
    if (this.statusCode == 200) {
      return utf8.decode(this.bodyBytes);
    }
    return null;
  }
}
