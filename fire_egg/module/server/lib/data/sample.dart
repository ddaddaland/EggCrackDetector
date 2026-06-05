import 'dart:typed_data';

import 'package:fire_egg_common/domain/domain.dart';
import 'package:fire_egg_common/domain/profile.dart';
import 'package:fire_egg_common/episode/domain_episode.dart';
import 'package:fire_egg_common/episode/episode.dart';
import 'package:fire_egg_common/tenant/profile.dart';
import 'package:fire_egg_common/tenant/tenant.dart';
import 'package:fire_egg_server/data/provider.dart';

class SampleDataProvider extends AbstractDataProvider {
  final List<_SampleTenant> _tenants = [
    _SampleTenant(
      email: 'test@test.test',
      password: 'password',
      token: 'token-dev-000-token',
      id: 'tenant-dev-000',
      tenant: Tenant(
        id: 'tenant-dev-000',
        profile: TenantProfile(
          name: '유태컴퍼니',
        ),
      ),
      domains: [
        _SampleDomain(
          tenantId: 'tenant-dev-000',
          id: 'domain-000',
          createTime: DateTime.now().millisecondsSinceEpoch,
          profile: DomainProfile(
            name: '농장 A001',
            location: '서울',
          ),
        ),
        _SampleDomain(
          tenantId: 'tenant-dev-000',
          id: 'domain-001',
          createTime: DateTime.now().millisecondsSinceEpoch,
          profile: DomainProfile(
            name: '농장 A002',
            location: '부산',
          ),
        ),
      ],
    ),
  ];

  @override
  Future<Tenant?> getTenantById(String id) async {
    for (final tenant in _tenants) {
      if (tenant.id == id) {
        return tenant.tenant;
      }
    }
    return null;
  }

  @override
  Future<Tenant?> getTenantByToken(String token) async {
    for (final tenant in _tenants) {
      if (tenant.token == token) {
        return tenant.tenant;
      }
    }
    return null;
  }

  @override
  Future<List<Domain>?> listDomainsByTenantId(String tenantId) async {
    for (final tenant in _tenants) {
      if (tenant.id == tenantId) {
        return tenant.domains;
      }
    }
    return null;
  }

  @override
  Future<Tenant?> getTenantByLogin(String email, String password) async {
    for (final tenant in _tenants) {
      if (tenant.email == email && tenant.password == password) {
        return tenant.tenant;
      }
    }
    return null;
  }

  @override
  Future<String?> getTenantTokenById(String tenantId) async {
    for (final tenant in _tenants) {
      if (tenant.id == tenantId) {
        return tenant.token;
      }
    }
    return null;
  }

  @override
  Future<bool> recordEpisode({
    required String tenantId,
    required String domainId,
    required String detectorId,
    required Episode episode,
    required Map<int, Uint8List>? images,
  }) async {
    for (final tenant in _tenants) {
      if (tenant.id == tenantId) {
        for (final domain in tenant.domains) {
          if (domain.id == domainId) {
            for (final s in episode.shots) {
              for (final i in s.images) {
                domain.images['${episode.index}/${s.index}/${i.cameraIndex}'] = Uint8List.fromList(i.bytes);
                i.bytes.clear();
              }
            }

            domain.episodes.add(
              DomainEpisode(
                index: episode.index,
                objectClasses: episode.objectClasses,
                domainId: domainId,
                detectorId: detectorId,
                eggs: episode.eggs,
                shots: episode.shots,
                imageSize: episode.imageSize,
                createTime: episode.createTime,
                creating: episode.creating,
                inferred: episode.inferred,
                inferenceStatus: episode.inferenceStatus,
                detections: episode.detections,
                error: episode.error,
              ),
            );
            // if (images != null) {
            //   images.forEach((key, value) {
            //     domain.images['${episode.index}/$key'] = value;
            //   });
            // }
            return true;
          }
        }
      }
    }
    return false;
  }

  @override
  Future<Uint8List?> getEpisodeImage({
    required String tenantId,
    required String domainId,
    required String episodeId,
    required int shotIndex,
    required int cameraIndex,
  }) async {
    for (final tenant in _tenants) {
      if (tenant.id == tenantId) {
        for (final domain in tenant.domains) {
          if (domain.id == domainId) {
            return domain.images['$episodeId/${shotIndex}/${cameraIndex}'];
          }
        }
      }
    }
    return null;
  }

  @override
  Future<List<DomainEpisode>?> listEpisodes({required String tenantId, required String domainId}) async {
    for (final tenant in _tenants) {
      if (tenant.id == tenantId) {
        for (final domain in tenant.domains) {
          if (domain.id == domainId) {
            return domain.episodes;
          }
        }
      }
    }
    return null;
  }
}

class _SampleTenant {
  final String email, password;
  final String token;
  final String id;
  final Tenant tenant;
  final List<_SampleDomain> domains;

  _SampleTenant({
    required this.email,
    required this.password,
    required this.id,
    required this.token,
    required this.tenant,
    required this.domains,
  });
}

class _SampleDomain extends Domain {
  final List<DomainEpisode> episodes = [];
  final Map<String, Uint8List> images = {};

  _SampleDomain({
    required super.tenantId,
    required super.id,
    required super.createTime,
    required super.profile,
  });
}
