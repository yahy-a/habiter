import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habiter_/firebase%20services/firebase_auth.dart';
import 'package:habiter_/providers/preferences_service.dart';
import 'package:habiter_/screens/structure.dart';
import 'package:habiter_/screens/signIn/signup.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuthServices _auth = FirebaseAuthServices();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void logIn(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      String email = _emailController.text;
      String password = _passwordController.text;

      User? user = await _auth.signInWithEmailAndPassword(email, password);

      if (user != null) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const HomeScreen()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid email or password')),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
                scale: 1.75,
              ),
              const SizedBox(
                height: 30,
              ),
              Text(
                'Welcome!',
                style: GoogleFonts.nunito(
                    fontSize: 36,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(
                height: 20,
              ),
              Form(
                  key: _formKey,
                  child: Column(children: [
                    Container(
                      margin: const EdgeInsets.fromLTRB(15, 15, 15, 3),
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
                      margin: const EdgeInsets.fromLTRB(15, 15, 15, 15),
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
                    SizedBox(
                      width: 330,
                      height: 55,
                      child: TextButton(
                        onPressed: () => logIn(context),
                        style: TextButton.styleFrom(
                          backgroundColor:
                              const Color.fromRGBO(141, 74, 248, 1),
                        ),
                        child: Text(
                          'Log In',
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
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SignupScreen())),
                      child: RichText(
                        text: TextSpan(children: [
                          TextSpan(
                              text: "DON’T HAVE AN ACCOUNT? ",
                              style: GoogleFonts.nunito(
                                  color: const Color.fromRGBO(161, 164, 178, 1),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w200)),
                          TextSpan(
                              text: "SIGN UP",
                              style: GoogleFonts.nunito(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  decoration: TextDecoration.underline))
                        ]),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _showForgotPasswordDialog(context),
                      child: Text(
                        'Forgot Password?',
                        style: GoogleFonts.poppins(
                          color: Provider.of<PreferencesProvider>(context, listen: false).isDarkMode
                              ? Color.fromARGB(255, 187, 134, 252)
                              : Colors.blue,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ]))
            ],
          ),
        ),
      ),
    );
  }
}
// Add this button below your password fie

// Add this method to handle forgot password
Future<void> _showForgotPasswordDialog(BuildContext context) async {
  final isDarkMode = Provider.of<PreferencesProvider>(context, listen: false).isDarkMode;
  final emailController = TextEditingController();
  final FirebaseAuthServices _auth = FirebaseAuthServices();
  bool isLoading = false;

  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: isDarkMode ? Color(0xFF2A2A2A) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.lock_reset,
                  color: isDarkMode ? Color.fromARGB(255, 187, 134, 252) : Colors.blue,
                  size: 28,
                ),
                SizedBox(width: 12),
                Text(
                  'Reset Password',
                  style: GoogleFonts.poppins(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter your email address to receive a password reset link.',
                  style: GoogleFonts.poppins(
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.poppins(
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: GoogleFonts.poppins(
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDarkMode ? Colors.white24 : Colors.black12,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: isDarkMode ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(
                    color: isDarkMode ? Colors.white54 : Colors.black54,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode 
                    ? Color.fromARGB(255, 187, 134, 252) 
                    : Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: isLoading
                    ? null
                    : () async {
                        if (_validateEmail(emailController.text, context)) {
                          setState(() => isLoading = true);
                          try {
                            await _auth.sendPasswordResetEmail(
                              emailController.text.trim(),
                            );
                            Navigator.of(context).pop();
                            _showSuccessDialog(context);
                          } catch (e) {
                            _showErrorSnackBar(context, e.toString());
                          } finally {
                            setState(() => isLoading = false);
                          }
                        }
                      },
                child: isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Send Reset Link',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
              ),
            ],
          );
        },
      );
    },
  );
}

bool _validateEmail(String email, BuildContext context) {
  if (email.isEmpty) {
    _showErrorSnackBar(context, 'Please enter your email address');
    return false;
  }
  
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  if (!emailRegex.hasMatch(email)) {
    _showErrorSnackBar(context, 'Please enter a valid email address');
    return false;
  }
  
  return true;
}

void _showSuccessDialog(BuildContext context) {
  final isDarkMode = Provider.of<PreferencesProvider>(context, listen: false).isDarkMode;
  
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: isDarkMode ? Color(0xFF2A2A2A) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 28,
            ),
            SizedBox(width: 12),
            Text(
              'Email Sent',
              style: GoogleFonts.poppins(
                color: isDarkMode ? Colors.white : Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          'A password reset link has been sent to your email address. Please check your inbox and follow the instructions to reset your password.',
          style: GoogleFonts.poppins(
            color: isDarkMode ? Colors.white70 : Colors.black87,
            fontSize: 14,
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      );
    },
  );
}

void _showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.white),
          SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
    ),
  );
}