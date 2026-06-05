import 'package:fire_egg_common/server/connector.dart';
import 'package:fire_egg_dashboard/tenant/widget.dart';
import 'package:fire_egg_widgets/container/light_box.dart';
import 'package:fire_egg_widgets/server/token_form.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

class FireEggDashboardHome extends StatefulWidget {
  const FireEggDashboardHome({super.key});

  @override
  State<FireEggDashboardHome> createState() => _FireEggDashboardHomeState();
}

class _FireEggDashboardHomeState extends State<FireEggDashboardHome> {
  (ServerConnector, String)? credentials;

  @override
  Widget build(BuildContext context) {
    if (credentials != null) {
      return TenantWidget(
        connector: credentials!.$1,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          spacing: 7,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.login),
            Text(
              '대시보드 로그인',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Center(
        child: LightBox(
          width: 400,
          padding: EdgeInsets.all(15),
          child: AnimatedSize(
            duration: Durations.short4,
            curve: Curves.easeOutQuart,
            child: ServerTokenLoginForm(
              onLogin: (address, email, token) {
                final newConnector = ServerConnector(
                  address: address,
                  token: token,
                );

                setState(() {
                  credentials = (newConnector, email);
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}
