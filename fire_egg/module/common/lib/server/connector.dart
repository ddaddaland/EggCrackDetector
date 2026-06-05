import 'dart:convert';

import 'package:fire_egg_common/domain/domain.dart';
import 'package:fire_egg_common/logging/logger.dart';
import 'package:fire_egg_common/tenant/tenant.dart';
import 'package:fire_egg_common/util/response.dart';
import 'package:http/http.dart' as http;

class ServerConnector {
  final logger = Logger('server-connector', 210);
  final String address;
  final String? token;
  final Map<String, String> extraHeaders;

  ServerConnector({
    required this.address,
    required this.token,
    this.extraHeaders = const {},
  });

  Uri url(String path) {
    return Uri.parse('$address/fe$path');
  }

  late final headers = <String, String>{
    'X-FE': 'dev',
    if (token != null) 'Authorization': 'Bearer $token',
    ...extraHeaders,
  };

  Future<http.Response> get(String path) async {
    final response = await http.get(
      url(path),
      headers: headers,
    );
    logger.info('GET $path -> ${response.statusCode}');
    return response;
  }

  Future<http.Response> post(String path, {required Object body}) async {
    final response = await http.post(
      url(path),
      headers: headers,
      body: body,
      encoding: utf8,
    );
    logger.info('POST $path -> ${response.statusCode}');
    return response;
  }

  Future<int> postForm(String path, void Function(http.MultipartRequest) builder) async {
    // TODO : response handling
    final request = http.MultipartRequest('POST', url('/episode'));
    request.headers.addAll(headers);
    builder(request);
    final response = await request.send();
    logger.info('POST $path (form) -> ${response.statusCode}');
    return response.statusCode;
  }

  // named requests

  Future<String?> getToken({required String email, required String password}) async {
    final response = await post(
      '/token',
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final body = await response.bodyJsonIfOk();
    if (body == null) {
      return null;
    }

    final token = body['token'] as String?;
    return token;
  }

  Future<(Tenant, List<Domain>?)?> getTenantAndDomains() async {
    final domainsResponse = await get('/domains');
    final domainsBody = domainsResponse.bodyJsonIfOk();
    if (domainsBody == null) {
      return null;
    }

    final tenant = Tenant.fromJson(domainsBody['tenant']);
    final domains = (domainsBody['domains'] as List?)?.map((e) => Domain.fromJson(e)).toList();
    return (tenant, domains);
  }
}
