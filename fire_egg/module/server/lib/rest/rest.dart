import 'dart:convert' show jsonDecode, jsonEncode;
import 'dart:io';
import 'dart:typed_data';

import 'package:fire_egg_common/episode/episode.dart';
import 'package:fire_egg_common/logging/logger.dart';
import 'package:fire_egg_server/server/server.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_multipart/shelf_multipart.dart';
import 'package:shelf_router/shelf_router.dart';

part 'rest.g.dart';

class FireEggServerRest {
  final Logger logger = Logger('rest', 210);

  final FireEggServer server;

  final int port;
  late final Router _router = _$FireEggServerRestRouter(this);
  HttpServer? _httpServer;

  FireEggServerRest({
    required this.server,
    required this.port,
  });

  Future<void> start() async {
    logger.info('starting rest server on port $port ...');

    if (_httpServer != null) {
      logger.warning('failed : server is already running on port ${_httpServer!.port}');
      return;
    }

    final handler = Pipeline()
        .addMiddleware(createCorsMiddleware())
        .addMiddleware(logRequests(logger: logger.logFromShelf)) // logger
        .addMiddleware(authMiddleware())
        .addHandler(_router.call);

    final server = _httpServer = await io.serve(handler, InternetAddress.loopbackIPv4, port);
    logger.info('server started on port ${server.port}');
  }

  Future<void> stop() async {
    logger.info('stopping rest server on port $port ...');
    if (_httpServer == null) {
      logger.warning('failed : server is not running');
      return;
    }
    await _httpServer?.close();
  }

  // routes

  @Route.get('/fe/ping')
  Future<Response> ping(Request request) async {
    return textResponse('pong');
  }

  @Route.post('/fe/token')
  Future<Response> token(Request request) async {
    final body = await request.readAsString();
    final json = jsonDecode(body) as Map<String, dynamic>;
    final tenant = await server.data.getTenantByLogin(json['email'], json['password']);
    if (tenant == null) {
      return response(401);
    }

    final token = await server.data.getTenantTokenById(tenant.id);
    return jsonResponse({'token': token});
  }

  @Route.get('/fe/domains')
  Future<Response> domains(Request request) async {
    final token = getTenantToken(request);
    if (token == null) {
      return response(401);
    }

    final tenant = await server.data.getTenantByToken(token);

    if (tenant == null) {
      return response(401);
    }

    final domains = await server.data.listDomainsByTenantId(tenant.id);
    return jsonResponse({
      'tenant': tenant.toJson(),
      'domains': domains?.map((d) => d.toJson()).toList(),
    });
  }

  @Route.get('/fe/domain/<domainId>')
  Future<Response> domain(Request request, String domainId) async {
    final token = getTenantToken(request);
    if (token == null) {
      return response(401);
    }

    final tenant = await server.data.getTenantByToken(token);
    if (tenant == null) {
      return response(401);
    }

    final domains = await server.data.listDomainsByTenantId(tenant.id);
    final domain = domains?.firstWhere((d) => d.id == domainId);
    if (domain == null) {
      logger.warning('domain not found : tenant=${tenant.profile.name} (${tenant.id}), domainId=$domainId');
      return response(404);
    }

    final episodes = await server.data.listEpisodes(tenantId: tenant.id, domainId: domain.id);
    if (episodes == null) {
      logger.warning('episodes not found : tenant=${tenant.profile.name} (${tenant.id}), domain=${domain.profile.name} (${domain.id})');
      return response(404);
    }

    return jsonResponse({
      'tenant': tenant.toJson(),
      'domain': domain.toJson(),
      'episodes': episodes.map((e) => e.toJson()).toList(),
    });
  }

  @Route.get('/fe/domain/<domainId>/episode/<episodeId>/shot/<shotIndex>/cam/<cameraIndex>')
  Future<Response> episodeImage(Request request, String domainId, String episodeId, String shotIndex, String cameraIndex) async {
    final token = getTenantToken(request);
    if (token == null) {
      logger.warning('token not found in request headers');
      return response(401);
    }

    final tenant = await server.data.getTenantByToken(token);
    if (tenant == null) {
      logger.warning('tenant not found for token: $token');
      return response(401);
    }

    final domains = await server.data.listDomainsByTenantId(tenant.id);
    final domain = domains?.firstWhere((d) => d.id == domainId);
    if (domain == null) {
      logger.warning('domain not found : tenant=${tenant.profile.name} (${tenant.id}), domainId=$domainId');
      return response(404);
    }

    final imageBytes = await server.data.getEpisodeImage(
      tenantId: tenant.id,
      domainId: domain.id,
      episodeId: episodeId,
      shotIndex: int.parse(shotIndex),
      cameraIndex: int.parse(cameraIndex),
    );
    if (imageBytes == null) {
      logger.warning('image not found : tenant=${tenant.profile.name} (${tenant.id}), domain=${domain.profile.name} (${domain.id}), episodeId=$episodeId, shotIndex=$shotIndex, cameraIndex=$cameraIndex');
      return response(404);
    }

    return Response.ok(
      imageBytes,
      headers: {
        'Content-Type': 'image/jpeg',
      },
    );
  }

