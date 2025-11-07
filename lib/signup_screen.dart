import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:myapp/loginpage.dart';
// awesome_dialog was previously used for modal dialogs; replaced with SnackBar for inline feedback
// kept the import commented out in case you want to restore modal dialogs later
// import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:myapp/sql_helper/database_helper.dart';
import 'package:myapp/services/auth_service.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Task Manager - Sign Up',
      home: const SignUpScreenHome(),
    );
  }
}

class SignUpScreenHome extends StatefulWidget {
  const SignUpScreenHome({super.key});

  @override
  State<SignUpScreenHome> createState() => _SignUpScreenHomeState();
}

class _BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(13)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final spacing = size.width / 20;

    // Draw diagonal lines
    for (var i = 0; i < size.width + size.height; i += spacing.toInt()) {
      canvas.drawLine(Offset(i.toDouble(), 0), Offset(0, i.toDouble()), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _SignUpScreenHomeState extends State<SignUpScreenHome> {
  var hidePassword1 = true;
  var hidePassword2 = true;
  final idNumberController = TextEditingController();
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPassController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _statusMessage;
  Color? _statusColor;
  final _authService = AuthService();

  @override
  void dispose() {
    idNumberController.dispose();
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPassController.dispose();
    super.dispose();
  }

  void togglePassword1() {
    setState(() {
      hidePassword1 = !hidePassword1;
    });
  }

  void togglePassword2() {
    setState(() {
      hidePassword2 = !hidePassword2;
    });
  }

  Future<void> validateInputs() async {
    // validate form fields first
    if (!_formKey.currentState!.validate()) return;

    // Check if user exists in DB
    final checkIfUserExists = await DatabaseHelper.checkIfUserExists(
      idNumberController.text,
      fullNameController.text,
    );

    if (!mounted) {
      return;
    }

    if (checkIfUserExists.isNotEmpty) {
      setState(() {
        _statusMessage = 'User already exists';
        _statusColor = Colors.red;
      });
      return;
    }

    // Create Firebase user (primary auth) and mirror into local SQLite
    try {
      await _authService.createUserWithEmailAndPassword(
        emailController.text.trim(),
        passwordController.text,
      );
    } catch (e) {
      setState(() {
        _statusMessage = 'Firebase registration failed: ${e.toString()}';
        _statusColor = Colors.red;
      });
      return;
    }

    final insertResult = await DatabaseHelper.insertUser(
      idNumberController.text,
      fullNameController.text,
      emailController.text.trim(),
      passwordController.text,
    );

    if (!mounted) {
      return;
    }

    if (insertResult > 0) {
      setState(() {
        _statusMessage = 'Registration Successful';
        _statusColor = Colors.green;
      });
      // small delay so user sees banner, then navigate
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (BuildContext context) => const LoginScreen(),
        ),
      );
    } else {
      setState(() {
        _statusMessage = 'Registration Failed';
        _statusColor = Colors.red;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a237e), // Deep Indigo
              Color(0xFF0d47a1), // Deep Blue
              Color(0xFF1565c0), // Rich Blue
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: CustomPaint(
          painter: _BackgroundPatternPainter(),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 40.0,
                vertical: 60.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withAlpha(25),
                    ),
                    child: Icon(
                      Icons.person_add,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Task Manager',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create Account',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Join us to start managing your tasks',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (_statusMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: _statusColor ?? Colors.grey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _statusMessage!,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () =>
                                setState(() => _statusMessage = null),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: idNumberController,
                          hintText: 'ID Number',
                          icon: FontAwesomeIcons.idCard,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'ID Number is required';
                            }
                            return null;
                          },
                          onChanged: (_) =>
                              setState(() => _statusMessage = null),
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: fullNameController,
                          hintText: 'Full Name',
                          icon: FontAwesomeIcons.solidUser,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Full Name is required';
                            }
                            return null;
                          },
                          onChanged: (_) =>
                              setState(() => _statusMessage = null),
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: emailController,
                          hintText: 'Email',
                          icon: FontAwesomeIcons.envelope,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Email is required';
                            }
                            return null;
                          },
                          onChanged: (_) =>
                              setState(() => _statusMessage = null),
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: passwordController,
                          hintText: 'Password',
                          icon: FontAwesomeIcons.lock,
                          obscureText: hidePassword1,
                          suffixIcon: IconButton(
                            onPressed: togglePassword1,
                            icon: FaIcon(
                              hidePassword1
                                  ? FontAwesomeIcons.eyeSlash
                                  : FontAwesomeIcons.eye,
                              color: Colors.white70,
                              size: 20,
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Password is required';
                            }
                            if (v.length < 8) {
                              return 'Password must be at least 8 characters';
                            }
                            return null;
                          },
                          onChanged: (_) =>
                              setState(() => _statusMessage = null),
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: confirmPassController,
                          hintText: 'Confirm Password',
                          icon: FontAwesomeIcons.lock,
                          obscureText: hidePassword2,
                          suffixIcon: IconButton(
                            onPressed: togglePassword2,
                            icon: FaIcon(
                              hidePassword2
                                  ? FontAwesomeIcons.eyeSlash
                                  : FontAwesomeIcons.eye,
                              color: Colors.white70,
                              size: 20,
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Password confirmation is required';
                            }
                            if (v.length < 8) {
                              return 'Password must be at least 8 characters';
                            }
                            if (v != passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                          onChanged: (_) =>
                              setState(() => _statusMessage = null),
                        ),
                        const SizedBox(height: 40),
                        _buildSignUpButton(),
                        const SizedBox(height: 30),
                        _buildLoginRow(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        style: GoogleFonts.poppins(color: Colors.white),
        validator: validator,
        onChanged: onChanged,
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: FaIcon(icon, color: Colors.white, size: 20),
          ),
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(color: Colors.white70),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  Widget _buildSignUpButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.blue.shade800,
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 5,
        ),
        onPressed: validateInputs,
        child: Text(
          'SIGN UP',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildLoginRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account?",
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (BuildContext context) => const LoginScreen(),
              ),
            );
          },
          child: Text(
            'Login',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
