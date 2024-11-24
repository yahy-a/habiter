import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habiter_/screens/structure.dart';
import 'package:habiter_/screens/signIn/login.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox(
        height: double.infinity,
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              height: 270,
              child: Image.asset('assets/images/welcome.png'),
            ),
            const SizedBox(height: 100,),
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFBB4EFC),
                    Color(0xFF7F6AF5)
                  ], // Gradient colors
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const SizedBox(height: 60,),
                    AnimatedTextKit(
                      animatedTexts: [
                        TyperAnimatedText(
                            "Welcome to Habiter, your guide to better habits. Track progress and stay motivated as you make lasting changes.",
                            textStyle: GoogleFonts.roboto(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            speed: const Duration(milliseconds: 100)),
                      ],
                      totalRepeatCount: 1,
                      pause: const Duration(milliseconds: 1000),
                      displayFullTextOnTap: true,
                      stopPauseOnTap: true,
                    ),
                    const SizedBox(height: 40,),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const HomeScreen()));
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 124, 32, 245),
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          )),
                      child: const SizedBox(
                          height: 50,
                          width: 150,
                          child: Center(
                            child: Text(
                              "Continue",
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                              ),
                            ),
                          )),
                    ),
                    const SizedBox(height: 30,)
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
