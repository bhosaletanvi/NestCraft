import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
          return const Scaffold(
            body: Center(
              child: Text('Home Page'),
            ),
          );
        }

        print("going to login page");
        return const Scaffold(
          body: Center(
            child: Text('Login Page'),
          ),
        );
      },
    );
  }
}