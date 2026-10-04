import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nest_craft/LoginPage.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
          return  Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
  print("going to homepage");

  return Scaffold(
    appBar: AppBar(
      title: const Text('Home Page'),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Logout',
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
          },
        ),
      ],
    ),

    body: const Center(
      child: Text(
        'Home Page',
        style: TextStyle(fontSize: 24),
      ),
    ),
  );
}

        print("going to login page");
        return LoginPage();
      },
    );
  }
}