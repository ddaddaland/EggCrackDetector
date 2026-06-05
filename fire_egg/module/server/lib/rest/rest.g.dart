// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rest.dart';

// **************************************************************************
// ShelfRouterGenerator
// **************************************************************************

Router _$FireEggServerRestRouter(FireEggServerRest service) {
  final router = Router();
  router.add('GET', r'/fe/ping', service.ping);
  router.add('POST', r'/fe/token', service.token);
  router.add('GET', r'/fe/domains', service.domains);
  router.add('GET', r'/fe/domain/<domainId>', service.domain);
  router.add(
    'GET',
    r'/fe/domain/<domainId>/episode/<episodeId>/shot/<shotIndex>/cam/<cameraIndex>',
    service.episodeImage,
  );
  router.add('POST', r'/fe/episode', service.createEpisode);
  return router;
}
