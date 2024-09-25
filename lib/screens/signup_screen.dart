import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sportify1/resources/auth_methods.dart';
import 'package:sportify1/screens/login_screen.dart';
import 'package:sportify1/utils/colors.dart';
import 'package:sportify1/utils/utils.dart';
import 'package:sportify1/widgets/authBackground.dart';
import 'package:sportify1/widgets/text_field_input.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  bool _isLoading = false;
  Uint8List? _image;

  @override
  void dispose() {
    // Dispose all controllers to free resources
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _bioController.dispose(); // Dispose bio controller as well
    super.dispose();
  }

  void signUpUser() async {
    setState(() {
      _isLoading = true;
    });

    String res = await AuthMethods().signUpUser(
      email: _emailController.text,
      password: _passwordController.text,
      username: _usernameController.text,
      bio: _bioController.text, // Include bio in the signup
      file: _image!,
    );

    // Handle success or error
    if (res == "success") {
      setState(() {
        _isLoading = false;
      });
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
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

  selectImage() async {
    Uint8List im = await pickImage(ImageSource.gallery);
    setState(() {
      _image = im;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(children: [
        authBackground(),
        SafeArea(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 94),
                  const Text(
                    "Sportify",
                    style: TextStyle(
                      color: Colors.deepOrangeAccent,
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 64),
                  Stack(
                    children: [
                      _image != null
                          ? CircleAvatar(
                        radius: 64,
                        backgroundImage: MemoryImage(_image!),
                        backgroundColor: Colors.red,
                      )
                          : const CircleAvatar(
                        radius: 64,
                        backgroundImage: NetworkImage(
                            'https://i.stack.imgur.com/l60Hf.png'),
                        backgroundColor: Colors.red,
                      ),
                      Positioned(
                        bottom: -10,
                        left: 80,
                        child: IconButton(
                          onPressed: selectImage,
                          icon: const Icon(Icons.add_a_photo),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextFieldInput(
                    hintText: 'Enter your username',
                    textInputType: TextInputType.text,
                    textEditingController: _usernameController,
                  ),
                  const SizedBox(height: 24),
                  TextFieldInput(
                    hintText: 'Enter your email',
                    textInputType: TextInputType.emailAddress,
                    textEditingController: _emailController,
                  ),
                  const SizedBox(height: 24),
                  TextFieldInput(
                    hintText: 'Enter your password',
                    textInputType: TextInputType.text,
                    textEditingController: _passwordController,
                    isPass: true,
                  ),
                  const SizedBox(height: 24),
                  TextFieldInput(
                    hintText: 'Tell us about your self', // Bio field
                    textInputType: TextInputType.text,
                    textEditingController: _bioController,
                  ),
                  const SizedBox(height: 24),
                  InkWell(
                    onTap: signUpUser,
                    child: Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: const ShapeDecoration(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                        ),
                        color: Colors.black,
                      ),
                      child: !_isLoading
                          ? const Text(
                        'Sign up',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      )
                          : const CircularProgressIndicator(
                        color: primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: const Text('Already have an account?'),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: const Text(
                            ' Login.',
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
      ]),
    );
  }
}
