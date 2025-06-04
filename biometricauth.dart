import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:local_auth/local_auth.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricAuthService {
  static final LocalAuthentication _localAuth = LocalAuthentication();
  static final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  static final database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://student-ehailing-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  // Save user credentials securely when they first login with email/password
  static Future<void> saveUserCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', email);
    await prefs.setString('user_password', password);
  }

  // Check if user has biometric enabled
  static Future<bool> isBiometricEnabled() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      final snapshot = await database.ref("users/${user.uid}").get();
      if (snapshot.exists) {
        final userData = Map<String, dynamic>.from(snapshot.value as Map);
        return userData['biometric_enabled'] ?? false;
      }
    }
    return false;
  }

  // Check if device supports biometric
  static Future<bool> canUseBiometric() async {
    bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
    bool isDeviceSupported = await _localAuth.isDeviceSupported();
    return canCheckBiometrics && isDeviceSupported;
  }

  // Authenticate with biometric and login
  static Future<bool> authenticateWithBiometric() async {
    try {
      if (!await canUseBiometric()) {
        Get.snackbar("Error", "Biometric authentication not available");
        return false;
      }

      bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Use your fingerprint to login',
        options: const AuthenticationOptions(biometricOnly: true),
      );

      if (authenticated) {
        // Get saved credentials
        final prefs = await SharedPreferences.getInstance();
        String? email = prefs.getString('user_email');
        String? password = prefs.getString('user_password');

        if (email != null && password != null) {
          // Login with saved credentials
          final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );

          if (userCredential.user != null) {
            Get.snackbar("Success", "Login successful!");
            return true;
          }
        } else {
          Get.snackbar("Error", "No saved credentials found. Please login with email/password first.");
          return false;
        }
      }
    } catch (e) {
      Get.snackbar("Error", "Biometric authentication failed: $e");
    }
    return false;
  }

  // Check if user has saved credentials for biometric login
  static Future<bool> hasSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('user_email');
    String? password = prefs.getString('user_password');
    return email != null && password != null;
  }

  // Clear saved credentials (for logout)
  static Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_email');
    await prefs.remove('user_password');
  }
}