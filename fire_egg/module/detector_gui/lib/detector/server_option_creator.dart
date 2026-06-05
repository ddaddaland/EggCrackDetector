import 'dart:convert';

import 'package:fire_egg_common/domain/domain.dart';
import 'package:fire_egg_common/server/connector.dart';
import 'package:fire_egg_common/tenant/tenant.dart';
import 'package:fire_egg_common/util/response.dart';
import 'package:fire_egg_detector/detector/option/server_option.dart';
import 'package:fire_egg_widgets/container/light_box.dart';
import 'package:fire_egg_widgets/server/token_form.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DetectorServerOptionCreator extends StatefulWidget {
  final void Function(ServerOption option) onCreate;
  final String? initialPassword;

  const DetectorServerOptionCreator({
    super.key,
    required this.onCreate,
    this.initialPassword,
  });

  @override
  State<DetectorServerOptionCreator> createState() => _DetectorServerOptionCreatorState();
}

class _DetectorServerOptionCreatorState extends State<DetectorServerOptionCreator> {

  bool busy = false;

  (String address, String token, Tenant tenant, List<Domain>? domains)? tenantAndDomains;

  void tryLogin(String address, String email, String token) async {
    setState(() {
      busy = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    final loginedConnector = ServerConnector(
      address: address,
      token: token,
    );

    final resp = await loginedConnector.getTenantAndDomains();
    if (resp == null) {
      setState(() {
        busy = false;
      });
      return;
    }

    tenantAndDomains = (address, token, resp.$1, resp.$2);
    setState(() {
      busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return Padding(
        padding: const EdgeInsets.all(50),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (tenantAndDomains != null) {
      final (address, token, tenant, domains) = tenantAndDomains!;

      return Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 10,
        children: [
          LightBox.label(
            label: '계정',
            icon: Icons.account_circle,
            child: Text('${tenant.id}\n${tenant.profile.name}'),
          ),
          LightBox.label(
            icon: Icons.domain,
            label: '사업장',
            child: domains == null || domains.isEmpty
                ? LightBox(
                    child: Center(child: Text('비어 있음')),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 5,
                    children: [
                      ...domains.map(
                        (domain) => LightBox(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            spacing: 10,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${domain.profile.name}'),
                                  Text(
                                    '${domain.profile.location}',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton(
                                child: Text('선택'),
                                onPressed: () {
                                  widget.onCreate(
                                    ServerOption(
                                      address: address,
                                      token: token,
                                      displayName: '${tenant.profile.name} (${domain.profile.name})',
                                      domainId: domain.id,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 15,
      children: [
        ServerTokenLoginForm(
          initialPassword: widget.initialPassword,
          onLogin: tryLogin,
        ),
      ],
    );
  }
}
