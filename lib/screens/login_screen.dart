import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'welcome_screen.dart';
import 'staff_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onContinueKiosk;
  final ValueChanged<String> onStaffLogin;

  const LoginScreen({
    super.key,
    required this.onContinueKiosk,
    required this.onStaffLogin,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _showStaffLogin = false;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _error;

  void _handleStaffLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('user', isEqualTo: username)
        .where('password', isEqualTo: password)
        .get();

    if (query.docs.isNotEmpty) {
      // Navigate to StaffScreen
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const StaffScreen()),
      );
    } else {
      setState(() => _error = 'Incorrect username or password');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
        backgroundColor: AppColors.cream200,
        body: Stack(
          children: [
            const TiledIcons(), // Animated icons background
            Center(
              child: Card(
                elevation: 10,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: _showStaffLogin
                        ? SingleChildScrollView(
                            key: const ValueKey('staff'),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Staff Login',
                                  style:
                                      theme.textTheme.headlineSmall?.copyWith(
                                    color: AppColors.pink700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                TextField(
                                  controller: _usernameController,
                                  decoration: InputDecoration(
                                    labelText: 'Username',
                                    labelStyle:
                                        TextStyle(color: AppColors.pink500),
                                    filled: true,
                                    fillColor:
                                        AppColors.cream200.withOpacity(0.2),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      borderSide:
                                          BorderSide(color: AppColors.peach300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      borderSide: BorderSide(
                                          color: AppColors.pink500, width: 2),
                                    ),
                                  ),
                                  style: TextStyle(color: AppColors.pink700),
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    labelStyle:
                                        TextStyle(color: AppColors.pink500),
                                    errorText: _error,
                                    filled: true,
                                    fillColor:
                                        AppColors.cream200.withOpacity(0.2),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      borderSide:
                                          BorderSide(color: AppColors.peach300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      borderSide: BorderSide(
                                          color: AppColors.pink500, width: 2),
                                    ),
                                  ),
                                  style: TextStyle(color: AppColors.pink700),
                                  onSubmitted: (_) => _handleStaffLogin(),
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.pink500,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(18),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 14),
                                        ),
                                        onPressed: _handleStaffLogin,
                                        child: const Text('Login'),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.pink700,
                                          side: BorderSide(
                                              color: AppColors.peach300),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(18),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 14),
                                        ),
                                        onPressed: () => setState(() {
                                          _showStaffLogin = false;
                                          _error = null;
                                          _usernameController.clear();
                                          _passwordController.clear();
                                        }),
                                        child: const Text('Back'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        : Column(
                            key: const ValueKey('kiosk'),
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Welcome to Inbento Kiosk',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: AppColors.pink700,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.pink500,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 18),
                                  textStyle: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                onPressed: widget.onContinueKiosk,
                                child: const Text('Continue to Kiosk'),
                              ),
                              const SizedBox(height: 20),
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.pink700,
                                  side: BorderSide(color: AppColors.peach300),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 18),
                                  textStyle: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                onPressed: () =>
                                    setState(() => _showStaffLogin = true),
                                child: const Text('Staff Login'),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ));
  }
}
