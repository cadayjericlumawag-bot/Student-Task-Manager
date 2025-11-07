import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:myapp/homepage_wrapper.dart';
import 'package:myapp/signup_screen.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Task Manager - Login',
      home: const LoginScreenHome(),
    );
  }
}

class LoginScreenHome extends StatefulWidget {
  const LoginScreenHome({super.key});

  @override
  State<LoginScreenHome> createState() => _LoginScreenHomeState();
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

class _LoginScreenHomeState extends State<LoginScreenHome> {
  var hidePassword = true;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _statusMessage;
  Color? _statusColor;
  final _authService = AuthService();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void togglePassword() {
    setState(() {
      hidePassword = !hidePassword;
    });
  }

  void validateInputs() {
    if (!_formKey.currentState!.validate()) return;
    final email = emailController.text.trim();
    final password = passwordController.text;

    _performLogin(email, password);
  }

  Future<void> _performLogin(String email, String password) async {
    try {
      await _authService.signInWithEmailAndPassword(email, password);
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Login successful';
        _statusColor = Colors.green;
      });
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (BuildContext context) => HomePageWrapper()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _statusMessage = e.message ?? 'Authentication failed';
        _statusColor = Colors.red;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'An unexpected error occurred';
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
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topRight,
                radius: 1.5,
                colors: [
                  Colors.blue.shade300.withAlpha(38),
                  Colors.transparent,
                ],
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Adjust sizes based on screen dimensions
                  final horizontalPadding = constraints.maxWidth > 600
                      ? 40.0
                      : 24.0;
                  final verticalSpacing = constraints.maxHeight > 700
                      ? 24.0
                      : 16.0;
                  final maxContentWidth = 450.0;

                  return Center(
                    child: SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: maxContentWidth,
                          minHeight: constraints.maxHeight,
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                            vertical: verticalSpacing,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // App Logo
                              Container(
                                padding: EdgeInsets.all(
                                  constraints.maxWidth * 0.04,
                                ),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withAlpha(25),
                                ),
                                child: Icon(
                                  Icons.task_alt,
                                  size: constraints.maxWidth * 0.15,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: verticalSpacing),

                              // Title and Welcome Text
                              Text(
                                'Task Manager',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: constraints.maxWidth * 0.07,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              SizedBox(height: verticalSpacing * 0.3),
                              Text(
                                'Welcome back!',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: constraints.maxWidth * 0.05,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: verticalSpacing * 0.3),
                              Text(
                                'Sign in to manage your tasks',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: constraints.maxWidth * 0.035,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: verticalSpacing * 1.5),

                              // Status Message
                              if (_statusMessage != null) ...[
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: horizontalPadding * 0.4,
                                    vertical: verticalSpacing * 0.5,
                                  ),
                                  margin: EdgeInsets.only(
                                    bottom: verticalSpacing * 0.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _statusColor ?? Colors.grey,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _statusMessage!,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                        ),
                                        onPressed: () => setState(
                                          () => _statusMessage = null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              // Login Form
                              Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    _buildTextField(
                                      controller: emailController,
                                      hintText: 'Email',
                                      icon: FontAwesomeIcons.envelope,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return 'Email is required';
                                        }
                                        if (!RegExp(
                                          r'^[\w\.-]+@[\w\.-]+\.[a-zA-Z]{2,}$',
                                        ).hasMatch(v)) {
                                          return 'Please enter a valid email';
                                        }
                                        return null;
                                      },
                                      onChanged: (_) =>
                                          setState(() => _statusMessage = null),
                                    ),
                                    SizedBox(height: verticalSpacing),
                                    _buildTextField(
                                      controller: passwordController,
                                      hintText: 'Password',
                                      icon: FontAwesomeIcons.lock,
                                      obscureText: hidePassword,
                                      suffixIcon: IconButton(
                                        onPressed: togglePassword,
                                        icon: FaIcon(
                                          hidePassword
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
                                  ],
                                ),
                              ),
                              SizedBox(height: verticalSpacing * 1.5),

                              // Login Button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.blue.shade800,
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 5,
                                  ),
                                  onPressed: validateInputs,
                                  child: Text(
                                    'LOGIN',
                                    style: GoogleFonts.poppins(
                                      fontSize: constraints.maxWidth * 0.04,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: verticalSpacing),

                              // Sign Up Link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Don't have an account?",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white70,
                                      fontSize: constraints.maxWidth * 0.035,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (BuildContext context) =>
                                              const SignupScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Sign up',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: constraints.maxWidth * 0.035,
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
                  );
                },
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
    TextInputType? keyboardType,
  }) {
    return Container(
      height: 56,
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20.0,
            vertical: 16.0,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: FaIcon(icon, color: Colors.white, size: 20),
          ),
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(color: Colors.white70),
          suffixIcon: suffixIcon,
          errorStyle: const TextStyle(height: 0),
        ),
        keyboardType: keyboardType,
      ),
    );
  }
}
