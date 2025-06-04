import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:student_ehailing/passenger/homepage_passenger.dart';
import 'package:student_ehailing/login.dart';
import 'package:student_ehailing/verifyemail.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context,snapshot){
            if (snapshot.hasData){
              print(snapshot.data);
              if(snapshot.data!.emailVerified){
                return Homepage();
              }
              else{
                return Verify();
              }
          }
            else{
             return Login();
            }
    }),
    );
  }
}
