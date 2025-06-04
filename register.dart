import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:student_ehailing/verifyemail.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  final database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://student-ehailing-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  final TextEditingController name = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController phone = TextEditingController();

  String gender = 'Male';
  String role = 'Passenger';

  register() async {
    // Validate form before proceeding
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text,
      );
      final uid = userCredential.user!.uid;

      // Common user data
      final userData = {
        'uid': uid,
        'name': name.text.trim(),
        'email': email.text.trim(),
        'phone': phone.text.trim(),
        'gender': gender,
        'role': role,
        'registeredAt': DateTime.now().toIso8601String(),
        'emailVerified': false,
        'biometricSetup': false,
      };

      // Store in role-specific table
      if (role == 'Passenger') {
        // Store in passengers table with passenger-specific fields
        await database.ref('passengers/$uid').set({
          ...userData,
          'ridesCount': 0,
          'favoriteDestinations': [],
          'paymentMethods': [],
          'isActive': true,
        });
      } else if (role == 'Driver') {
        // Store in drivers table with driver-specific fields
        await database.ref('drivers/$uid').set({
          ...userData,
          'vehicleInfo': {
            'make': '',
            'model': '',
            'year': '',
            'plateNumber': '',
            'color': '',
            'capacity': 4,
          },
          'licenseNumber': '',
          'isVerified': false,
          'isOnline': false,
          'rating': 0.0,
          'totalRides': 0,
          'documentsSubmitted': false,
        });
      }

      // Also maintain a general users table for authentication reference
      await database.ref('users/$uid').set({
        'email': email.text.trim(),
        'role': role,
        'isActive': true,
        'registeredAt': DateTime.now().toIso8601String(),
      });

      // Navigate to email verification screen
      Get.offAll(() => Verify());
    } on FirebaseAuthException catch (e) {
      Get.snackbar("Error", e.message ?? "Something went wrong");
    } catch (e) {
      Get.snackbar("Error", "Failed to register. Please try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Register")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: name,
                  decoration: InputDecoration(hintText: 'Enter full name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: email,
                  decoration: InputDecoration(hintText: 'Enter email'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an email';
                    }
                    if (!value.endsWith('@student.uthm.edu.my')) {
                      return 'Email must be from @student.uthm.edu.my domain';
                    }
                    if (!RegExp(r'^[^@]+@student\.uthm\.edu\.my$').hasMatch(value)) {
                      return 'Please enter a valid email format';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: password,
                  obscureText: true,
                  decoration: InputDecoration(hintText: 'Enter password'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    if (!RegExp(r'[A-Z]').hasMatch(value)) {
                      return 'Password must contain at least one capital letter';
                    }
                    if (!RegExp(r'[0-9!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
                      return 'Password must contain at least one number or special character';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: phone,
                  decoration: InputDecoration(hintText: 'Enter phone number'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (value.length < 10) {
                      return 'Please enter valid phone number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                DropdownButton<String>(
                  value: gender,
                  onChanged: (value) {
                    setState(() {
                      gender = value!;
                    });
                  },
                  items: ['Male', 'Female'].map((g) {
                    return DropdownMenuItem(value: g, child: Text(g));
                  }).toList(),
                ),
                DropdownButton<String>(
                  value: role,
                  onChanged: (value) {
                    setState(() {
                      role = value!;
                    });
                  },
                  items: ['Passenger', 'Driver'].map((r) {
                    return DropdownMenuItem(value: r, child: Text(r));
                  }).toList(),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: register,
                  child: Text("Register"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}