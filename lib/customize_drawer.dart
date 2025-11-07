import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'loginpage.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'screens/analytics_screen.dart';
import 'screens/settings_screen.dart';
import 'sql_helper/database_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomizedDrawer extends StatefulWidget {
  const CustomizedDrawer({super.key});

  @override
  State<CustomizedDrawer> createState() => _CustomizedDrawerState();
}

class _CustomizedDrawerState extends State<CustomizedDrawer> {
  Map<String, dynamic>? _currentUser;
  String? _displayName;
  String? _email;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      // Prefer FirebaseAuth user when available
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        if (!mounted) return;
        setState(() {
          _displayName =
              firebaseUser.displayName ?? firebaseUser.email?.split('@').first;
          _email = firebaseUser.email;
        });
        return;
      }

      // Fallback to local DB user if FirebaseAuth not used
      final user = await DatabaseHelper.getCurrentUser();
      if (user != null && mounted) {
        setState(() {
          _currentUser = user;
          _displayName = user['fullName'] as String?;
          _email = user['idNumber'] as String?;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading user data: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          _buildDrawerHeader(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Profile Section
                _buildDrawerItem(
                  icon: FontAwesomeIcons.circleUser,
                  title: 'My Account',
                  onTap: () => _showAccountDialog(context),
                ),
                _buildDrawerItem(
                  icon: FontAwesomeIcons.key,
                  title: 'Change Password',
                  onTap: () => _showChangePasswordDialog(context),
                ),
                const Divider(),
                // Main Navigation
                _buildDrawerItem(
                  icon: FontAwesomeIcons.chartPie,
                  title: 'Analytics',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AnalyticsScreen(),
                    ),
                  ),
                ),
                const Divider(),
                _buildDrawerItem(
                  icon: FontAwesomeIcons.gear,
                  title: 'Settings',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  ),
                ),
                _buildDrawerItem(
                  icon: FontAwesomeIcons.rightFromBracket,
                  title: 'Logout',
                  onTap: () => _showLogoutDialog(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    final userName = _displayName ?? _currentUser?['fullName'] ?? 'Loading...';
    final userEmail = _email ?? _currentUser?['idNumber'] ?? '';
    final isFirebaseUser = FirebaseAuth.instance.currentUser != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withAlpha((0.7 * 255).round()),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color.fromRGBO(255, 255, 255, 0.9),
                  child: ClipOval(
                    child: Image.network(
                      'https://ui-avatars.com/api/?name=${Uri.encodeComponent(userName)}&background=0D8ABC&color=fff&size=200',
                      width: 76,
                      height: 76,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.white70,
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isFirebaseUser
                          ? Icons.verified_user
                          : Icons.person_outline,
                      size: 20,
                      color: isFirebaseUser
                          ? Colors.green.shade400
                          : Colors.orange.shade400,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              userName,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isFirebaseUser
                        ? Colors.green.shade400
                        : Colors.orange.shade400,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isFirebaseUser ? 'Firebase User' : 'Local User',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    userEmail,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color.fromRGBO(255, 255, 255, 0.9),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: FaIcon(icon, size: 22, color: Colors.grey.shade700),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade800,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showAccountDialog(BuildContext context) {
    final isFirebaseUser = FirebaseAuth.instance.currentUser != null;

    AwesomeDialog(
      context: context,
      dialogType: DialogType.info,
      title: 'Account Details',
      desc: isFirebaseUser
          ? 'Manage your Firebase account settings'
          : 'View your local account information',
      btnOkText: 'Close',
      btnOkOnPress: () {},
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAccountDetailRow(
              'Name',
              _displayName ?? 'Not set',
              onEdit: isFirebaseUser
                  ? null
                  : () => _showEditNameDialog(context),
            ),
            const SizedBox(height: 8),
            _buildAccountDetailRow('Email/ID', _email ?? 'Not set'),
            const SizedBox(height: 8),
            _buildAccountDetailRow(
              'Account Type',
              isFirebaseUser ? 'Firebase Authentication' : 'Local Account',
            ),
            const SizedBox(height: 16),
            if (isFirebaseUser) ...[
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  FirebaseAuth.instance.currentUser?.sendEmailVerification();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Verification email sent!')),
                  );
                },
                icon: const Icon(Icons.email),
                label: const Text('Send Verification Email'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade400,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    ).show();
  }

  Widget _buildAccountDetailRow(
    String label,
    String value, {
    VoidCallback? onEdit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit, size: 16),
                onPressed: onEdit,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                splashRadius: 16,
              ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final isFirebaseUser = FirebaseAuth.instance.currentUser != null;
    // Capture the root ScaffoldMessenger before showing dialog
    final rootMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        final formKey = GlobalKey<FormState>();
        String currentPassword = '';
        String newPassword = '';

        return AlertDialog(
          title: const Text('Change Password'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current password',
                  ),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Enter current password'
                      : null,
                  onChanged: (v) => currentPassword = v,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'New password'),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Enter new password';
                    }
                    if (v.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                  onChanged: (v) => newPassword = v,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm new password',
                  ),
                  validator: (v) =>
                      v != newPassword ? 'Passwords do not match' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                if (isFirebaseUser) {
                  final user = FirebaseAuth.instance.currentUser;
                  final email = user?.email;
                  if (user == null || email == null) {
                    rootMessenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Unable to change password for this account',
                        ),
                      ),
                    );
                    return;
                  }

                  // Close dialog before starting async operations
                  Navigator.pop(dialogContext);

                  try {
                    // Reauthenticate with current password
                    final cred = EmailAuthProvider.credential(
                      email: email,
                      password: currentPassword,
                    );
                    await user.reauthenticateWithCredential(cred);
                    await user.updatePassword(newPassword);

                    if (!mounted) return;
                    rootMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('Password changed successfully'),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    rootMessenger.showSnackBar(
                      SnackBar(content: Text('Error changing password: $e')),
                    );
                  }
                } else {
                  // Local DB user: update password directly
                  if (_currentUser == null) {
                    rootMessenger.showSnackBar(
                      const SnackBar(content: Text('No local user found')),
                    );
                    return;
                  }
                  // Close dialog before starting async operations
                  Navigator.pop(dialogContext);

                  try {
                    final int id = _currentUser!['id'] as int;
                    final String idNumber =
                        _currentUser!['idNumber'] as String? ?? '';
                    final String fullName =
                        _currentUser!['fullName'] as String? ?? '';
                    final String userName =
                        _currentUser!['userName'] as String? ?? '';

                    await DatabaseHelper.updateUser(
                      id,
                      idNumber,
                      fullName,
                      userName,
                      newPassword,
                    );

                    if (!mounted) return;
                    rootMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('Password changed successfully'),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    rootMessenger.showSnackBar(
                      SnackBar(content: Text('Error changing password: $e')),
                    );
                  }
                }
              },
              child: const Text('Change'),
            ),
          ],
        );
      },
    );
  }

  void _showEditNameDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final TextEditingController nameController = TextEditingController(
      text: _currentUser?['fullName'] as String? ?? '',
    );
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Edit Name',
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Full Name',
              hintText: 'Enter your full name',
              prefixIcon: Icon(Icons.person, color: Colors.grey.shade600),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Name cannot be empty';
              }
              if (value.trim().length < 2) {
                return 'Name must be at least 2 characters';
              }
              return null;
            },
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              nameController.dispose();
              Navigator.of(dialogContext).pop();
            },
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) {
                return;
              }

              if (_currentUser == null) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('No user data found')),
                );
                return;
              }

              final newName = nameController.text.trim();
              final int id = _currentUser!['id'] as int;
              final String idNumber =
                  _currentUser!['idNumber'] as String? ?? '';
              final String userName =
                  _currentUser!['userName'] as String? ?? '';
              final String password =
                  _currentUser!['password'] as String? ?? '';

              // Close dialog first
              nameController.dispose();
              Navigator.of(dialogContext).pop();

              // Then update in background
              DatabaseHelper.updateUser(
                    id,
                    idNumber,
                    newName,
                    userName,
                    password,
                  )
                  .then((_) {
                    if (!mounted) return;

                    setState(() {
                      _currentUser = {..._currentUser!, 'fullName': newName};
                      _displayName = newName;
                    });

                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Name updated successfully to $newName',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.green.shade600,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  })
                  .catchError((error) {
                    if (!mounted) return;
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Error updating name: $error'),
                        backgroundColor: Colors.red.shade600,
                      ),
                    );
                  });
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.rightSlide,
      title: 'Logout',
      desc: 'Are you sure you want to logout?',
      btnCancelOnPress: () {},
      btnOkOnPress: () {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      },
    ).show();
  }
}
