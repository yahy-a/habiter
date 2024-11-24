import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habiter_/firebase%20services/firebase_auth.dart';
import 'package:habiter_/screens/signIn/login.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

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
                scale: 1.75,
              ),
              const SizedBox(
                height: 30,
              ),
              Text(
                'Change Password',
                style: GoogleFonts.nunito(
                    fontSize: 29,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(
                height: 10,
              ),
              Form(
                  key: _formKey,
                  child: Column(children: [
                    Container(
                      margin: const EdgeInsets.fromLTRB(15, 15, 15, 3),
                      child: TextFormField(
                        style: const TextStyle(color: Colors.white),
                        controller: _passwordController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color.fromRGBO(82, 82, 82, 1),
                          hintText: 'Current Password',
                          hintStyle: GoogleFonts.rubik(
                              fontSize: 18, color: Colors.white),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your current password';
                          }
                          if (value.length < 8) {
                            return 'Password must be at least 8 characters long';
                          }
                          return null;
                        },
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.fromLTRB(15, 15, 15, 15),
                      child: TextFormField(
                        style: const TextStyle(color: Colors.white),
                        controller: _newPasswordController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color.fromRGBO(82, 82, 82, 1),
                          hintText: 'New Password',
                          hintStyle: GoogleFonts.rubik(
                              fontSize: 18, color: Colors.white),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a new password';
                          }
                          if (value.length < 8) {
                            return 'Password must be at least 8 characters long';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(
                      width: 330,
                      height: 55,
                      child: TextButton(
                        onPressed: () async {
                          if(_formKey.currentState!.validate()){
                            bool isUpdated = await FirebaseAuthServices().updatePassword(_passwordController.text, _newPasswordController.text);
                            if(isUpdated){
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Password changed successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              // ignore: use_build_context_synchronously
                              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                            }else{
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to change password'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        style: TextButton.styleFrom(
                          backgroundColor:
                              const Color.fromRGBO(141, 74, 248, 1),
                        ),
                        child: Text(
                          'Change Password',
                          style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 50,
                    ),
                  ]))
            ],
          ),
        ),
      ),
    );
  }
}

