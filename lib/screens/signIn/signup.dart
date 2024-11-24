import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habiter_/firebase%20services/firebase_auth.dart';
import 'package:habiter_/screens/signIn/login.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final formKey_ = GlobalKey<FormState>();
  bool isChecked = false;

  final FirebaseAuthServices _auth = FirebaseAuthServices();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  Future<void> signUp() async {
    if (isChecked) {
      if (formKey_.currentState!.validate()) {
        String email = _emailController.text;
        String password = _passwordController.text;

        User? user = await _auth.signupWithEmailAndPassword(email, password);
        

        if (user != null) {
          // ignore: use_build_context_synchronously
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const LoginScreen()));
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Failed to sign up')));
        }
      }
    } else{
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("please agree to the terms and conditions")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(39, 46, 238, 0.08),
      body: SingleChildScrollView(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(
                height: 70,
              ),
              Image.asset(
                'assets/images/Splash.png',
                scale: 2,
              ),
              // const SizedBox(
              //   height: 20,
              // ),
              Text(
                'Create your account',
                style: GoogleFonts.nunito(
                    fontSize: 30,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
              // const SizedBox(
              //   height: 10,
              // ),
              Form(
                  key: formKey_,
                  child: Column(children: [
                    Container(
                      margin: const EdgeInsets.fromLTRB(15, 15, 15, 0),
                      child: TextFormField(
                        style: const TextStyle(color: Colors.white),
                        controller: _nameController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color.fromRGBO(82, 82, 82, 1),
                          hintText: 'Full Name',
                          hintStyle: GoogleFonts.rubik(
                              fontSize: 18, color: Colors.white),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none),
                          enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide.none), // Remove underline
                          focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide.none),
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Enter a valid name';
                          }
                          return null;
                        },
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.fromLTRB(15, 15, 15, 0),
                      child: TextFormField(
                        style: const TextStyle(color: Colors.white),
                        controller: _emailController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color.fromRGBO(82, 82, 82, 1),
                          hintText: 'Email Address',
                          hintStyle: GoogleFonts.rubik(
                              fontSize: 18, color: Colors.white),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none),
                          enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide.none), // Remove underline
                          focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide.none),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an email address';
                          }
                          if (!RegExp(
                                  r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
                              .hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.fromLTRB(15, 15, 15, 0),
                      child: TextFormField(
                        style: const TextStyle(color: Colors.white),
                        controller: _passwordController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color.fromRGBO(82, 82, 82, 1),
                          hintText: 'Password',
                          hintStyle: GoogleFonts.rubik(
                              fontSize: 18, color: Colors.white),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none),
                          enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide.none), // Remove underline
                          focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide.none),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 8) {
                            return 'Password must be at least 8 characters long';
                          }
                          return null;
                        },
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.fromLTRB(15, 15, 15, 3),
                      child: TextFormField(
                        style: const TextStyle(color: Colors.white),
                        controller: _confirmPasswordController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color.fromRGBO(82, 82, 82, 1),
                          hintText: 'Confirm Password',
                          hintStyle: GoogleFonts.rubik(
                              fontSize: 18, color: Colors.white),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none),
                          enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide.none), // Remove underline
                          focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide.none),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          RichText(
                              text: TextSpan(children: <TextSpan>[
                            TextSpan(
                                text: 'I have read the ',
                                style: GoogleFonts.rubik(
                                  fontSize: 18,
                                )),
                            TextSpan(
                                text: 'Privacy Policy',
                                style: GoogleFonts.rubik(
                                  fontSize: 18,
                                  color: Colors.blueAccent, // Color of the link
                                  decoration: TextDecoration.underline,
                                )),
                          ])),
                          Checkbox(
                            value: isChecked,
                            onChanged: (value) {
                              setState(() {
                                isChecked = value!;
                              });
                            },
                            activeColor: Colors.blue,
                          )
                        ]),
                    const SizedBox(
                      height: 20,
                    ),
                    SizedBox(
                      width: 330,
                      height: 55,
                      child: TextButton(
                        onPressed: signUp,
                        style: TextButton.styleFrom(
                          backgroundColor:
                              const Color.fromRGBO(141, 74, 248, 1),
                        ),
                        child: Text(
                          'Sign Up',
                          style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginScreen())),
                      child: RichText(
                        text: TextSpan(children: [
                          TextSpan(
                              text: "ALREADY HAVE AN ACCOUNT? ",
                              style: GoogleFonts.nunito(
                                  color: const Color.fromRGBO(161, 164, 178, 1),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w200)),
                          TextSpan(
                              text: "SIGN IN",
                              style: GoogleFonts.nunito(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  decoration: TextDecoration.underline))
                        ]),
                      ),
                    )
                  ]))
            ],
          ),
        ),
      ),
    );
  }
}
