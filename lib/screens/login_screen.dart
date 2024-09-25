import 'package:flutter/material.dart';
import 'package:sportify1/resources/auth_methods.dart';
import 'package:sportify1/responsive/mobile_screen_layout.dart';
import 'package:sportify1/responsive/responsive_layout.dart';
import 'package:sportify1/responsive/web_screen_layout.dart';
import 'package:sportify1/screens/signup_screen.dart';
import 'package:sportify1/utils/colors.dart';
import 'package:sportify1/utils/global_variable.dart';
import 'package:sportify1/utils/utils.dart';
import 'package:sportify1/widgets/authBackground.dart';
import 'package:sportify1/widgets/text_field_input.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'interestsScreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<bool> checkIfFirstLogin() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        return userData['interests'] == null || userData['interests'].isEmpty;
      }
    } catch (e) {
      print('Error checking first login: $e');
    }
    return false;
  }

  void loginUser() async {
    setState(() {
      _isLoading = true;
    });
    String res = await AuthMethods().loginUser(
        email: _emailController.text, password: _passwordController.text);
    if (res == 'success') {
      if (context.mounted) {
        bool isFirstLogin = await checkIfFirstLogin();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => isFirstLogin
                ? SelectInterestsScreen()
                : const ResponsiveLayout(
              mobileScreenLayout: MobileScreenLayout(),
              webScreenLayout: WebScreenLayout(),
            ),
          ),
              (route) => false,
        );

        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
      if (context.mounted) {
        showSnackBar(context, res);
      }
    }
  }

  void signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });
    String res = await AuthMethods().signInWithGoogle();
    if (res == 'success') {
      if (context.mounted) {
        bool isFirstLogin = await checkIfFirstLogin();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => isFirstLogin
                ? SelectInterestsScreen()
                : const ResponsiveLayout(
              mobileScreenLayout: MobileScreenLayout(),
              webScreenLayout: WebScreenLayout(),
            ),
          ),
              (route) => false,
        );

        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
      if (context.mounted) {
        showSnackBar(context, res);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          authBackground(),
          SafeArea(
            child: SingleChildScrollView(
              child: Container(
                padding: MediaQuery.of(context).size.width > webScreenSize
                    ? EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width / 3)
                    : const EdgeInsets.symmetric(horizontal: 32),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 54,
                    ),
                    Image.asset("assets/logo.png", height: 200),
                    const SizedBox(
                      height: 4,
                    ),
                    const Text("Welcome back !!",
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(
                      height: 34,
                    ),
                    TextFieldInput(
                      hintText: 'Example@domain.com',
                      textInputType: TextInputType.emailAddress,
                      textEditingController: _emailController,
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    TextFieldInput(
                      hintText: 'Enter your password',
                      textInputType: TextInputType.text,
                      textEditingController: _passwordController,
                      isPass: true,
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    GestureDetector(
                      onTap: () {
                        // Add your navigation or action here
                        // For example, Navigator.of(context).push(MaterialPageRoute(builder: (context) => PasswordResetScreen()));
                      },
                      child: const Padding(
                        padding: EdgeInsets.only(bottom: 12.0),
                        child: Text(
                          'Forget your password?',
                          style: TextStyle(
                            color: Colors.black45,
                            // Change this color as needed
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    InkWell(
                      onTap: loginUser,
                      child: Container(
                        width: double.infinity,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: const ShapeDecoration(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(6)),
                          ),
                          color: Colors.black,
                        ),
                        child: !_isLoading
                            ? const Text(
                          'Log in',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        )
                            : const CircularProgressIndicator(
                          color: primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    // After the existing content in your Column widget

                    const SizedBox(height: 20),
                    const Text('or continue with'),

                    const Divider(color: Colors.grey),
                    const SizedBox(height: 10),

                    const SizedBox(height: 20),
                    InkWell(
                      onTap: signInWithGoogle,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 108),
                        decoration: BoxDecoration(
                          color: Colors.white, // Change as needed
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset('assets/google.png', height: 24),
                            // Your Google icon asset
                            const SizedBox(width: 16),
                            const Text('Sign in with Google',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    InkWell(
                      onTap: () {
                        // Implement your Facebook sign-in logic here
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 103),
                        decoration: BoxDecoration(
                          color: Colors.white, // Facebook's color
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset('assets/facebook.png', height: 24),
                            // Your Facebook icon asset
                            const SizedBox(width: 10),
                            const Text('Sign in with Facebook',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: const Text(
                            'Dont have an account?',
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SignupScreen(),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            child: const Text(
                              ' Signup.',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}