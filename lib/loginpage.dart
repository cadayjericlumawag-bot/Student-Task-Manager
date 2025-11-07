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
              child: Center(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width > 600
                          ? 40.0
                          : 24.0,
                      vertical: 24.0,
                    ),
                    child: AutofillGroup(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withAlpha(25),
                            ),
                            child: Icon(
                              Icons.task_alt,
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
                            'Welcome back!',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sign in to manage your tasks',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 16,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 32),
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
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildTextField(
                                  controller: emailController,
                                  hintText: 'Email',
                                  icon: FontAwesomeIcons.envelope,
                                  keyboardType: TextInputType.emailAddress,
                                  autofillHints: const [AutofillHints.email],
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
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: passwordController,
                                  hintText: 'Password',
                                  icon: FontAwesomeIcons.lock,
                                  obscureText: hidePassword,
                                  autofillHints: const [AutofillHints.password],
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
                          const SizedBox(height: 32),
                          _buildLoginButton(),
                          const SizedBox(height: 24),
                          _buildSignUpRow(),
                        ],
                      ),
                    ),
                  ),
                ),
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
    Iterable<String>? autofillHints,
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
        autofillHints: autofillHints,
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: FaIcon(icon, color: Colors.white, size: 20),
          ),
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(color: Colors.white70),
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        keyboardType: keyboardType,
      ),
    );
  }

  Widget _buildLoginButton() {
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
          'LOGIN',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSignUpRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account?",
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (BuildContext context) => const SignupScreen(),
              ),
            );
          },
          child: Text(
            'Sign up',
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
