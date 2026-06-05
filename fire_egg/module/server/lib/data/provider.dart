import 'dart:typed_data';

import 'package:fire_egg_common/domain/domain.dart';
import 'package:fire_egg_common/episode/domain_episode.dart';
import 'package:fire_egg_common/episode/episode.dart';
import 'package:fire_egg_common/tenant/tenant.dart';

abstract class AbstractDataProvider {
  // tenant
  Future<Tenant?> getTenantById(String id);

  Future<Tenant?> getTenantByToken(String token);

  Future<Tenant?> getTenantByLogin(String email, String password);

  Future<String?> getTenantTokenById(String tenantId);

  // domain
  Future<List<Domain>?> listDomainsByTenantId(String tenantId);

  // episode
  Future<bool?> recordEpisode({
    required String tenantId,
    required String domainId,
    required String detectorId,
    required Episode episode,
    required Map<int, Uint8List>? images,
  });

  Future<List<DomainEpisode>?> listEpisodes({
    required String tenantId,
    required String domainId,
  });

  Future<Uint8List?> getEpisodeImage({
    required String tenantId,
    required String domainId,
    required String episodeId,
    required int shotIndex,
    required int cameraIndex,
  });
}
