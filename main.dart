import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart'; // Import LoginPage
import 'main_page.dart'; // Import MainPage
import 'password_update_page.dart';
import 'sign_up_page.dart'; // Import SignUpPage

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyCZtQcxIREtqDNKb8eynmvzmpIdDtttMBM",
      authDomain: "expense-tracker-5cf1f.firebaseapp.com",
      projectId: "expense-tracker-5cf1f",
      storageBucket: "expense-tracker-5cf1f.firebasestorage.app",
      messagingSenderId: "1000191019542",
      appId: "1:1000191019542:web:69a5353968bfe1b9320337",
      measurementId: "G-0BWN8ETJWZ",
    ),
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      home: AuthenticationWrapper(),
      routes: {
        '/login': (context) => LoginPage(), // Define the login route
        '/main': (context) => MainPage(),   // Define the main route
        '/signup': (context) => SignUpPage(), // Define the sign-up route
      },
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          return MainPage(); // User is logged in, navigate to MainPage
        } else if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        } else {
          return LoginPage(); // User is not logged in, navigate to LoginPage
        }
      },
    );
  }
}
