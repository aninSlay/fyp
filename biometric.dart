import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:get/get.dart';
import 'package:student_ehailing/wrapper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';

class BiometricSetup extends StatefulWidget {
  const BiometricSetup({super.key});

  @override
  State<BiometricSetup> createState() => _BiometricSetupState();
}

class _BiometricSetupState extends State<BiometricSetup> {
  final LocalAuthentication auth = LocalAuthentication();

  // Add the database reference with proper configuration
  final database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://student-ehailing-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  Future<void> authenticateUser() async {
    bool canCheckBiometrics = await auth.canCheckBiometrics;
    bool isDeviceSupported = await auth.isDeviceSupported();

    if (canCheckBiometrics && isDeviceSupported) {
      try {
        bool authenticated = await auth.authenticate(
          localizedReason: 'Please authenticate to set up biometric login',
          options: const AuthenticationOptions(biometricOnly: true),
        );

        if (authenticated) {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            // Update the user's biometric status in Firebase Database
            DatabaseReference ref = database.ref("users/${user.uid}");

            // Get existing user data first
            DataSnapshot snapshot = await ref.get();
            Map<String, dynamic> userData = {};

            if (snapshot.exists) {
              userData = Map<String, dynamic>.from(snapshot.value as Map);
            }

            // Update with biometric info while preserving existing data
            userData.addAll({
              "biometricSetup": true,
              "biometric_enabled": true,
              "biometric_setup_at": DateTime.now().toIso8601String(),
            });

            await ref.set(userData);
          }

          Get.snackbar("Success", "Biometric setup complete! You can now use fingerprint to login.",
              snackPosition: SnackPosition.BOTTOM);
          Get.offAll(() => Wrapper());
        } else {
          Get.snackbar("Failed", "Authentication failed.",
              snackPosition: SnackPosition.BOTTOM);
        }
      } catch (e) {
        Get.snackbar("Error", "An error occurred: $e",
            snackPosition: SnackPosition.BOTTOM);
      }
    } else {
      Get.snackbar("Unsupported", "Biometric not supported on this device.",
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void skipBiometric() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Update biometric status to false when skipped
      DatabaseReference ref = database.ref("users/${user.uid}");

      DataSnapshot snapshot = await ref.get();
      Map<String, dynamic> userData = {};

      if (snapshot.exists) {
        userData = Map<String, dynamic>.from(snapshot.value as Map);
      }

      userData.addAll({
        "biometricSetup": false,
        "biometric_enabled": false,
      });

      await ref.set(userData);
    }

    Get.offAll(() => Wrapper());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Biometric Setup")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fingerprint,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 20),
            Text(
              "Secure Your Account",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              "Enable biometric login to access your account quickly and securely using your fingerprint.",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: authenticateUser,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text("Enable Biometric Login", style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: skipBiometric,
                child: Text("Skip for now", style: TextStyle(fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }
}