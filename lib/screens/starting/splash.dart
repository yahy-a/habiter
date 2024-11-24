import 'dart:async';

import 'package:flutter/material.dart';
import 'package:habiter_/screens/starting/welcome.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin{

  late AnimationController _controller;
  late Animation<double> _animation;


  @override
  void initState(){
    super.initState();

  _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );

  _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut); 
  _controller.forward(); 


    Timer(const Duration(seconds: 4,),(){
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>const WelcomeScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Image.asset('assets/images/Splash.png',scale: 1,)
          ),
      )
    );
  }
}