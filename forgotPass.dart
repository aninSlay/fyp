import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class forgotPass extends StatefulWidget {
  const forgotPass({super.key});

  @override
  State<forgotPass> createState() => _forgotPassState();
}

class _forgotPassState extends State<forgotPass> {

  TextEditingController email=TextEditingController();

  reset()async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Forgot password"),),
        body:Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              TextField(
                controller: email,
                decoration: InputDecoration(hintText: 'Enter email'),
              ),

              ElevatedButton(onPressed: (()=>reset()), child: Text("Reset Password"))
            ],
          ),
        )
    );
  }
}
