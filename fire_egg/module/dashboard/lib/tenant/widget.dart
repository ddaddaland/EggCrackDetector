import 'package:fire_egg_common/domain/domain.dart';
import 'package:fire_egg_common/server/connector.dart';
import 'package:fire_egg_common/tenant/tenant.dart';
import 'package:fire_egg_dashboard/domain/widget.dart';
import 'package:fire_egg_widgets/container/light_box.dart';
import 'package:flutter/material.dart';

class TenantWidget extends StatefulWidget {
  final ServerConnector connector;

  const TenantWidget({
    super.key,
    required this.connector,
  });

  @override
  State<TenantWidget> createState() => _TenantWidgetState();
}

class _TenantWidgetState extends State<TenantWidget> {
  late final connector = widget.connector;
  bool busy = false;
  bool error = false;

  Tenant? tenant;
  List<Domain>? domains;

  void showDomain(Tenant tenant, Domain domain) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DomainWidget(
          tenant: tenant,
          domain: domain,
          connector: connector,
        ),
      ),
    );
  }

  void load() async {
    setState(() {
      busy = true;
    });

    await Future.delayed(const Duration(seconds: 1));
    final result = await connector.getTenantAndDomains();
    if (result == null) {
      setState(() {
        error = true;
        busy = false;
      });
      return;
    }

    tenant = result.$1;
    domains = result.$2;

    setState(() {
      busy = false;
    });
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          spacing: 15,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 7,
              children: [
                Icon(Icons.dashboard),
                Text('대시보드 '),
              ],
            ),
            Builder(
              builder: (context) {
                if (tenant != null) {
                  return Row(
                    spacing: 4,
                    children: [
                      Icon(Icons.person),
                      Text(
                        '${tenant!.profile.name}',
                        style: TextStyle(
                          fontSize: 15,
                        ),
                      ),
                    ],
                  );
                }

                return SizedBox();
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Builder(
          builder: (context) {
            if (busy) {
              return Center(
                child: const CircularProgressIndicator(),
              );
            }

            final tenant = this.tenant;
            final domains = this.domains;

            if (error || tenant == null) {
              return Icon(Icons.error);
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 10,
              children: [
                // acc
                LightBox.label(
                  label: '계정',
                  icon: Icons.account_circle,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${tenant.profile.name}',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                // domains
                Expanded(
                  child: LightBox.label(
                    label: '사업장',
                    icon: Icons.domain,
                    child: domains == null || domains.isEmpty
                        ? LightBox(
                            child: Center(child: Text('비어 있음')),
                          )
                        : Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                spacing: 5,
                                children: [
                                  ...domains.map(
                                    (domain) => LightBox(
                                      onTap: () => showDomain(tenant, domain),
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
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
