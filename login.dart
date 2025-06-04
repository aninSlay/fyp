import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:student_ehailing/register.dart';
import 'package:student_ehailing/forgotPass.dart';
import 'package:student_ehailing/wrapper.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();

  bool isloading = false;
  bool _showBiometricOption = false;
  final LocalAuthentication auth = LocalAuthentication();
  final storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  // Check if biometric login is available
  void _checkBiometricAvailability() async {
    bool canCheck = await auth.canCheckBiometrics;
    bool isSupported = await auth.isDeviceSupported();

    setState(() {
      _showBiometricOption = canCheck && isSupported;
    });
  }

  signIn() async {
    setState(() {
      isloading = true;
    });
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text,
        password: password.text,
      );

      await storage.write(key: 'email', value: email.text);
      await storage.write(key: 'password', value: password.text);

      Get.snackbar("Success", "Login successful!");
      Get.offAll(Wrapper());
    } on FirebaseAuthException catch (e) {
      Get.snackbar("Error", e.code);
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
    setState(() {
      isloading = false;
    });
  }

  biometricLogin() async {
    bool canCheck = await auth.canCheckBiometrics;
    bool isSupported = await auth.isDeviceSupported();

    if (!canCheck || !isSupported) {
      Get.snackbar("Error", "Biometric not supported on this device");
      return;
    }

    try {
      bool authenticated = await auth.authenticate(
        localizedReason: 'Use your fingerprint to login',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        // Read stored credentials
        String? savedEmail = await storage.read(key: 'email');
        String? savedPassword = await storage.read(key: 'password');

        if (savedEmail != null && savedPassword != null) {
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: savedEmail,
            password: savedPassword,
          );
          Get.snackbar("Success", "Login successful!");
          Get.offAll(Wrapper());
        } else {
          Get.snackbar("Error", "No credentials found. Please login manually first.");
        }
      }
    } catch (e) {
      Get.snackbar("Biometric Error", e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return isloading
        ? const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    )
        : Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: email,
              decoration: InputDecoration(
                hintText: 'Enter email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: password,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Enter password',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: signIn,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text("Login", style: TextStyle(fontSize: 16)),
              ),
            ),

            // Show biometric option if available
            if (_showBiometricOption) ...[
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text("OR", style: TextStyle(color: Colors.grey)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: biometricLogin,
                  icon: Icon(Icons.fingerprint, size: 24),
                  label: Text("Login with Fingerprint", style: TextStyle(fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],

            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Get.to(const Register()),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text("Register", style: TextStyle(fontSize: 16)),
              ),
            ),
            SizedBox(height: 12),
            TextButton(
              onPressed: () => Get.to(const forgotPass()),
              child: Text("Forgot password?", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}