import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:student_ehailing/biometric.dart';  // import biometric page

class Verify extends StatefulWidget {
  const Verify({super.key});

  @override
  State<Verify> createState() => _VerifyState();
}

class _VerifyState extends State<Verify> {
  bool isEmailVerified = false;

  @override
  void initState() {
    super.initState();
    sendVerifyLink();
  }

  Future<void> sendVerifyLink() async {
    final user = FirebaseAuth.instance.currentUser!;
    await user.sendEmailVerification();
    Get.snackbar('Link sent', 'Please check your email',
        margin: EdgeInsets.all(30), snackPosition: SnackPosition.BOTTOM);
  }

  Future<void> reload() async {
    await FirebaseAuth.instance.currentUser!.reload();
    final user = FirebaseAuth.instance.currentUser!;
    setState(() {
      isEmailVerified = user.emailVerified;
    });
    if (isEmailVerified) {
      // If email is verified, go to biometric setup page
      Get.offAll(() => BiometricSetup());
    } else {
      Get.snackbar("Not verified", "Please verify your email first.",
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Verification")),
      body: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Center(
          child: Text(
              'Open your mail and click on the link provided and refresh this page'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: reload,
        child: Icon(Icons.restart_alt_rounded),
      ),
    );
  }
}