  @Route.post('/fe/episode')
  Future<Response> createEpisode(Request request) async {
    final token = getTenantToken(request);
    if (token == null) {
      return response(401);
    }

    final tenant = await server.data.getTenantByToken(token);
    final domainId = request.headers['X-FE-Domain'];
    final appVersion = request.headers['X-FE-App-Version'];
    final detectorId = request.headers['X-FE-Detector'];

    if (tenant == null || domainId == null || appVersion == null || detectorId == null) {
      return response(401);
    }

    final form = request.formData();
    if (form == null) {
      return response(400, 'invalid form data');
    }

    final items = await form.formData.toList();
    final episode = Episode.fromJson(jsonDecode(await items.firstWhere((item) => item.name == 'data').part.readString()));

    logger.info('');
    logger.info('received episode #${episode.index} from tenant ${tenant.profile.name}');
    logger.info('domain : ${domainId}');
    logger.info('detector : ${detectorId} (${appVersion})');
    logger.info('files : ${items.length} (${items.map((e) => e.name).join(', ')})');

    final now = DateTime.now();
    Map<int, Uint8List>? images;
    // if (episode.captureResult != null) {
    //   images = <int, Uint8List>{
    //     for (final pair in episode.captureResult!.detectionsByImage.entries)
    //       pair.key: await items.firstWhere((item) => item.name == 'image_${pair.key}').part.readBytes(),
    //   };
    // }
    final duration = DateTime.now().difference(now);

    logger.info('images : ${images?.length ?? '-'} (${duration.inMilliseconds} ms)');
    logger.info('');

    await server.data.recordEpisode(
      tenantId: tenant.id,
      domainId: domainId,
      detectorId: detectorId,
      episode: episode,
      images: images,
    );

    return textResponse('ok');
  }

  // middleware

  Middleware authMiddleware() {
    return (Handler innerHandler) {
      return (Request request) async {
        final requestEnv = request.headers['X-FE'];
        if (requestEnv == null || requestEnv.isEmpty) {
          return Response.unauthorized('');
        }

        return await innerHandler(request);
      };
    };
  }

  Middleware createCorsMiddleware() {
    // 모든 응답에 공통으로 들어갈 CORS 헤더
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*', // 실제 서비스에서는 특정 도메인을 지정하는 것이 안전합니다.
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': '*',
    };

    return (Handler innerHandler) {
      return (Request request) async {
        // logger.warning('[CORS] ${request.method} ${request.requestedUri}');

        // 💡 핵심: Preflight(OPTIONS) 요청이 들어오면 바로 CORS 헤더와 함께 200 응답을 보냄
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: corsHeaders);
        }

        // 일반 요청(GET, POST 등)은 다음 핸들러로 진행시킨 뒤, 응답에 CORS 헤더를 추가함
        final response = await innerHandler(request);
        return response.change(
          headers: {
            ...response.headers,
            ...corsHeaders,
          },
        );
      };
    };
  }

  // utils

  String? getTenantToken(Request request) {
    final requestEnv = request.headers['Authorization'];
    if (requestEnv == null || requestEnv.isEmpty) {
      return null;
    }
    return requestEnv.split(' ').last;
  }

  Response response(int statusCode, [String body = '']) {
    return Response(
      statusCode,
      body: body,
      headers: {
        'Content-Type': 'text/plain',
      },
    );
  }

  Response textResponse(String text, {int statusCode = 200}) {
    return Response(
      statusCode,
      body: text,
      headers: {
        'Content-Type': 'text/plain',
      },
    );
  }

  Response jsonResponse(Map<String, dynamic> data, {int statusCode = 200}) {
    return Response(
      statusCode,
      body: jsonEncode(data),
      headers: {
        'Content-Type': 'application/json',
      },
    );
  }
}
