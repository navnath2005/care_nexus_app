import 'package:care_nexus/main.dart';
import 'package:care_nexus/routes.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth/login_page.dart';

class CareNexus extends StatelessWidget {
  const CareNexus({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Care Nexus",
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          /// still connecting...
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          /// not logged in
          if (!snapshot.hasData) return const LoginPage();

          /// logged in
          return const RoleRouter();
        },
      ),
    );
  }
}
