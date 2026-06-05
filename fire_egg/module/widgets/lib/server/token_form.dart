import 'package:fire_egg_common/server/connector.dart';
import 'package:fire_egg_widgets/container/light_box.dart';
import 'package:flutter/material.dart';

class ServerTokenLoginForm extends StatefulWidget {
  final String? initialPassword;
  final void Function(String address, String email, String token) onLogin;

  const ServerTokenLoginForm({
    super.key,
    required this.onLogin,
    this.initialPassword,
  });

  @override
  State<ServerTokenLoginForm> createState() => _ServerTokenLoginFormState();
}

class _ServerTokenLoginFormState extends State<ServerTokenLoginForm> {
  late final addressController = TextEditingController(text: 'https://server.cracked-egg-detector.xyz');
  late final emailController = TextEditingController(text: 'test@test.test');
  late final passwordController = TextEditingController(text: widget.initialPassword ?? '');

  bool busy = false;

  void tryLogin() async {
    setState(() {
      busy = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    final address = addressController.text;
    final email = emailController.text;
    final password = passwordController.text;
    final connector = ServerConnector(address: address, token: null);

    final token = await connector.getToken(
      email: email,
      password: password,
    );

    if (token == null) {
      setState(() {
        busy = false;
      });
      return;
    }

    widget.onLogin(address, email, token);
  }

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return Container(
        padding: EdgeInsets.all(35),
        child: SizedBox(
          width: 30,
          child: LinearProgressIndicator(),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 15,
      children: [
        LightBox.label(
          label: '서버 주소',
          icon: Icons.link,
          child: TextField(
            controller: addressController,
            onChanged: (s) => setState(() {}),
            decoration: InputDecoration(
              suffix: IconButton(
                icon: Icon(Icons.data_object),
                onPressed: () {
                  addressController.text = 'http://localhost:13333';
                },
              ),
            ),
          ),
        ),
        LightBox.label(
          label: '이메일',
          icon: Icons.email,
          child: TextField(
            controller: emailController,
            onChanged: (s) => setState(() {}),
          ),
        ),
        LightBox.label(
          label: '비밀번호',
          icon: Icons.password,
          child: TextField(
            controller: passwordController,
            onChanged: (s) => setState(() {}),
            obscureText: true,
          ),
        ),

        ElevatedButton(
          child: Text('로그인'),
          onPressed: addressController.text.isEmpty || emailController.text.isEmpty || passwordController.text.isEmpty ? null : tryLogin,
        ),
      ],
    );
  }
}
